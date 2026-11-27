package app.muvio.mobile

import android.net.Uri
import com.nuvio.engine.NuvioEngine
import com.nuvio.engine.NuvioEngineConfig
import com.nuvio.engine.NuvioEngineException
import com.nuvio.engine.NuvioTorrentProfile
import com.nuvio.engine.NuvioUploadMode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeout
import java.io.File
import java.net.URLEncoder
import java.util.Locale

/**
 * Persistent Nuvio C++ P2P demand-scheduled streaming controller (`lib-nuvio-engine-android`).
 *
 * Key upgrades over Muvio v1.0.4:
 * 1. Keeps the `NuvioEngine` DHT + UDP/TCP swarm session alive across plays (`warmUp()` on service
 *    start, `stopStream()` on playback exit instead of tearing down DHT!).
 * 2. Returns the local HTTP Range URL (`http://127.0.0.1:<port>/streams/<id>`) immediately once
 *    torrent metadata resolves (`0L` preload) so Media3 `ExoPlayer` opens right away and
 *    drives C++ sliding-window demand piece scheduling directly via HTTP `Range` requests.
 * 3. Caps magnet URIs cleanly under NuvioEngine's 16 KiB limit while injecting high-speed UDP/WSS
 *    public trackers for instant peer discovery.
 */
class LocalTorrentStreamController(private val cacheRoot: File) {

    companion object {
        private const val MAX_MAGNET_LENGTH = 15_000
        private const val METADATA_TIMEOUT_MS = 38_000L

        private val FAST_TRACKERS = listOf(
            "udp://tracker.opentrackr.org:1337/announce",
            "udp://open.stealth.si:80/announce",
            "udp://tracker.torrent.eu.org:451/announce",
            "udp://exodus.desync.com:6969/announce",
            "udp://open.demonii.com:1337/announce",
            "udp://tracker.openbittorrent.com:6969/announce",
            "udp://explodie.org:6969/announce",
            "udp://p4p.arenabg.com:1337/announce",
            "https://tracker.tamersunion.org:443/announce",
            "wss://tracker.openwebtorrent.com"
        )

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

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val engineMutex = Mutex()

    @Volatile
    private var engine: NuvioEngine? = null

    @Volatile
    private var activeTorrentId: String? = null

    @Volatile
    private var activeStreamId: String? = null

    @Volatile
    private var activeStreamUrl: String? = null

    @Volatile
    private var activeFileSize: Long = 0L

    @Volatile
    private var statsJob: Job? = null

    @Volatile
    private var cachedTelemetry: Map<String, Any> = emptyTelemetry()

    /**
     * Boots NuvioEngine + DHT immediately when `:torrent` service binds so DHT routing table is warm
     * before the user even taps a torrent source.
     */
    fun warmUp() {
        scope.launch {
            try {
                ensureEngine()
            } catch (_: Throwable) {
            }
        }
    }

    private suspend fun ensureEngine(): NuvioEngine = engineMutex.withLock {
        val existing = engine
        if (existing != null) return@withLock existing

        val dataDir = File(cacheRoot, "nuvio_data").apply { mkdirs() }
        val diskCacheDir = File(cacheRoot, "nuvio_cache").apply { mkdirs() }

        val config = NuvioEngineConfig(
            dataDirectory = dataDir,
            cacheDirectory = diskCacheDir,
            memoryCacheCapacityBytes = 48L * 1024L * 1024L,      // 48 MiB RAM sliding buffer (32-bit ARM safe)
            diskCacheCapacityBytes = 1536L * 1024L * 1024L,      // 1.5 GiB persistent disk piece cache
            torrentProfile = NuvioTorrentProfile.Fast,
            listenPort = 0,
            uploadMode = NuvioUploadMode.Limited,
            uploadLimitBytesPerSecond = 256L * 1024L
        )

        val created = NuvioEngine.create(config, Dispatchers.IO)
        engine = created
        created
    }

    suspend fun startSequentialStream(
        magnetOrUri: String,
        infoHash: String?,
        fileIndex: Int,
        filenameHint: String?,
        sources: List<String>
    ): String {
        val magnet = buildNormalizedMagnet(magnetOrUri, infoHash, filenameHint, sources)
        val nuvio = ensureEngine()

        // Stop any previous active stream without shutting down DHT!
        stopCurrentStreamInternal(nuvio)

        cachedTelemetry = emptyTelemetry()

        val torrentId = withTimeout(METADATA_TIMEOUT_MS) {
            try {
                nuvio.addMagnet(magnet)
            } catch (e: NuvioEngineException) {
                throw IllegalStateException("Erreur P2P Nuvio (${e.status}): ${e.message}", e)
            }
        }

        val normalizedFileIndex = fileIndex.takeIf { it >= 0 }
        val normalizedHint = filenameHint?.trim()?.takeIf { it.isNotEmpty() }

        val prepared = try {
            nuvio.prepareStream(
                torrentId,
                normalizedFileIndex,
                normalizedHint,
                0L
            )
        } catch (_: Throwable) {
            // Fallback without fileIndex if addon passed an out-of-range fileIdx
            nuvio.prepareStream(
                torrentId,
                null,
                normalizedHint,
                0L
            )
        }

        activeTorrentId = torrentId
        activeStreamId = prepared.id
        activeStreamUrl = prepared.url
        activeFileSize = prepared.fileSize

        cachedTelemetry = mapOf(
            "hasMetadata" to true,
            "readyToPlay" to true,
            "peers" to 0,
            "seeds" to 0,
            "downloadSpeed" to 0,
            "progress" to 0.0,
            "bufferedBytes" to 0L,
            "fileSize" to prepared.fileSize
        )

        startStatsPolling(nuvio, prepared.id, prepared.fileSize)
        return prepared.url
    }

    private fun startStatsPolling(
        nuvio: NuvioEngine,
        streamId: String,
        initialFileSize: Long
    ) {
        statsJob?.cancel()
        statsJob = scope.launch {
            while (isActive && activeStreamId == streamId) {
                try {
                    val engineStats = nuvio.stats.value
                    val streamStats = nuvio.currentStreamStats(streamId)

                    val peers = engineStats.connectedPeers
                    val seeds = engineStats.connectedSeeds
                    val downSpeed = engineStats.downloadRateBytesPerSecond.coerceAtLeast(0L)
                    val fileSize = streamStats?.fileSize?.takeIf { it > 0L } ?: initialFileSize
                    val buffered = streamStats?.contiguousReadyBytes
                        ?: streamStats?.verifiedFileBytes
                        ?: 0L
                    val progress = (streamStats?.fileProgress ?: 0f).toDouble().coerceIn(0.0, 1.0)

                    cachedTelemetry = mapOf(
                        "hasMetadata" to true,
                        "readyToPlay" to true,
                        "peers" to peers,
                        "seeds" to seeds,
                        "downloadSpeed" to downSpeed.coerceAtMost(Int.MAX_VALUE.toLong()).toInt(),
                        "progress" to progress,
                        "bufferedBytes" to buffered.coerceAtLeast(0L),
                        "fileSize" to fileSize.coerceAtLeast(0L)
                    )
                } catch (_: Throwable) {
                }
                delay(900L)
            }
        }
    }

    fun getCachedStatus(): Map<String, Any> = cachedTelemetry

    /**
     * Stops only the active stream & reclaims old disk cache while keeping `NuvioEngine` + DHT warm
     * for instant peer discovery on the next selection.
     */
    fun stopCurrentStreamAsync() {
        scope.launch {
            val nuvio = engine ?: return@launch
            stopCurrentStreamInternal(nuvio)
        }
    }

    private suspend fun stopCurrentStreamInternal(nuvio: NuvioEngine) {
        statsJob?.cancel()
        statsJob = null

        val prevStreamId = activeStreamId
        val prevTorrentId = activeTorrentId
        activeStreamId = null
        activeTorrentId = null
        activeStreamUrl = null
        activeFileSize = 0L
        cachedTelemetry = emptyTelemetry()

        if (!prevStreamId.isNullOrBlank()) {
            try {
                nuvio.stopStream(prevStreamId)
            } catch (_: Throwable) {
            }
        }
        if (!prevTorrentId.isNullOrBlank()) {
            try {
                nuvio.removeTorrent(prevTorrentId)
            } catch (_: Throwable) {
            }
        }
        try {
            nuvio.reclaimDiskCache(1200L * 1024L * 1024L)
        } catch (_: Throwable) {
        }
    }

    fun shutdownAsync() {
        statsJob?.cancel()
        statsJob = null
        val nuvio = engine
        engine = null
        activeStreamId = null
        activeTorrentId = null
        cachedTelemetry = emptyTelemetry()
        Thread {
            try {
                kotlinx.coroutines.runBlocking {
                    if (nuvio != null) {
                        try {
                            nuvio.shutdown()
                        } catch (_: Throwable) {
                        }
                    }
                }
            } catch (_: Throwable) {
            } finally {
                scope.cancel()
            }
        }.apply {
            isDaemon = true
            start()
        }
    }

    private fun buildNormalizedMagnet(
        rawUri: String,
        infoHash: String?,
        filenameHint: String?,
        sources: List<String>
    ): String {
        val trimmed = rawUri.trim()
        val cleanHash = extractCleanInfoHash(trimmed, infoHash)

        val trackers = LinkedHashSet<String>()

        if (trimmed.startsWith("magnet:?", ignoreCase = true)) {
            try {
                val parsed = Uri.parse(trimmed)
                parsed.getQueryParameters("tr").forEach { tr ->
                    val t = tr.trim()
                    if (t.isNotEmpty()) trackers.add(t)
                }
            } catch (_: Throwable) {
            }
        }

        for (src in sources) {
            val s = src.trim()
            when {
                s.startsWith("tracker:", ignoreCase = true) -> {
                    val tr = s.substring("tracker:".length).trim()
                    if (tr.isNotEmpty()) trackers.add(tr)
                }
                s.startsWith("udp://", ignoreCase = true) ||
                    s.startsWith("http://", ignoreCase = true) ||
                    s.startsWith("https://", ignoreCase = true) ||
                    s.startsWith("wss://", ignoreCase = true) -> trackers.add(s)
            }
        }

        trackers.addAll(FAST_TRACKERS)

        if (cleanHash == null) {
            if (trimmed.startsWith("magnet:?", ignoreCase = true)) {
                return if (trimmed.length <= MAX_MAGNET_LENGTH) trimmed else trimmed.take(MAX_MAGNET_LENGTH)
            }
            throw IllegalArgumentException("Lien magnet ou infoHash invalide.")
        }

        val sb = StringBuilder("magnet:?xt=urn:btih:").append(cleanHash)
        val dn = filenameHint?.trim()?.takeIf { it.isNotEmpty() }
        if (dn != null) {
            val encodedDn = URLEncoder.encode(dn, "UTF-8")
            if (sb.length + encodedDn.length + 8 < MAX_MAGNET_LENGTH) {
                sb.append("&dn=").append(encodedDn)
            }
        }

        for (tr in trackers) {
            val encodedTr = URLEncoder.encode(tr, "UTF-8")
            if (sb.length + encodedTr.length + 8 >= MAX_MAGNET_LENGTH) break
            sb.append("&tr=").append(encodedTr)
        }

        return sb.toString()
    }

    private fun extractCleanInfoHash(rawUri: String, explicitHash: String?): String? {
        val candidate = explicitHash?.trim()?.lowercase(Locale.US)
        if (!candidate.isNullOrEmpty() &&
            (candidate.matches(Regex("^[0-9a-f]{40}$")) || candidate.matches(Regex("^[a-z2-7]{32}$")))
        ) {
            return candidate
        }
        val btihMatch = Regex("urn:btih:([0-9a-fA-F]{40}|[a-zA-Z2-7]{32})")
            .find(rawUri)
            ?.groupValues
            ?.getOrNull(1)
        if (!btihMatch.isNullOrEmpty()) {
            return btihMatch.lowercase(Locale.US)
        }
        return null
    }
}
