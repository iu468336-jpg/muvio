package app.muvio.mobile

import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val torrentChannelName = "app.muvio.mobile/torrent_engine"
    private val pipChannelName = "app.muvio.mobile/pip"
    private var streamController: LocalTorrentStreamController? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, torrentChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startTorrentStream" -> {
                        val uri = call.argument<String>("uri") ?: ""
                        val infoHash = call.argument<String>("infoHash")
                        val fileIdx = call.argument<Int>("fileIdx") ?: 0
                        try {
                            if (streamController == null) {
                                val cacheRoot = File(cacheDir, "muvio_torrents")
                                cacheRoot.mkdirs()
                                streamController = LocalTorrentStreamController(cacheRoot)
                            }
                            val localUrl = streamController!!.startSequentialStream(
                                magnetOrUri = uri,
                                infoHash = infoHash,
                                fileIndex = fileIdx
                            )
                            result.success(localUrl)
                        } catch (t: Throwable) {
                            result.error("TORRENT_ERR", t.message, null)
                        }
                    }
                    "stopTorrentStream" -> {
                        streamController?.stop()
                        streamController = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, pipChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "enterPip") {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val params = PictureInPictureParams.Builder()
                            .setAspectRatio(Rational(16, 9))
                            .build()
                        val ok = enterPictureInPictureMode(params)
                        result.success(ok)
                    } else {
                        result.success(false)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        streamController?.stop()
        streamController = null
        super.onDestroy()
    }
}
