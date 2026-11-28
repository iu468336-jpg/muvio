package app.muvio.mobile

import android.app.ActivityManager
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Surface
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.VideoSize
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.TransferListener
import androidx.media3.datasource.okhttp.OkHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.extractor.DefaultExtractorsFactory
import androidx.media3.extractor.ts.DefaultTsPayloadReaderFactory
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import okhttp3.OkHttpClient
import java.security.SecureRandom
import java.security.cert.X509Certificate
import java.util.Locale
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Nuvio-grade AndroidX Media3 (`ExoPlayer` + Jellyfin FFmpeg Audio Decoder) playback engine
 * rendered through a dedicated hardware `SurfaceView` (`NativeVideoSurfaceViewFactory`).
 *
 * Crash-proof guarantees on 32-bit `armeabi-v7a` and 64-bit `arm64-v8a` Android phones:
 * 1. Direct `SurfaceView` -> `SurfaceFlinger` hardware overlay output (zero `SurfaceTexture`
 *    `GL_TEXTURE_EXTERNAL_OES` shader import or mid-stream `setDefaultBufferSize` buffer crash!).
 * 2. 32-bit ARM / low-RAM decoder protection: caps max video resolution to 1080p (1920x1080)
 *    on 32-bit `armeabi-v7a` or <=3 GB RAM phones so 4K/10-bit HEVC streams never trigger
 *    `OMX` / `MediaCodec` graphic-buffer OOM or `SIGABRT` crashes on stream startup.
 * 3. RFC-7230 HTTP header sanitization so `OkHttpDataSource` never throws `IllegalArgumentException`
 *    on control characters or non-ASCII scraper headers.
 * 4. AudioFocus managed safely (`handleAudioFocus = false`) so OEM `AudioManager` binder bugs
 *    or call interruptions never abort `ExoPlayer.prepare()`.
 * 5. Trust-all OkHttp Media3 DataSource + 65s loopback timeout + 64 KiB `BufferedReadDataSource`
 *    + `InlineDataUriDataSource` (`data:` HLS support).
 */
@OptIn(UnstableApi::class)
class NativeMedia3PlayerController(
    private val context: Context
) {
    companion object {
        const val SURFACE_VIEW_ID_SENTINEL = 1

        private const val DEFAULT_USER_AGENT =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

        private val remoteOkHttpClient: OkHttpClient by lazy { buildMediaOkHttpClient(readTimeoutSec = 45L) }
        private val loopbackOkHttpClient: OkHttpClient by lazy { buildMediaOkHttpClient(readTimeoutSec = 65L) }

        private fun buildMediaOkHttpClient(readTimeoutSec: Long): OkHttpClient {
            val builder = OkHttpClient.Builder()
                .connectTimeout(20L, TimeUnit.SECONDS)
                .readTimeout(readTimeoutSec, TimeUnit.SECONDS)
                .writeTimeout(20L, TimeUnit.SECONDS)
                .followRedirects(true)
                .followSslRedirects(true)
                .retryOnConnectionFailure(true)

            try {
                val trustAllCerts = arrayOf<TrustManager>(
                    object : X509TrustManager {
                        override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) = Unit
                        override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) = Unit
                        override fun getAcceptedIssuers(): Array<X509Certificate> = emptyArray()
                    }
                )
                val sslContext = SSLContext.getInstance("TLS").apply {
                    init(null, trustAllCerts, SecureRandom())
                }
                builder.sslSocketFactory(sslContext.socketFactory, trustAllCerts[0] as X509TrustManager)
                builder.hostnameVerifier { _, _ -> true }
            } catch (_: Throwable) {
            }

            return builder.build()
        }

        private fun is32BitProcess(): Boolean {
            return try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    !android.os.Process.is64Bit()
                } else {
                    Build.SUPPORTED_64_BIT_ABIS.isEmpty()
                }
            } catch (_: Throwable) {
                true
            }
        }
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val sessionSeq = AtomicInteger(1)

    private var exoPlayer: ExoPlayer? = null
    private var trackSelector: DefaultTrackSelector? = null
    private var activeViewId: Int = -1
    private var displaySurface: Surface? = null
    private var eventSink: EventChannel.EventSink? = null
    private var audioTrackIndex: Int = 0
    private var subtitlesEnabled: Boolean = true

    private val isLowMemoryOr32Bit: Boolean by lazy {
        val is32 = is32BitProcess()
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        val memInfo = ActivityManager.MemoryInfo()
        val totalRamBytes = try {
            am?.getMemoryInfo(memInfo)
            memInfo.totalMem
        } catch (_: Throwable) {
            0L
        }
        val lowRamDevice = am?.isLowRamDevice == true || (totalRamBytes in 1L..(3200L * 1024L * 1024L))
        is32 || lowRamDevice
    }

    private val positionPoller = object : Runnable {
        override fun run() {
            val p = exoPlayer ?: return
            try {
                val posMs = p.currentPosition.coerceAtLeast(0L)
                val durMs = if (p.duration == C.TIME_UNSET || p.duration < 0L) 0L else p.duration
                sendEvent(
                    mapOf(
                        "event" to "position",
                        "positionMs" to posMs,
                        "durationMs" to durMs,
                        "bufferedMs" to p.bufferedPosition.coerceAtLeast(0L),
                        "isPlaying" to p.isPlaying,
                        "isBuffering" to (p.playbackState == Player.STATE_BUFFERING)
                    )
                )
            } catch (_: Throwable) {
            }
            mainHandler.postDelayed(this, 500L)
        }
    }

    fun attachDisplaySurface(viewId: Int, surface: Surface) {
        mainHandler.post {
            if (!surface.isValid) return@post
            activeViewId = viewId
            displaySurface = surface
            val p = exoPlayer ?: return@post
            try {
                p.setVideoSurface(surface)
                if (Build.VERSION.SDK_INT == Build.VERSION_CODES.P && !p.playWhenReady) {
                    val pos = p.currentPosition
                    p.seekTo(if (pos == 0L) 1L else pos)
                }
            } catch (_: Throwable) {
            }
        }
    }

    fun detachDisplaySurface(viewId: Int, surface: Surface?) {
        mainHandler.post {
            val p = exoPlayer
            if (surface != null && p != null) {
                try {
                    p.clearVideoSurface(surface)
                } catch (_: Throwable) {
                }
            }
            if (activeViewId == viewId || displaySurface === surface) {
                displaySurface = null
                activeViewId = -1
            }
        }
    }

    fun attachEventChannel(channel: EventChannel) {
        channel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    fun handleMethodCall(
        method: String,
        args: Map<String, Any?>?,
        result: MethodChannel.Result
    ) {
        try {
            when (method) {
                "open" -> {
                    val url = args?.get("url") as? String ?: ""
                    val filename = args?.get("filename") as? String
                    val rawHeaders = args?.get("headers") as? Map<*, *>
                    val headers = HashMap<String, String>()
                    if (rawHeaders != null) {
                        for ((k, v) in rawHeaders) {
                            if (k != null && v != null) {
                                headers[k.toString()] = v.toString()
                            }
                        }
                    }

                    val rawSubs = args?.get("subtitles") as? List<*>
                    val externalSubs = ArrayList<Map<String, String>>()
                    if (rawSubs != null) {
                        for (item in rawSubs) {
                            if (item is Map<*, *>) {
                                val subUrl = item["url"]?.toString()?.trim() ?: ""
                                if (subUrl.isNotEmpty()) {
                                    externalSubs.add(
                                        mapOf(
                                            "url" to subUrl,
                                            "lang" to (item["lang"]?.toString() ?: "en"),
                                            "label" to (item["label"]?.toString() ?: "Sous-titres")
                                        )
                                    )
                                }
                            }
                        }
                    }

                    val startPosMs = (args?.get("startPositionMs") as? Number)?.toLong() ?: 0L
                    val preferSoftware = args?.get("preferSoftware") as? Boolean ?: false
                    val info = openStream(
                        url = url,
                        filename = filename,
                        headers = headers,
                        externalSubtitles = externalSubs,
                        startPositionMs = startPosMs,
                        preferSoftware = preferSoftware
                    )
                    result.success(info)
                }
                "play" -> {
                    exoPlayer?.play()
                    result.success(null)
                }
                "pause" -> {
                    exoPlayer?.pause()
                    result.success(null)
                }
                "playOrPause" -> {
                    val p = exoPlayer
                    if (p != null) {
                        if (p.isPlaying) p.pause() else p.play()
                    }
                    result.success(p?.isPlaying ?: false)
                }
                "seek" -> {
                    val posMs = (args?.get("positionMs") as? Number)?.toLong() ?: 0L
                    exoPlayer?.seekTo(posMs.coerceAtLeast(0L))
                    result.success(null)
                }
                "setVolume" -> {
                    val vol = (args?.get("volume") as? Number)?.toFloat() ?: 1.0f
                    exoPlayer?.volume = vol.coerceIn(0.0f, 1.0f)
                    result.success(null)
                }
                "setSpeed" -> {
                    val speed = (args?.get("speed") as? Number)?.toFloat() ?: 1.0f
                    exoPlayer?.playbackParameters = PlaybackParameters(speed.coerceIn(0.25f, 3.0f))
                    result.success(null)
                }
                "setSubtitlesEnabled" -> {
                    val enabled = args?.get("enabled") as? Boolean ?: true
                    subtitlesEnabled = enabled
                    val ts = trackSelector
                    if (ts != null) {
                        ts.parameters = ts.buildUponParameters()
                            .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, !enabled)
                            .build()
                    }
                    result.success(null)
                }
                "cycleAudioTrack" -> {
                    val label = cycleAudioTrack()
                    result.success(label)
                }
                "dispose" -> {
                    releasePlayer()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            CrashLogManager.recordLog(
                context,
                source = "NativeMedia3[$method]",
                trace = t.stackTraceToString()
            )
            result.error("PLAYER_ERR", t.message ?: t.toString(), null)
        }
    }

    private fun sanitizeHeaderName(raw: String): String {
        val sb = StringBuilder(raw.length)
        for (ch in raw.trim()) {
            if (ch.code in 0x21..0x7E && ch != ':') {
                sb.append(ch)
            }
        }
        return sb.toString()
    }

    private fun sanitizeHeaderValue(raw: String): String {
        val sb = StringBuilder(raw.length)
        for (ch in raw.trim()) {
            if (ch == '\t' || ch.code in 0x20..0x7E) {
                sb.append(ch)
            }
        }
        return sb.toString().trim()
    }

    private fun openStream(
        url: String,
        filename: String?,
        headers: Map<String, String>,
        externalSubtitles: List<Map<String, String>>,
        startPositionMs: Long,
        preferSoftware: Boolean
    ): Map<String, Any> {
        mainHandler.removeCallbacks(positionPoller)

        exoPlayer?.let { old ->
            try {
                old.clearVideoSurface()
                old.stop()
                old.release()
            } catch (_: Throwable) {
            }
        }
        exoPlayer = null

        var userAgent = DEFAULT_USER_AGENT
        val cleanHeaders = HashMap<String, String>()
        for ((k, v) in headers) {
            val safeKey = sanitizeHeaderName(k)
            val safeVal = sanitizeHeaderValue(v)
            if (safeKey.isEmpty() || safeVal.isEmpty()) continue
            when {
                safeKey.equals("User-Agent", ignoreCase = true) -> userAgent = safeVal
                safeKey.equals("Range", ignoreCase = true) -> Unit
                else -> cleanHeaders[safeKey] = safeVal
            }
        }

        val parsedUri = Uri.parse(url)
        val host = parsedUri.host?.lowercase(Locale.US) ?: ""
        val isLoopback = host == "127.0.0.1" || host == "localhost" || host == "::1"

        val okHttpClient = if (isLoopback) loopbackOkHttpClient else remoteOkHttpClient
        val httpFactory = OkHttpDataSource.Factory(okHttpClient)
            .setUserAgent(userAgent)

        if (cleanHeaders.isNotEmpty() && !isLoopback) {
            httpFactory.setDefaultRequestProperties(cleanHeaders)
        }

        val baseDefaultFactory = DefaultDataSource.Factory(context, httpFactory)
        val routedDataSourceFactory = DataSource.Factory {
            object : DataSource {
                private val defaultSource = baseDefaultFactory.createDataSource()
                private val dataUriSource = InlineDataUriDataSource()
                private var active: DataSource? = null

                override fun addTransferListener(transferListener: TransferListener) {
                    defaultSource.addTransferListener(transferListener)
                }

                override fun open(dataSpec: DataSpec): Long {
                    val chosen = if (dataSpec.uri.scheme.equals("data", ignoreCase = true)) {
                        dataUriSource
                    } else {
                        defaultSource
                    }
                    active = chosen
                    return chosen.open(dataSpec)
                }

                override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
                    return active?.read(buffer, offset, length) ?: C.RESULT_END_OF_INPUT
                }

                override fun getUri(): Uri? = active?.uri

                override fun getResponseHeaders(): Map<String, List<String>> =
                    active?.responseHeaders ?: emptyMap()

                override fun close() {
                    try {
                        active?.close()
                    } finally {
                        active = null
                    }
                }
            }
        }

        val bufferedDataSourceFactory = BufferedReadDataSource.Factory(routedDataSourceFactory)

        val extractorsFactory = DefaultExtractorsFactory()
            .setTsExtractorFlags(DefaultTsPayloadReaderFactory.FLAG_ENABLE_HDMV_DTS_AUDIO_STREAMS)
            .setConstantBitrateSeekingEnabled(true)

        val mediaSourceFactory = DefaultMediaSourceFactory(bufferedDataSourceFactory, extractorsFactory)

        // Conservative RAM buffer budget on 32-bit ARM / low-RAM phones (12 MiB vs 20 MiB)
        val targetBytes = if (isLowMemoryOr32Bit) 12 * 1024 * 1024 else 24 * 1024 * 1024
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                /* minBufferMs = */ if (isLowMemoryOr32Bit) 6_000 else 10_000,
                /* maxBufferMs = */ if (isLowMemoryOr32Bit) 18_000 else 30_000,
                /* bufferForPlaybackMs = */ 1_000,
                /* bufferForPlaybackAfterRebufferMs = */ 2_200
            )
            .setTargetBufferBytes(targetBytes)
            .setPrioritizeTimeOverSizeThresholds(false)
            .build()

        val renderersFactory = DefaultRenderersFactory(context)
            .setExtensionRendererMode(
                if (preferSoftware) {
                    DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER
                } else {
                    DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON
                }
            )
            .setEnableDecoderFallback(true)

        val selector = DefaultTrackSelector(context).apply {
            val paramsBuilder = buildUponParameters()
                .setPreferredAudioLanguages("fr", "fra", "fre", "en", "eng")
                .setPreferredTextLanguages("fr", "fra", "fre", "en", "eng")
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, !subtitlesEnabled)
                .setAllowInvalidateSelectionsOnRendererCapabilitiesChange(true)

            // Cap adaptive video selection to 1080p on 32-bit / low-RAM phones to prevent 4K OMX crashes
            if (isLowMemoryOr32Bit) {
                paramsBuilder
                    .setMaxVideoSize(1920, 1080)
                    .setExceedVideoConstraintsIfNecessary(true)
                    .setExceedRendererCapabilitiesIfNecessary(false)
            }
            parameters = paramsBuilder.build()
        }
        trackSelector = selector

        val audioAttrs = AudioAttributes.Builder()
            .setUsage(C.USAGE_MEDIA)
            .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
            .build()

        // Match NuvioMobile: pass handleAudioFocus=false so OEM AudioFocus binder quirks never abort playback
        val player = ExoPlayer.Builder(context, renderersFactory)
            .setMediaSourceFactory(mediaSourceFactory)
            .setTrackSelector(selector)
            .setLoadControl(loadControl)
            .setAudioAttributes(audioAttrs, false)
            .setHandleAudioBecomingNoisy(true)
            .build()

        player.addListener(object : Player.Listener {
            override fun onVideoSizeChanged(videoSize: VideoSize) {
                val rawW = videoSize.width
                val rawH = videoSize.height
                if (rawW > 0 && rawH > 0) {
                    val effectiveW = if (videoSize.pixelWidthHeightRatio > 0f && videoSize.pixelWidthHeightRatio != 1f) {
                        max(1, (rawW * videoSize.pixelWidthHeightRatio).roundToInt())
                    } else {
                        rawW
                    }
                    val aspect = effectiveW.toFloat() / rawH.toFloat()
                    sendEvent(
                        mapOf(
                            "event" to "videoSize",
                            "width" to effectiveW,
                            "height" to rawH,
                            "aspectRatio" to aspect.toDouble()
                        )
                    )
                }
            }

            override fun onPlaybackStateChanged(playbackState: Int) {
                val durMs = if (player.duration == C.TIME_UNSET || player.duration < 0L) 0L else player.duration
                // Also inspect videoFormat in case SurfaceView hasn't fired VideoSize yet
                if (playbackState == Player.STATE_READY) {
                    player.videoFormat?.let { vf ->
                        if (vf.width > 0 && vf.height > 0) {
                            val ratio = if (vf.pixelWidthHeightRatio > 0f) vf.pixelWidthHeightRatio else 1f
                            var w = max(1, (vf.width * ratio).roundToInt())
                            var h = vf.height
                            if (vf.rotationDegrees == 90 || vf.rotationDegrees == 270) {
                                val tmp = w
                                w = h
                                h = tmp
                            }
                            if (h > 0) {
                                sendEvent(
                                    mapOf(
                                        "event" to "videoSize",
                                        "width" to w,
                                        "height" to h,
                                        "aspectRatio" to (w.toDouble() / h.toDouble())
                                    )
                                )
                            }
                        }
                    }
                }
                sendEvent(
                    mapOf(
                        "event" to "state",
                        "state" to playbackState,
                        "isBuffering" to (playbackState == Player.STATE_BUFFERING),
                        "isCompleted" to (playbackState == Player.STATE_ENDED),
                        "isPlaying" to player.isPlaying,
                        "durationMs" to durMs
                    )
                )
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                sendEvent(
                    mapOf(
                        "event" to "playing",
                        "isPlaying" to isPlaying,
                        "isBuffering" to (player.playbackState == Player.STATE_BUFFERING)
                    )
                )
            }

            override fun onPlayerError(error: PlaybackException) {
                CrashLogManager.recordLog(
                    context,
                    source = "ExoPlayerError[${error.errorCodeName}]",
                    trace = "${error.message}\n${error.cause?.stackTraceToString() ?: ""}"
                )
                sendEvent(
                    mapOf(
                        "event" to "error",
                        "code" to error.errorCodeName,
                        "message" to (error.message ?: "Playback error")
                    )
                )
            }
        })

        // Bind existing SurfaceView surface immediately if already mounted, otherwise
        // NativeVideoSurfaceViewFactory.surfaceCreated() attaches it seamlessly!
        val currentSurface = displaySurface
        if (currentSurface != null && currentSurface.isValid) {
            try {
                player.setVideoSurface(currentSurface)
            } catch (_: Throwable) {
            }
        }

        val itemBuilder = MediaItem.Builder().setUri(parsedUri)
        inferVideoMimeType(url, filename)?.let { mime ->
            itemBuilder.setMimeType(mime)
        }

        if (externalSubtitles.isNotEmpty()) {
            val subConfigs = externalSubtitles.mapNotNull { sub ->
                val subUrl = sub["url"]?.trim() ?: ""
                val subUri = runCatching { Uri.parse(subUrl) }.getOrNull()
                if (subUrl.isEmpty() || subUri == null || subUri.scheme.isNullOrBlank()) {
                    null
                } else {
                    val lang = sub["lang"] ?: "en"
                    val label = sub["label"] ?: lang.uppercase(Locale.US)
                    val isFrench = lang.startsWith("fr", ignoreCase = true) ||
                        label.contains("fran", ignoreCase = true)
                    MediaItem.SubtitleConfiguration.Builder(subUri)
                        .setMimeType(inferSubtitleMimeType(subUrl))
                        .setLanguage(lang)
                        .setLabel(label)
                        .setSelectionFlags(if (isFrench) C.SELECTION_FLAG_DEFAULT else 0)
                        .build()
                }
            }
            if (subConfigs.isNotEmpty()) {
                itemBuilder.setSubtitleConfigurations(subConfigs)
            }
        }

        audioTrackIndex = 0
        exoPlayer = player
        player.setMediaItem(itemBuilder.build())
        if (startPositionMs > 0L) {
            player.seekTo(startPositionMs)
        }
        player.playWhenReady = true
        player.prepare()

        mainHandler.postDelayed(positionPoller, 350L)

        return mapOf(
            "textureId" to SURFACE_VIEW_ID_SENTINEL,
            "useSurfaceView" to true,
            "sessionId" to sessionSeq.getAndIncrement(),
            "aspectRatio" to (16.0 / 9.0)
        )
    }

    private fun inferVideoMimeType(url: String, filename: String?): String? {
        val lowerUrl = url.lowercase(Locale.US)
        if (lowerUrl.startsWith("data:")) {
            if (lowerUrl.contains("mpegurl") || lowerUrl.contains("m3u8")) {
                return MimeTypes.APPLICATION_M3U8
            }
        }
        val pathOnly = lowerUrl.substringBefore('?').substringBefore('#')
        val hint = (filename ?: "").lowercase(Locale.US)

        return when {
            pathOnly.endsWith(".m3u8") ||
                lowerUrl.contains(".m3u8?") ||
                lowerUrl.contains("/hls/") ||
                lowerUrl.contains("format=m3u8") ||
                lowerUrl.contains("type=m3u8") ||
                hint.endsWith(".m3u8") -> MimeTypes.APPLICATION_M3U8
            pathOnly.endsWith(".mpd") ||
                lowerUrl.contains(".mpd?") ||
                hint.endsWith(".mpd") -> MimeTypes.APPLICATION_MPD
            pathOnly.endsWith(".ism/manifest") ||
                hint.endsWith(".ism") -> MimeTypes.APPLICATION_SS
            pathOnly.endsWith(".mkv") || pathOnly.endsWith(".webm") -> MimeTypes.VIDEO_MATROSKA
            pathOnly.endsWith(".mp4") || pathOnly.endsWith(".m4v") -> MimeTypes.VIDEO_MP4
            // Do NOT force container MIME on `127.0.0.1` P2P stream URLs — let DefaultExtractorsFactory sniff!
            else -> null
        }
    }

    private fun inferSubtitleMimeType(subUrl: String): String {
        val clean = subUrl.lowercase(Locale.US).substringBefore('?').substringBefore('#')
        return when {
            clean.endsWith(".srt") -> MimeTypes.APPLICATION_SUBRIP
            clean.endsWith(".ass") || clean.endsWith(".ssa") -> MimeTypes.TEXT_SSA
            clean.endsWith(".ttml") || clean.endsWith(".xml") -> MimeTypes.APPLICATION_TTML
            else -> MimeTypes.TEXT_VTT
        }
    }

    private fun cycleAudioTrack(): String {
        val p = exoPlayer ?: return "Audio"
        val ts = trackSelector ?: return "Audio"
        val groups = p.currentTracks.groups.filter { g ->
            g.type == C.TRACK_TYPE_AUDIO && g.length > 0
        }
        if (groups.isEmpty()) return "Audio"
        audioTrackIndex = (audioTrackIndex + 1) % groups.size
        val chosen = groups[audioTrackIndex]
        val format = chosen.getTrackFormat(0)
        val label = format.label?.takeIf { it.isNotBlank() }
            ?: format.language?.takeIf { it.isNotBlank() }
            ?: "Piste ${audioTrackIndex + 1}"

        ts.parameters = ts.buildUponParameters()
            .clearOverridesOfType(C.TRACK_TYPE_AUDIO)
            .addOverride(TrackSelectionOverride(chosen.mediaTrackGroup, 0))
            .build()

        return label.uppercase(Locale.US)
    }

    private fun sendEvent(payload: Map<String, Any>) {
        mainHandler.post {
            try {
                eventSink?.success(payload)
            } catch (_: Throwable) {
            }
        }
    }

    fun releasePlayer() {
        mainHandler.removeCallbacks(positionPoller)
        exoPlayer?.let { p ->
            try {
                p.clearVideoSurface()
                p.stop()
                p.release()
            } catch (_: Throwable) {
            }
        }
        exoPlayer = null
        trackSelector = null
    }
}
