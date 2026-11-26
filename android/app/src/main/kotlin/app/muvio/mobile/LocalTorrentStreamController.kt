package app.muvio.mobile

import fi.iki.elonen.NanoHTTPD
import org.libtorrent4j.AlertListener
import org.libtorrent4j.Priority
import org.libtorrent4j.SessionManager
import org.libtorrent4j.TorrentFlags
import org.libtorrent4j.TorrentHandle
import org.libtorrent4j.TorrentInfo
import org.libtorrent4j.alerts.AddTorrentAlert
import org.libtorrent4j.alerts.Alert
import org.libtorrent4j.alerts.AlertType
import org.libtorrent4j.alerts.MetadataReceivedAlert
import org.libtorrent4j.alerts.PieceFinishedAlert
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.io.RandomAccessFile
import java.net.URLEncoder
import kotlin.math.max
import kotlin.math.min

/**
 * Piece-accurate sequential torrent streaming engine powered by `libtorrent4j` + `NanoHTTPD`.
 *
 * Key guarantees for reliable `media_kit` (`libmpv`) playback on mobile:
 * 1. Injects fast public UDP/HTTP trackers + Stremio `sources` trackers + DHT/LSD bootstrap.
 * 2. Selects the exact target video file (`fileIdx` or largest video extension) and sets
 *    `Priority.IGNORE` on all other files so season packs never waste bandwidth.
 * 3. Prioritizes BOTH the initial header pieces AND the final tail pieces (`moov` / MKV `Cues`)
 *    with `Priority.TOP_PRIORITY` + urgent `setPieceDeadline`.
 * 4. Serves byte-accurate HTTP `206 Partial Content` streams via `TorrentPieceInputStream`
 *    which verifies `TorrentHandle.havePiece(pieceIdx)` before reading from `RandomAccessFile`,
 *    preventing `mpv` from ever reading sparse all-zero unwritten disk blocks!
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
    }

    private var sessionManager: SessionManager? = null
    private var httpServer: ProgressiveHttpServer? = null

    @Volatile
    private var activeHandle: TorrentHandle? = null

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

    fun startSequentialStream(
        magnetOrUri: String,
        infoHash: String?,
        fileIndex: Int,
        sources: List<String>
    ): String {
        stop()
        stopped = false
        cleanOldCacheFiles()

        val session = SessionManager()
        session.addListener(object : AlertListener {
            override fun types(): IntArray = intArrayOf(
                AlertType.ADD_TORRENT.swig(),
                AlertType.METADATA_RECEIVED.swig(),
                AlertType.PIECE_FINISHED.swig()
            )

            override fun alert(alert: Alert<*>) {
                when (alert) {
                    is AddTorrentAlert -> {
                        val h = alert.handle()
                        if (h.isValid) {
                            activeHandle = h
                            h.resume()
                            try {
                                h.forceReannounce()
                                h.forceDHTAnnounce()
                                h.forceLSDAnnounce()
                            } catch (_: Throwable) {
                            }
                            if (h.status().hasMetadata()) {
                                configureTargetFile(h, fileIndex)
                            }
                        }
                    }
                    is MetadataReceivedAlert -> {
                        val h = alert.handle()
                        if (h.isValid) {
                            activeHandle = h
                            configureTargetFile(h, fileIndex)
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
            }
        })

        session.start()
        try {
            session.startDht()
        } catch (_: Throwable) {
        }
        sessionManager = session

        val enrichedMagnet = buildEnrichedMagnet(magnetOrUri, infoHash, sources)
        session.download(enrichedMagnet, saveDir, TorrentFlags.SEQUENTIAL_DOWNLOAD)

        val server = ProgressiveHttpServer()
        server.start(60_000, false)
        httpServer = server

        return "http://127.0.0.1:${server.listeningPort}/stream"
    }

    fun getStreamStatus(): Map<String, Any> {
        val h = activeHandle
        if (h == null || !h.isValid) {
            return mapOf(
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

        val st = h.status()
        val hasMeta = st.hasMetadata() && selectedFileIdx >= 0 && pieceLength > 0
        var contiguousHeaderPieces = 0
        var ready = false

        if (hasMeta) {
            val checkCount = min(lastPieceIdx - firstPieceIdx + 1, 12)
            for (i in 0 until checkCount) {
                if (h.havePiece(firstPieceIdx + i)) {
                    contiguousHeaderPieces++
                } else {
                    break
                }
            }
            val contiguousBytes = contiguousHeaderPieces.toLong() * pieceLength.toLong()
            val tailReady = h.havePiece(lastPieceIdx)
            val minHeaderBytes = min(selectedFileSize, max(pieceLength.toLong() * 2L, 1_572_864L))
            ready = contiguousBytes >= minHeaderBytes && (tailReady || contiguousHeaderPieces >= 3)
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
        if (selectedFileIdx >= 0) return
        val ti: TorrentInfo = handle.torrentFile() ?: return
        val fs = ti.files()
        val numFiles = fs.numFiles()
        if (numFiles <= 0) return

        var chosenIdx = -1
        if (requestedIdx in 0 until numFiles) {
            val candidateName = fs.fileName(requestedIdx).lowercase()
            if (VIDEO_EXTENSIONS.any { candidateName.endsWith(it) } || numFiles == 1) {
                chosenIdx = requestedIdx
            }
        }
        if (chosenIdx < 0) {
            var bestSize = -1L
            for (i in 0 until numFiles) {
                val name = fs.fileName(i).lowercase()
                val sz = fs.fileSize(i)
                if (VIDEO_EXTENSIONS.any { name.endsWith(it) } && sz > bestSize) {
                    bestSize = sz
                    chosenIdx = i
                }
            }
        }
        if (chosenIdx < 0) {
            chosenIdx = requestedIdx.coerceIn(0, numFiles - 1)
        }

        val priorities = Array(numFiles) { idx ->
            if (idx == chosenIdx) Priority.DEFAULT else Priority.IGNORE
        }
        handle.prioritizeFiles(priorities)

        val pLen = fs.pieceLength()
        val firstP = fs.pieceIndexAtFile(chosenIdx)
        val lastP = fs.lastPieceIndexAtFile(chosenIdx)

        selectedFileOffset = fs.fileOffset(chosenIdx)
        selectedFileSize = fs.fileSize(chosenIdx)
        pieceLength = pLen
        firstPieceIdx = firstP
        lastPieceIdx = lastP
        selectedFile = File(saveDir, fs.filePath(chosenIdx))
        selectedFileIdx = chosenIdx

        // Prioritize header pieces (EBML / ftyp / moov) + final tail pieces (Cues / moov at tail)
        val headEnd = min(lastP, firstP + 6)
        for (p in firstP..headEnd) {
            handle.piecePriority(p, Priority.TOP_PRIORITY)
            handle.setPieceDeadline(p, (p - firstP) * 150)
        }
        val tailStart = max(firstP, lastP - 1)
        for (p in tailStart..lastP) {
            handle.piecePriority(p, Priority.TOP_PRIORITY)
            handle.setPieceDeadline(p, 250)
        }
        handle.setSequentialRange(firstP, lastP)
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
            val h = activeHandle
            if (h != null && h.isValid && h.status().hasMetadata()) {
                configureTargetFile(h, 0)
                if (selectedFileIdx >= 0) return true
            }
            synchronized(pieceLock) {
                try {
                    pieceLock.wait(250)
                } catch (_: InterruptedException) {
                    break
                }
            }
        }
        return selectedFileIdx >= 0 && selectedFile != null && pieceLength > 0
    }

    private fun waitForPiece(pieceIndex: Int, timeoutMs: Long): Boolean {
        val deadline = System.currentTimeMillis() + timeoutMs
        val h = activeHandle ?: return false

        // Boost priority of this exact piece and the next 5 lookahead pieces
        try {
            val maxLookahead = min(lastPieceIdx, pieceIndex + 5)
            for (p in pieceIndex..maxLookahead) {
                if (!h.havePiece(p)) {
                    h.piecePriority(p, Priority.TOP_PRIORITY)
                    h.setPieceDeadline(p, (p - pieceIndex) * 120)
                }
            }
        } catch (_: Throwable) {
        }

        while (!stopped && System.currentTimeMillis() < deadline) {
            if (!h.isValid) return false
            if (h.havePiece(pieceIndex)) return true
            synchronized(pieceLock) {
                try {
                    pieceLock.wait(200)
                } catch (_: InterruptedException) {
                    return false
                }
            }
        }
        return h.isValid && h.havePiece(pieceIndex)
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

    fun stop() {
        stopped = true
        synchronized(pieceLock) {
            pieceLock.notifyAll()
        }
        try {
            httpServer?.stop()
        } catch (_: Throwable) {
        }
        httpServer = null

        try {
            val h = activeHandle
            if (h != null && h.isValid) {
                sessionManager?.remove(h)
            }
        } catch (_: Throwable) {
        }
        activeHandle = null
        selectedFileIdx = -1
        selectedFile = null
        selectedFileSize = 0L

        val oldSession = sessionManager
        sessionManager = null
        if (oldSession != null) {
            Thread {
                try {
                    oldSession.stop()
                } catch (_: Throwable) {
                }
            }.apply { isDaemon = true }.start()
        }
    }

    private inner class ProgressiveHttpServer : NanoHTTPD("127.0.0.1", 0) {
        override fun serve(httpSession: IHTTPSession): Response {
            if (!waitForMetadata(45_000L)) {
                return newFixedLengthResponse(
                    Response.Status.GATEWAY_TIMEOUT,
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
                synchronized(pieceLock) {
                    try {
                        pieceLock.wait(150)
                    } catch (_: InterruptedException) {
                        break
                    }
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

            // Flush disk cache on boundary if file length hasn't grown yet
            val nextPieceStartOffset = (pieceIdx.toLong() + 1L) * pLen.toLong()
            val bytesLeftInPiece = nextPieceStartOffset - absTorrentOffset
            val maxRead = min(len.toLong(), min(remaining, bytesLeftInPiece)).toInt()

            val reader = ensureRaf()
            if (reader.length() < currentFilePos + maxRead) {
                activeHandle?.flushCache()
                Thread.sleep(60)
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
