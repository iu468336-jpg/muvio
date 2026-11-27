package app.muvio.mobile

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

/**
 * Native AndroidX Media3 (`ExoPlayer` + Jellyfin FFmpeg Audio Decoder) playback bridge
 * backed by Flutter's `SurfaceProducer` texture.
 *
 * Replaces `media_kit` (`libmpv` Dart FFI callbacks) so video playback on 32-bit `armeabi-v7a`
 * and 64-bit `arm64-v8a` Android phones uses hardware `MediaCodec` + FFmpeg surround audio
 * decoding with zero Dart FFI callback crashes and zero UI-thread ANR!
 */
@OptIn(UnstableApi::class)
class NativeMedia3PlayerController(
    private val context: Context,
    private val textureRegistry: TextureRegistry
) {
    private val mainHandler = Handler(Looper.getMainLooper())

    private var exoPlayer: ExoPlayer? = null
    private var trackSelector: DefaultTrackSelector? = null
    private var surfaceProducer: TextureRegistry.SurfaceProducer? = null
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
                    @Suppress("UNCHECKED_CAST")
                    val headers = (args?.get("headers") as? Map<String, String>) ?: emptyMap()
                    val startPosMs = (args?.get("startPositionMs") as? Number)?.toLong() ?: 0L
                    val preferSoftware = args?.get("preferSoftware") as? Boolean ?: false
                    val info = openStream(
                        url = url,
                        headers = headers,
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
            result.error("PLAYER_ERR", t.message ?: t.toString(), null)
        }
    }

    private fun openStream(
        url: String,
        headers: Map<String, String>,
        startPositionMs: Long,
        preferSoftware: Boolean
    ): Map<String, Any> {
        mainHandler.removeCallbacks(positionPoller)

        var producer = surfaceProducer
        if (producer == null) {
            producer = textureRegistry.createSurfaceProducer()
            producer.setSize(1280, 720)
            producer.setCallback(object : TextureRegistry.SurfaceProducer.Callback {
                override fun onSurfaceAvailable() {
                    val p = exoPlayer
                    val sp = surfaceProducer
                    if (p != null && sp != null) {
                        try {
                            p.setVideoSurface(sp.surface)
                        } catch (_: Throwable) {
                        }
                    }
                }

                override fun onSurfaceCleanup() {
                    try {
                        exoPlayer?.clearVideoSurface()
                    } catch (_: Throwable) {
                    }
                }
            })
            surfaceProducer = producer
        }

        // Release any previous ExoPlayer instance while reusing the active SurfaceProducer cleanly
        exoPlayer?.let { old ->
            try {
                old.clearVideoSurface()
                old.stop()
                old.release()
            } catch (_: Throwable) {
            }
        }
        exoPlayer = null

        val userAgent = headers["User-Agent"]
            ?: "Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36"

        val httpFactory = DefaultHttpDataSource.Factory()
            .setUserAgent(userAgent)
            .setAllowCrossProtocolRedirects(true)
            .setConnectTimeoutMs(18_000)
            .setReadTimeoutMs(30_000)

        if (headers.isNotEmpty()) {
            httpFactory.setDefaultRequestProperties(headers)
        }

        val dataSourceFactory = DefaultDataSource.Factory(context, httpFactory)
        val mediaSourceFactory = DefaultMediaSourceFactory(context)
            .setDataSourceFactory(dataSourceFactory)

        // Bounded RAM buffers (max 16 MB) so 32-bit armeabi-v7a phones with 2 GB RAM never OOM
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                /* minBufferMs = */ 4_000,
                /* maxBufferMs = */ 18_000,
                /* bufferForPlaybackMs = */ 1_200,
                /* bufferForPlaybackAfterRebufferMs = */ 2_500
            )
            .setTargetBufferBytes(16 * 1024 * 1024)
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
                .setPreferredTextLanguage("fr")
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
                        surfaceProducer?.setSize(w, h)
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
                sendEvent(
                    mapOf(
                        "event" to "error",
                        "code" to error.errorCodeName,
                        "message" to (error.message ?: "Playback error")
                    )
                )
            }
        })

        player.setVideoSurface(producer.surface)

        val itemBuilder = MediaItem.Builder().setUri(Uri.parse(url))
        val lowerUrl = url.lowercase()
        when {
            lowerUrl.contains(".m3u8") -> itemBuilder.setMimeType("application/x-mpegURL")
            lowerUrl.contains(".mpd") -> itemBuilder.setMimeType("application/dash+xml")
        }

        player.setMediaItem(itemBuilder.build())
        if (startPositionMs > 0L) {
            player.seekTo(startPositionMs)
        }
        player.playWhenReady = true
        player.prepare()

        exoPlayer = player
        mainHandler.postDelayed(positionPoller, 400L)

        return mapOf(
            "textureId" to producer.id(),
            "aspectRatio" to (16.0 / 9.0)
        )
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
        val lang = format.language ?: format.label ?: "Piste ${audioTrackIndex + 1}"
        if (format.language != null) {
            ts.parameters = ts.buildUponParameters()
                .setPreferredAudioLanguage(format.language)
                .build()
        }
        return lang.uppercase()
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

        surfaceProducer?.let { sp ->
            try {
                sp.release()
            } catch (_: Throwable) {
            }
        }
        surfaceProducer = null
    }
}
