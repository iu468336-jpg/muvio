package app.muvio.mobile

import fi.iki.elonen.NanoHTTPD
import org.libtorrent4j.AlertListener
import org.libtorrent4j.Priority
import org.libtorrent4j.SessionManager
import org.libtorrent4j.SessionParams
import org.libtorrent4j.SettingsPack
import org.libtorrent4j.Sha1Hash
import org.libtorrent4j.TorrentFlags
import org.libtorrent4j.TorrentHandle
import org.libtorrent4j.TorrentInfo
import org.libtorrent4j.alerts.AddTorrentAlert
import org.libtorrent4j.alerts.Alert
import org.libtorrent4j.alerts.AlertType
import org.libtorrent4j.alerts.MetadataReceivedAlert
import org.libtorrent4j.alerts.PieceFinishedAlert
import org.libtorrent4j.swig.settings_pack
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.io.RandomAccessFile
import java.net.URLEncoder
import kotlin.math.max
import kotlin.math.min

/**
 * 32-bit `armeabi-v7a` safe, piece-accurate sequential torrent streaming engine
 * powered by `libtorrent4j:2.1.0-38` (`setPosixDiskIO()`) + `NanoHTTPD`, hosted inside
 * the isolated `:torrent` Android service process (`TorrentForegroundService`).
 *
 * Critical guarantees for mobile stability:
 * 1. NEVER retains `alert.handle()` across `SessionManager.alertsLoop()` iterations!
 *    `TorrentAlert.handle()` returns a non-owning SWIG pointer (`swigCMemOwn = false`)
 *    into the transient C++ `torrent_alert`, which is destroyed immediately on `v.clear()`.
 *    Instead, we extract `Sha1Hash(alertHandle.infoHash().toHex())` synchronously inside
 *    `alert()` and ALWAYS resolve an owned `TorrentHandle` (`swigCMemOwn = true`) via
 *    `sessionManager.find(infoHash)`.
 * 2. Disables `enable_ip_notifier` (`false`) per LibreTorrent 4.1.1 so Android 11–15
 *    SELinux `NETLINK_ROUTE` restrictions never break socket binding or peer discovery,
 *    and binds explicit IPv4+IPv6 `listenInterfaces` with port retry.
 * 3. Calls `SessionParams(settings).apply { setPosixDiskIO() }` so `libtorrent` NEVER
 *    memory-maps (`mmap`) multi-gigabyte video torrents into a 32-bit virtual address space.
 * 4. Serves byte-accurate HTTP `206 Partial Content` streams via `TorrentPieceInputStream`,
 *    verifying `TorrentHandle.havePiece(pieceIdx)` before reading from `RandomAccessFile`.
 */
class LocalTorrentStreamController(private val saveDir: File) {

    companion object {
        private val DEFAULT_TRACKERS = listOf(
            "udp://tracker.opentrackr.org:1337/announce",
            "http://tracker.opentrackr.org:1337/announce",
            "udp://open.stealth.si:80/announce",
            "udp://tracker.torrent.eu.org:451/announce",
            "udp://open.demonii.com:1337/announce",
            "udp://exodus.desync.com:6969/announce",
            "udp://tracker.moeking.me:6969/announce",
            "udp://explodie.org:6969/announce",
            "udp://tracker1.bt.moack.co.kr:80/announce",
            "udp://tracker.tiny-vps.com:6969/announce",
            "udp://tracker.dler.org:6969/announce",
            "http://tracker.dler.com:6969/announce"
        )

        private val VIDEO_EXTENSIONS = listOf(
            ".mkv", ".mp4", ".webm", ".avi", ".mov", ".m4v", ".ts", ".m2ts"
        )

        private const val DHT_BOOTSTRAP_NODES =
            "dht.libtorrent.org:25401,router.bittorrent.com:6881,dht.transmissionbt.com:6881,outer.silotis.us:6881"

        fun emptyTelemetry(): Map<String, Any> = mapOf(
            "hasMetadata" to false,
            "readyToPlay" to false,
            "peers" to 0,
            "seeds" to 0,
            "downloadSpeed" to 0,
            "progress" to 0.0,
            "bufferedBytes" to 0L,
            "fileSize" to 0L
        )
    }

    private var sessionManager: SessionManager? = null
    private var httpServer: ProgressiveHttpServer? = null
    private var telemetryUpdaterThread: Thread? = null

    @Volatile
    private var cachedTelemetry: Map<String, Any> = emptyTelemetry()

    /**
     * Hex info-hash (40-char SHA-1) used to obtain a fresh, heap-owned `TorrentHandle`
     * via `sessionManager.find(Sha1Hash.parseHex(hex))` — NEVER storing a dangling
     * `alert.handle()` pointer!
     */
    @Volatile
    private var activeInfoHashHex: String? = null

    @Volatile
    private var selectedFileIdx: Int = -1

    @Volatile
    private var selectedFile: File? = null

    @Volatile
    private var selectedFileSize: Long = 0L

    @Volatile
    private var selectedFileOffset: Long = 0L

    @Volatile
    private var pieceLength: Int = 0

    @Volatile
    private var firstPieceIdx: Int = 0

    @Volatile
    private var lastPieceIdx: Int = 0

    @Volatile
    private var stopped: Boolean = false

    private val pieceLock = Object()
    private val configLock = Object()

    /**
     * Safely resolves an owned `TorrentHandle` (`swigCMemOwn = true`) from `SessionManager`.
     */
    private fun resolveOwnedHandle(): TorrentHandle? {
        if (stopped) return null
        val session = sessionManager ?: return null
        val hex = activeInfoHashHex ?: return null
        if (hex.length != 40) return null
        return try {
            val h = session.find(Sha1Hash.parseHex(hex))
            if (h != null && h.isValid) h else null
        } catch (_: Throwable) {
            null
        }
    }

    fun startSequentialStream(
        magnetOrUri: String,
        infoHash: String?,
        fileIndex: Int,
        sources: List<String>
    ): String {
        stopBlocking()
        stopped = false
        cachedTelemetry = emptyTelemetry()
        cleanOldCacheFiles()

        // Pre-seed infoHash if known (40-char hex)
        val cleanHex = extractHexInfoHash(magnetOrUri, infoHash)
        activeInfoHashHex = cleanHex

        val randomPort = 39000 + ((System.currentTimeMillis() and 0x1FFF).toInt())

        val settings = SettingsPack()
            .activeDownloads(2)
            .activeSeeds(1)
            .activeLimit(4)
            .connectionsLimit(60)
            .maxPeerlistSize(300)
            .maxQueuedDiskBytes(4 * 1024 * 1024)
            .sendBufferWatermark(1024 * 1024)
            .alertQueueSize(1000)
            .stopTrackerTimeout(1)
            .seedingOutgoingConnections(false)
            .listenInterfaces("0.0.0.0:$randomPort,[::]:$randomPort")
            .setInteger(settings_pack.int_types.max_retry_port_bind.swigValue(), 12)
            // CRITICAL on Android 11-15 (SELinux blocks untrusted NETLINK_ROUTE bind):
            .setBoolean(settings_pack.bool_types.enable_ip_notifier.swigValue(), false)
            .setString(settings_pack.string_types.dht_bootstrap_nodes.swigValue(), DHT_BOOTSTRAP_NODES)
            .setBoolean(settings_pack.bool_types.enable_dht.swigValue(), true)
            .setBoolean(settings_pack.bool_types.enable_lsd.swigValue(), true)
            .setBoolean(settings_pack.bool_types.enable_upnp.swigValue(), false)
            .setBoolean(settings_pack.bool_types.enable_natpmp.swigValue(), false)
            .setBoolean(settings_pack.bool_types.announce_to_all_trackers.swigValue(), true)
            .setBoolean(settings_pack.bool_types.announce_to_all_tiers.swigValue(), true)
            .setBoolean(settings_pack.bool_types.prioritize_partial_pieces.swigValue(), true)
            .setBoolean(settings_pack.bool_types.validate_https_trackers.swigValue(), false)
            .setInteger(settings_pack.int_types.aio_threads.swigValue(), 2)
            .setInteger(settings_pack.int_types.hashing_threads.swigValue(), 1)
            .setInteger(settings_pack.int_types.checking_mem_usage.swigValue(), 256)
            .setInteger(settings_pack.int_types.file_pool_size.swigValue(), 8)

        val params = SessionParams(settings)
        // CRITICAL for 32-bit armeabi-v7a: never mmap large video files into 32-bit VM space!
        params.setPosixDiskIO()

        val session = SessionManager(false)
        sessionManager = session

        session.addListener(object : AlertListener {
            override fun types(): IntArray = intArrayOf(
                AlertType.ADD_TORRENT.swig(),
                AlertType.METADATA_RECEIVED.swig(),
                AlertType.PIECE_FINISHED.swig()
            )

            override fun alert(alert: Alert<*>) {
                if (stopped) return
                try {
                    when (alert) {
                        is AddTorrentAlert -> {
                            // Extract pure Java String hex synchronously before alert C++ object is freed!
                            val hex = alert.handle()?.infoHash()?.toHex()
                            if (!hex.isNullOrBlank() && hex.length == 40) {
                                activeInfoHashHex = hex.lowercase()
                            }
                            val owned = resolveOwnedHandle()
                            if (owned != null && owned.isValid) {
                                owned.resume()
                                try {
                                    owned.forceReannounce()
                                    owned.forceDHTAnnounce()
                                    owned.forceLSDAnnounce()
                                } catch (_: Throwable) {
                                }
                                if (owned.status().hasMetadata()) {
                                    configureTargetFile(owned, fileIndex)
                                }
                            }
                        }
                        is MetadataReceivedAlert -> {
                            val hex = alert.handle()?.infoHash()?.toHex()
                            if (!hex.isNullOrBlank() && hex.length == 40) {
                                activeInfoHashHex = hex.lowercase()
                            }
                            val owned = resolveOwnedHandle()
                            if (owned != null && owned.isValid) {
                                configureTargetFile(owned, fileIndex)
                            }
                            synchronized(pieceLock) {
                                pieceLock.notifyAll()
                            }
                        }
                        is PieceFinishedAlert -> {
                            synchronized(pieceLock) {
                                pieceLock.notifyAll()
                            }
                        }
                    }
                } catch (_: Throwable) {
                }
            }
        })

        session.start(params)
        try {
            if (!session.isDhtRunning) {
                session.startDht()
            }
        } catch (_: Throwable) {
        }

        val enrichedMagnet = buildEnrichedMagnet(magnetOrUri, infoHash, sources)
        session.download(enrichedMagnet, saveDir, TorrentFlags.SEQUENTIAL_DOWNLOAD)

        val server = ProgressiveHttpServer()
        server.start(60_000, false)
        httpServer = server

        startBackgroundTelemetryUpdater(fileIndex)

        return "http://127.0.0.1:${server.listeningPort}/stream"
    }

    /**
     * Lock-free, JNI-free snapshot safe to read directly from IPC / UI threads.
     */
    fun getCachedStatus(): Map<String, Any> = cachedTelemetry

    private fun extractHexInfoHash(magnetOrUri: String, explicitHash: String?): String? {
        val candidate = explicitHash?.trim()?.lowercase()
        if (!candidate.isNullOrEmpty() && candidate.length == 40 && candidate.all { it in '0'..'9' || it in 'a'..'f' }) {
            return candidate
        }
        val regex = Regex("btih:([0-9a-fA-F]{40})")
        val match = regex.find(magnetOrUri)
        return match?.groupValues?.getOrNull(1)?.lowercase()
    }

    private fun startBackgroundTelemetryUpdater(requestedFileIdx: Int) {
        val thread = Thread {
            while (!stopped) {
                try {
                    cachedTelemetry = computeLiveStatus(requestedFileIdx)
                } catch (_: Throwable) {
                }
                try {
                    Thread.sleep(650)
                } catch (_: InterruptedException) {
                    return@Thread
                }
            }
        }.apply {
            name = "MuvioTorrentTelemetry"
            isDaemon = true
            start()
        }
        telemetryUpdaterThread = thread
    }

    private fun computeLiveStatus(requestedFileIdx: Int): Map<String, Any> {
        val h = resolveOwnedHandle()
        if (stopped || h == null || !h.isValid) {
            return emptyTelemetry()
        }

        val st = h.status()
        if (st.hasMetadata() && selectedFileIdx < 0) {
            configureTargetFile(h, requestedFileIdx)
        }

        val hasMeta = st.hasMetadata() && selectedFileIdx >= 0 && pieceLength > 0
        var contiguousHeaderPieces = 0
        var ready = false

        if (hasMeta) {
            val checkCount = min(lastPieceIdx - firstPieceIdx + 1, 10)
            for (i in 0 until checkCount) {
                if (h.havePiece(firstPieceIdx + i)) {
                    contiguousHeaderPieces++
                } else {
                    break
                }
            }
            val contiguousBytes = contiguousHeaderPieces.toLong() * pieceLength.toLong()
            val tailReady = h.havePiece(lastPieceIdx)
            val minHeaderBytes = min(selectedFileSize, max(pieceLength.toLong() * 2L, 768_000L))
            ready = contiguousBytes >= minHeaderBytes && (tailReady || contiguousHeaderPieces >= 2)
        }

        return mapOf(
            "hasMetadata" to hasMeta,
            "readyToPlay" to ready,
            "peers" to st.numPeers(),
            "seeds" to st.numSeeds(),
            "downloadSpeed" to st.downloadPayloadRate(),
            "progress" to st.progress().toDouble(),
            "bufferedBytes" to (contiguousHeaderPieces.toLong() * pieceLength.toLong()),
            "fileSize" to selectedFileSize
        )
    }

    private fun configureTargetFile(handle: TorrentHandle, requestedIdx: Int) {
        synchronized(configLock) {
            if (selectedFileIdx >= 0 || stopped || !handle.isValid) return
            val ti: TorrentInfo = handle.torrentFile() ?: return
            val fs = ti.files()
            val numFiles = fs.numFiles()
            if (numFiles <= 0) return

            var chosenIdx = -1
            if (requestedIdx in 0 until numFiles && !fs.padFileAt(requestedIdx)) {
                val candidateName = fs.fileName(requestedIdx).lowercase()
                if (VIDEO_EXTENSIONS.any { candidateName.endsWith(it) } || numFiles == 1) {
                    chosenIdx = requestedIdx
                }
            }
            if (chosenIdx < 0) {
                var bestSize = -1L
                for (i in 0 until numFiles) {
                    if (fs.padFileAt(i)) continue
                    val name = fs.fileName(i).lowercase()
                    val sz = fs.fileSize(i)
                    if (VIDEO_EXTENSIONS.any { name.endsWith(it) } && sz > bestSize) {
                        bestSize = sz
                        chosenIdx = i
                    }
                }
            }
            if (chosenIdx < 0) {
                var bestSize = -1L
                for (i in 0 until numFiles) {
                    if (fs.padFileAt(i)) continue
                    val sz = fs.fileSize(i)
                    if (sz > bestSize) {
                        bestSize = sz
                        chosenIdx = i
                    }
                }
            }
            if (chosenIdx < 0) {
                chosenIdx = requestedIdx.coerceIn(0, numFiles - 1)
            }

            val pLen = ti.pieceLength()
            val fOffset = fs.fileOffset(chosenIdx)
            val fSize = fs.fileSize(chosenIdx)
            if (pLen <= 0 || fSize <= 0L) return

            // Exact piece bounds arithmetic (identical to LibreTorrent 4.1.1 TorrentDownloadImpl.getFilePieces)
            val firstP = (fOffset / pLen.toLong()).toInt()
            val lastP = ((fOffset + fSize - 1L) / pLen.toLong()).toInt()

            val priorities = Array(numFiles) { idx ->
                if (idx == chosenIdx) Priority.DEFAULT else Priority.IGNORE
            }
            handle.prioritizeFiles(priorities)
            handle.setFlags(TorrentFlags.SEQUENTIAL_DOWNLOAD)

            selectedFileOffset = fOffset
            selectedFileSize = fSize
            pieceLength = pLen
            firstPieceIdx = firstP
            lastPieceIdx = lastP
            selectedFile = File(saveDir, fs.filePath(chosenIdx))
            selectedFileIdx = chosenIdx

            // Prioritize header pieces (EBML / ftyp / moov) + final tail pieces (Cues / moov at tail)
            val headEnd = min(lastP, firstP + 6)
            for (p in firstP..headEnd) {
                handle.piecePriority(p, Priority.TOP_PRIORITY)
                handle.setPieceDeadline(p, 1000 + (p - firstP) * 180)
            }
            val tailStart = max(firstP, lastP - 1)
            for (p in tailStart..lastP) {
                handle.piecePriority(p, Priority.TOP_PRIORITY)
                handle.setPieceDeadline(p, 1200)
            }
            try {
                handle.setSequentialRange(firstP, lastP)
            } catch (_: Throwable) {
            }
        }
    }

    private fun buildEnrichedMagnet(
        magnetOrUri: String,
        infoHash: String?,
        sources: List<String>
    ): String {
        val trackers = LinkedHashSet<String>()
        trackers.addAll(DEFAULT_TRACKERS)
        for (src in sources) {
            if (src.startsWith("tracker:")) {
                val tr = src.removePrefix("tracker:").trim()
                if (tr.isNotEmpty()) trackers.add(tr)
            } else if (src.startsWith("udp://") || src.startsWith("http://") || src.startsWith("https://")) {
                trackers.add(src.trim())
            }
        }

        val base = when {
            magnetOrUri.startsWith("magnet:?") -> magnetOrUri
            !infoHash.isNullOrBlank() -> "magnet:?xt=urn:btih:${infoHash.trim()}"
            else -> magnetOrUri
        }

        val sb = StringBuilder(base)
        for (tr in trackers) {
            val encoded = URLEncoder.encode(tr, "UTF-8")
            if (!base.contains(encoded, ignoreCase = true) && !base.contains(tr, ignoreCase = true)) {
                sb.append("&tr=").append(encoded)
            }
        }
        return sb.toString()
    }

    private fun waitForMetadata(timeoutMs: Long): Boolean {
        val deadline = System.currentTimeMillis() + timeoutMs
        while (!stopped && System.currentTimeMillis() < deadline) {
            if (selectedFileIdx >= 0 && selectedFile != null && pieceLength > 0) {
                return true
            }
            val h = resolveOwnedHandle()
            if (h != null && h.isValid) {
                try {
                    if (h.status().hasMetadata()) {
                        configureTargetFile(h, 0)
                        if (selectedFileIdx >= 0) return true
                    }
                } catch (_: Throwable) {
                }
            }
            var interrupted = false
            synchronized(pieceLock) {
                try {
                    pieceLock.wait(250)
                } catch (_: InterruptedException) {
                    interrupted = true
                }
            }
            if (interrupted) return false
        }
        return selectedFileIdx >= 0 && selectedFile != null && pieceLength > 0
    }

    private fun waitForPiece(pieceIndex: Int, timeoutMs: Long): Boolean {
        val deadline = System.currentTimeMillis() + timeoutMs
        val initialHandle = resolveOwnedHandle() ?: return false

        try {
            val maxLookahead = min(lastPieceIdx, pieceIndex + 5)
            for (p in pieceIndex..maxLookahead) {
                if (!initialHandle.havePiece(p)) {
                    initialHandle.piecePriority(p, Priority.TOP_PRIORITY)
                    initialHandle.setPieceDeadline(p, 800 + (p - pieceIndex) * 150)
                }
            }
        } catch (_: Throwable) {
        }

        while (!stopped && System.currentTimeMillis() < deadline) {
            try {
                val h = resolveOwnedHandle() ?: return false
                if (h.havePiece(pieceIndex)) return true
            } catch (_: Throwable) {
                return false
            }
            var interrupted = false
            synchronized(pieceLock) {
                try {
                    pieceLock.wait(180)
                } catch (_: InterruptedException) {
                    interrupted = true
                }
            }
            if (interrupted) return false
        }
        return try {
            val h = resolveOwnedHandle()
            h != null && h.isValid && h.havePiece(pieceIndex)
        } catch (_: Throwable) {
            false
        }
    }

    private fun detectMimeType(fileName: String): String {
        val lower = fileName.lowercase()
        return when {
            lower.endsWith(".mkv") -> "video/x-matroska"
            lower.endsWith(".webm") -> "video/webm"
            lower.endsWith(".avi") -> "video/x-msvideo"
            lower.endsWith(".ts") || lower.endsWith(".m2ts") -> "video/mp2t"
            lower.endsWith(".mov") -> "video/quicktime"
            else -> "video/mp4"
        }
    }

    private fun cleanOldCacheFiles() {
        try {
            if (saveDir.exists()) {
                saveDir.deleteRecursively()
            }
            saveDir.mkdirs()
        } catch (_: Throwable) {
        }
    }

    fun stopAsync() {
        stopped = true
        cachedTelemetry = emptyTelemetry()
        synchronized(pieceLock) {
            pieceLock.notifyAll()
        }
        Thread {
            stopBlocking()
        }.apply {
            name = "MuvioTorrentStop"
            isDaemon = true
            start()
        }
    }

    fun stopBlocking() {
        stopped = true
        cachedTelemetry = emptyTelemetry()
        synchronized(pieceLock) {
            pieceLock.notifyAll()
        }
        try {
            telemetryUpdaterThread?.interrupt()
        } catch (_: Throwable) {
        }
        telemetryUpdaterThread = null

        try {
            httpServer?.stop()
        } catch (_: Throwable) {
        }
        httpServer = null

        try {
            val h = resolveOwnedHandle()
            if (h != null && h.isValid) {
                sessionManager?.remove(h)
            }
        } catch (_: Throwable) {
        }
        activeInfoHashHex = null
        selectedFileIdx = -1
        selectedFile = null
        selectedFileSize = 0L

        val oldSession = sessionManager
        sessionManager = null
        if (oldSession != null) {
            try {
                oldSession.stop()
            } catch (_: Throwable) {
            }
        }
    }

    private inner class ProgressiveHttpServer : NanoHTTPD("127.0.0.1", 0) {
        override fun serve(httpSession: IHTTPSession): Response {
            if (!waitForMetadata(45_000L)) {
                return newFixedLengthResponse(
                    Response.Status.REQUEST_TIMEOUT,
                    MIME_PLAINTEXT,
                    "Metadata timeout"
                )
            }

            val targetFile = selectedFile ?: return newFixedLengthResponse(
                Response.Status.NOT_FOUND,
                MIME_PLAINTEXT,
                "No video file found in torrent"
            )
            val totalLen = selectedFileSize
            if (totalLen <= 0L) {
                return newFixedLengthResponse(
                    Response.Status.NOT_FOUND,
                    MIME_PLAINTEXT,
                    "Empty torrent video file"
                )
            }
            val mime = detectMimeType(targetFile.name)

            if (httpSession.method == Method.HEAD) {
                val headRes = newFixedLengthResponse(Response.Status.OK, mime, "")
                headRes.addHeader("Accept-Ranges", "bytes")
                headRes.addHeader("Content-Length", totalLen.toString())
                return headRes
            }

            val rangeHeader = httpSession.headers["range"]
            var startByte = 0L
            var endByte = totalLen - 1L
            var isPartial = false

            if (rangeHeader != null && rangeHeader.startsWith("bytes=")) {
                isPartial = true
                val spec = rangeHeader.removePrefix("bytes=").trim()
                val dashIdx = spec.indexOf('-')
                if (dashIdx >= 0) {
                    val startPart = spec.substring(0, dashIdx).trim()
                    val endPart = spec.substring(dashIdx + 1).trim()
                    if (startPart.isNotEmpty()) {
                        startByte = startPart.toLongOrNull()?.coerceIn(0L, totalLen - 1L) ?: 0L
                        if (endPart.isNotEmpty()) {
                            endByte = endPart.toLongOrNull()?.coerceIn(startByte, totalLen - 1L)
                                ?: (totalLen - 1L)
                        }
                    } else if (endPart.isNotEmpty()) {
                        val suffixLen = endPart.toLongOrNull() ?: 0L
                        startByte = (totalLen - suffixLen).coerceIn(0L, totalLen - 1L)
                    }
                }
            }

            val contentLength = (endByte - startByte) + 1L
            val stream = TorrentPieceInputStream(
                file = targetFile,
                startOffsetInFile = startByte,
                bytesToServe = contentLength
            )

            val status = if (isPartial) Response.Status.PARTIAL_CONTENT else Response.Status.OK
            val res = newFixedLengthResponse(status, mime, stream, contentLength)
            res.addHeader("Accept-Ranges", "bytes")
            res.addHeader("Connection", "keep-alive")
            if (isPartial) {
                res.addHeader("Content-Range", "bytes $startByte-$endByte/$totalLen")
            }
            return res
        }
    }

    /**
     * Custom `InputStream` that guarantees `libtorrent` has finished and hash-verified
     * the exact piece covering the current read offset before reading bytes from disk.
     */
    private inner class TorrentPieceInputStream(
        private val file: File,
        startOffsetInFile: Long,
        bytesToServe: Long
    ) : InputStream() {
        private var currentFilePos: Long = startOffsetInFile
        private var remaining: Long = bytesToServe
        private var raf: RandomAccessFile? = null

        private fun ensureRaf(): RandomAccessFile {
            var r = raf
            if (r != null) return r
            val deadline = System.currentTimeMillis() + 30_000L
            while (!stopped && !file.exists() && System.currentTimeMillis() < deadline) {
                var interrupted = false
                synchronized(pieceLock) {
                    try {
                        pieceLock.wait(150)
                    } catch (_: InterruptedException) {
                        interrupted = true
                    }
                }
                if (interrupted) {
                    throw IOException("Interrupted waiting for file")
                }
            }
            if (!file.exists()) {
                throw IOException("Torrent file not yet materialized on disk")
            }
            r = RandomAccessFile(file, "r")
            raf = r
            return r
        }

        override fun read(): Int {
            val single = ByteArray(1)
            val n = read(single, 0, 1)
            return if (n <= 0) -1 else (single[0].toInt() and 0xFF)
        }

        override fun read(b: ByteArray, off: Int, len: Int): Int {
            if (stopped) return -1
            if (remaining <= 0L) return -1
            if (len == 0) return 0

            val pLen = pieceLength
            if (pLen <= 0) throw IOException("Invalid piece length")

            val absTorrentOffset = selectedFileOffset + currentFilePos
            val pieceIdx = (absTorrentOffset / pLen.toLong()).toInt()

            if (!waitForPiece(pieceIdx, 45_000L)) {
                throw IOException("Timed out waiting for torrent piece $pieceIdx")
            }

            val nextPieceStartOffset = (pieceIdx.toLong() + 1L) * pLen.toLong()
            val bytesLeftInPiece = nextPieceStartOffset - absTorrentOffset
            val maxRead = min(len.toLong(), min(remaining, bytesLeftInPiece)).toInt()

            val reader = ensureRaf()
            if (reader.length() < currentFilePos + maxRead) {
                try {
                    resolveOwnedHandle()?.flushCache()
                } catch (_: Throwable) {
                }
                Thread.sleep(50)
            }
            reader.seek(currentFilePos)
            val actualRead = reader.read(b, off, maxRead)
            if (actualRead <= 0) {
                return -1
            }

            currentFilePos += actualRead.toLong()
            remaining -= actualRead.toLong()
            return actualRead
        }

        override fun close() {
            try {
                raf?.close()
            } catch (_: Throwable) {
            }
            raf = null
        }
    }
}
