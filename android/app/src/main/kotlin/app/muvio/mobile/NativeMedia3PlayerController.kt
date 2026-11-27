package app.muvio.mobile

import android.content.Context
import android.net.Uri
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
import io.flutter.view.TextureRegistry
import okhttp3.OkHttpClient
import java.security.SecureRandom
import java.security.cert.X509Certificate
import java.util.Locale
import java.util.concurrent.TimeUnit
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

/**
 * Nuvio-grade AndroidX Media3 (`ExoPlayer` + Jellyfin FFmpeg Audio Decoder) playback engine
 * backed by Flutter's OpenGL ES `SurfaceTextureEntry` (`createSurfaceTexture()`).
 *
 * Key capabilities matching NuvioMobile:
 * 1. Trust-all OkHttp Media3 DataSource with custom `Referer`/`Origin`/`Cookie`/`User-Agent`
 *    headers (while stripping fixed `Range` headers so Media3 manages byte-range seeks cleanly).
 * 2. 65-second read timeout on `127.0.0.1` / `localhost` so P2P piece fetching never prematurely
 *    triggers `PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT`.
 * 3. `BufferedReadDataSource` (64 KiB read-ahead) + `InlineDataUriDataSource` (`data:` HLS support).
 * 4. `DefaultExtractorsFactory` with `FLAG_ENABLE_HDMV_DTS_AUDIO_STREAMS` + `constantBitrateSeeking`.
 * 5. External WebVTT / SRT / ASS subtitle sidecar injection (`MediaItem.SubtitleConfiguration`).
 */
@OptIn(UnstableApi::class)
class NativeMedia3PlayerController(
    private val context: Context,
    private val textureRegistry: TextureRegistry
) {
    companion object {
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
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    private var exoPlayer: ExoPlayer? = null
    private var trackSelector: DefaultTrackSelector? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var videoSurface: Surface? = null
    private var eventSink: EventChannel.EventSink? = null
    private var audioTrackIndex: Int = 0
    private var subtitlesEnabled: Boolean = true

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

        var entry = textureEntry
        var surface = videoSurface
        if (entry == null || surface == null || !surface.isValid) {
            try {
                surface?.release()
            } catch (_: Throwable) {
            }
            try {
                entry?.release()
            } catch (_: Throwable) {
            }
            entry = textureRegistry.createSurfaceTexture()
            val st = entry.surfaceTexture()
            st.setDefaultBufferSize(1280, 720)
            surface = Surface(st)
            textureEntry = entry
            videoSurface = surface
        }

        // Sanitize headers: extract User-Agent and strip any fixed Range header so Media3 can seek freely
        var userAgent = DEFAULT_USER_AGENT
        val cleanHeaders = HashMap<String, String>()
        for ((k, v) in headers) {
            val trimmedKey = k.trim()
            val trimmedVal = v.trim()
            if (trimmedKey.isEmpty() || trimmedVal.isEmpty()) continue
            when {
                trimmedKey.equals("User-Agent", ignoreCase = true) -> userAgent = trimmedVal
                trimmedKey.equals("Range", ignoreCase = true) -> Unit
                else -> cleanHeaders[trimmedKey] = trimmedVal
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

        // Fast-start RAM buffer config tuned for instant startup + 32-bit ARM safety
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                /* minBufferMs = */ 8_000,
                /* maxBufferMs = */ 24_000,
                /* bufferForPlaybackMs = */ 900,
                /* bufferForPlaybackAfterRebufferMs = */ 2_000
            )
            .setTargetBufferBytes(20 * 1024 * 1024)
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
            parameters = buildUponParameters()
                .setPreferredAudioLanguages("fr", "fra", "fre", "en", "eng")
                .setPreferredTextLanguages("fr", "fra", "fre", "en", "eng")
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, !subtitlesEnabled)
                .build()
        }
        trackSelector = selector

        val audioAttrs = AudioAttributes.Builder()
            .setUsage(C.USAGE_MEDIA)
            .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
            .build()

        val player = ExoPlayer.Builder(context, renderersFactory)
            .setMediaSourceFactory(mediaSourceFactory)
            .setTrackSelector(selector)
            .setLoadControl(loadControl)
            .setAudioAttributes(audioAttrs, true)
            .setHandleAudioBecomingNoisy(true)
            .build()

        player.addListener(object : Player.Listener {
            override fun onVideoSizeChanged(videoSize: VideoSize) {
                val w = videoSize.width
                val h = videoSize.height
                if (w > 0 && h > 0) {
                    try {
                        textureEntry?.surfaceTexture()?.setDefaultBufferSize(w, h)
                    } catch (_: Throwable) {
                    }
                    val aspect = if (videoSize.pixelWidthHeightRatio > 0f) {
                        (w.toFloat() * videoSize.pixelWidthHeightRatio) / h.toFloat()
                    } else {
                        w.toFloat() / h.toFloat()
                    }
                    sendEvent(
                        mapOf(
                            "event" to "videoSize",
                            "width" to w,
                            "height" to h,
                            "aspectRatio" to aspect.toDouble()
                        )
                    )
                }
            }

            override fun onPlaybackStateChanged(playbackState: Int) {
                val durMs = if (player.duration == C.TIME_UNSET || player.duration < 0L) 0L else player.duration
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

        player.setVideoSurface(surface)

        val itemBuilder = MediaItem.Builder().setUri(parsedUri)
        inferVideoMimeType(url, filename)?.let { mime ->
            itemBuilder.setMimeType(mime)
        }

        if (externalSubtitles.isNotEmpty()) {
            val subConfigs = externalSubtitles.mapIndexed { idx, sub ->
                val subUrl = sub["url"] ?: ""
                val lang = sub["lang"] ?: "en"
                val label = sub["label"] ?: lang.uppercase(Locale.US)
                val isFrench = lang.startsWith("fr", ignoreCase = true) ||
                    label.contains("fran", ignoreCase = true)
                MediaItem.SubtitleConfiguration.Builder(Uri.parse(subUrl))
                    .setMimeType(inferSubtitleMimeType(subUrl))
                    .setLanguage(lang)
                    .setLabel(label)
                    .setSelectionFlags(if (idx == 0 || isFrench) C.SELECTION_FLAG_DEFAULT else 0)
                    .build()
            }
            itemBuilder.setSubtitleConfigurations(subConfigs)
        }

        audioTrackIndex = 0
        player.setMediaItem(itemBuilder.build())
        if (startPositionMs > 0L) {
            player.seekTo(startPositionMs)
        }
        player.playWhenReady = true
        player.prepare()

        exoPlayer = player
        mainHandler.postDelayed(positionPoller, 350L)

        return mapOf(
            "textureId" to entry.id(),
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

        videoSurface?.let { s ->
            try {
                s.release()
            } catch (_: Throwable) {
            }
        }
        videoSurface = null

        textureEntry?.let { entry ->
            try {
                entry.release()
            } catch (_: Throwable) {
            }
        }
        textureEntry = null
    }
}
