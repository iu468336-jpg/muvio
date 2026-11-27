package app.muvio.mobile

import android.app.PictureInPictureParams
import android.os.Build
import android.os.Bundle
import android.util.Rational
import app.muvio.mobile.nuvio.NuvioPluginRuntimeController
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.renderer.FlutterRenderer
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val torrentChannelName = "app.muvio.mobile/torrent_engine"
    private val nuvioPluginsChannelName = "app.muvio.mobile/nuvio_plugins"
    private val playerChannelName = "app.muvio.mobile/native_player"
    private val playerEventsChannelName = "app.muvio.mobile/native_player_events"
    private val pipChannelName = "app.muvio.mobile/pip"
    private val diagnosticsChannelName = "app.muvio.mobile/diagnostics"

    private var torrentClient: TorrentServiceClient? = null
    private var media3Controller: NativeMedia3PlayerController? = null
    private var nuvioPluginController: NuvioPluginRuntimeController? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Since EnableImpeller=false runs Flutter on Skia OpenGL ES, pin GL textures
        // globally before engine startup so ImageReaderSurfaceProducer (AHardwareBuffer)
        // never triggers Gralloc stride crashes on MediaTek/Mali/HiSilicon devices.
        try {
            FlutterRenderer.debugForceSurfaceProducerGlTextures = true
        } catch (_: Throwable) {
        }
        CrashLogManager.install(applicationContext, processTag = "ui")
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        val playerCtrl = NativeMedia3PlayerController(
            context = applicationContext,
            textureRegistry = flutterEngine.renderer
        )
        playerCtrl.attachEventChannel(EventChannel(messenger, playerEventsChannelName))
        media3Controller = playerCtrl

        val client = TorrentServiceClient(applicationContext).also {
            it.warmUp()
        }
        torrentClient = client

        val nuvioPlugins = NuvioPluginRuntimeController(applicationContext)
        nuvioPluginController = nuvioPlugins

        MethodChannel(messenger, playerChannelName).setMethodCallHandler { call, result ->
            @Suppress("UNCHECKED_CAST")
            val args = call.arguments as? Map<String, Any?>
            playerCtrl.handleMethodCall(call.method, args, result)
        }

        MethodChannel(messenger, nuvioPluginsChannelName).setMethodCallHandler { call, result ->
            @Suppress("UNCHECKED_CAST")
            val args = call.arguments as? Map<String, Any?>
            nuvioPlugins.handleMethodCall(call.method, args, result)
        }

        MethodChannel(messenger, torrentChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "startTorrentStream" -> {
                    val uri = call.argument<String>("uri") ?: ""
                    val infoHash = call.argument<String>("infoHash")
                    val fileIdx = call.argument<Int>("fileIdx") ?: -1
                    val filenameHint = call.argument<String>("filenameHint")
                    val sources = call.argument<List<String>>("sources") ?: emptyList()
                    client.startStream(
                        uri = uri,
                        infoHash = infoHash,
                        fileIdx = fileIdx,
                        filenameHint = filenameHint,
                        sources = sources,
                        result = result
                    )
                }
                "getTorrentStatus" -> {
                    client.getStatus(result)
                }
                "stopTorrentStream" -> {
                    client.stopStream(result)
                }
                "warmUp" -> {
                    client.warmUp()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, diagnosticsChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "recordCrash" -> {
                    val source = call.argument<String>("source") ?: "FlutterDart"
                    val trace = call.argument<String>("trace") ?: ""
                    CrashLogManager.recordLog(applicationContext, source, trace)
                    result.success(null)
                }
                "readCrashLog" -> {
                    result.success(CrashLogManager.readLog(applicationContext))
                }
                "clearCrashLog" -> {
                    CrashLogManager.clearLog(applicationContext)
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

        try {
            nuvioPluginController?.shutdown()
        } catch (_: Throwable) {
        }
        nuvioPluginController = null

        try {
            torrentClient?.shutdown()
        } catch (_: Throwable) {
        }
        torrentClient = null

        super.onDestroy()
    }
}
