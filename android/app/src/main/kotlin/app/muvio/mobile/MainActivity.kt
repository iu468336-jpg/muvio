package app.muvio.mobile

import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val torrentChannelName = "app.muvio.mobile/torrent_engine"
    private val playerChannelName = "app.muvio.mobile/native_player"
    private val playerEventsChannelName = "app.muvio.mobile/native_player_events"
    private val pipChannelName = "app.muvio.mobile/pip"

    @Volatile
    private var streamController: LocalTorrentStreamController? = null
    private var media3Controller: NativeMedia3PlayerController? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val playerCtrl = NativeMedia3PlayerController(
            context = applicationContext,
            textureRegistry = flutterEngine.renderer
        )
        playerCtrl.attachEventChannel(EventChannel(messenger, playerEventsChannelName))
        media3Controller = playerCtrl

        MethodChannel(messenger, playerChannelName).setMethodCallHandler { call, result ->
            @Suppress("UNCHECKED_CAST")
            val args = call.arguments as? Map<String, Any?>
            playerCtrl.handleMethodCall(call.method, args, result)
        }

        MethodChannel(messenger, torrentChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "startTorrentStream" -> {
                    val uri = call.argument<String>("uri") ?: ""
                    val infoHash = call.argument<String>("infoHash")
                    val fileIdx = call.argument<Int>("fileIdx") ?: 0
                    val sources = call.argument<List<String>>("sources") ?: emptyList()
                    Thread {
                        try {
                            var ctrl = streamController
                            if (ctrl == null) {
                                val cacheRoot = File(cacheDir, "muvio_torrents")
                                cacheRoot.mkdirs()
                                ctrl = LocalTorrentStreamController(cacheRoot)
                                streamController = ctrl
                            }
                            val localUrl = ctrl.startSequentialStream(
                                magnetOrUri = uri,
                                infoHash = infoHash,
                                fileIndex = fileIdx,
                                sources = sources
                            )
                            runOnUiThread {
                                result.success(localUrl)
                            }
                        } catch (t: Throwable) {
                            runOnUiThread {
                                result.error("TORRENT_ERR", t.message ?: t.toString(), null)
                            }
                        }
                    }.apply {
                        name = "MuvioStartTorrent"
                        isDaemon = true
                        start()
                    }
                }
                "getTorrentStatus" -> {
                    try {
                        val status = streamController?.getCachedStatus() ?: mapOf(
                            "hasMetadata" to false,
                            "readyToPlay" to false,
                            "peers" to 0,
                            "seeds" to 0,
                            "downloadSpeed" to 0,
                            "progress" to 0.0,
                            "bufferedBytes" to 0L,
                            "fileSize" to 0L
                        )
                        result.success(status)
                    } catch (t: Throwable) {
                        result.error("STATUS_ERR", t.message ?: t.toString(), null)
                    }
                }
                "stopTorrentStream" -> {
                    val old = streamController
                    streamController = null
                    old?.stopAsync()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, pipChannelName).setMethodCallHandler { call, result ->
            if (call.method == "enterPip") {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val params = PictureInPictureParams.Builder()
                            .setAspectRatio(Rational(16, 9))
                            .build()
                        val ok = enterPictureInPictureMode(params)
                        result.success(ok)
                    } else {
                        result.success(false)
                    }
                } catch (_: Throwable) {
                    result.success(false)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        try {
            media3Controller?.releasePlayer()
        } catch (_: Throwable) {
        }
        media3Controller = null

        val oldTorrent = streamController
        streamController = null
        oldTorrent?.stopAsync()

        super.onDestroy()
    }
}
