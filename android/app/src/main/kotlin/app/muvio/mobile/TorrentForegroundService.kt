package app.muvio.mobile

import android.app.Service
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.io.File

/**
 * Isolated Android `:torrent` sub-process service (`android:process=":torrent"`)
 * hosting Nuvio's native C++ P2P engine (`NuvioEngine`).
 *
 * Architectural guarantees:
 * 1. Runs in its own OS process (`:torrent`) with its own 32-bit/64-bit virtual address space,
 *    completely isolated from Flutter's UI / Skia / Media3 `ExoPlayer` process.
 * 2. Keeps `NuvioEngine` + DHT warm across source switches (`stopCurrentStreamAsync()` instead of
 *    destroying the engine on every stop) so subsequent torrent clicks resolve peers in seconds.
 */
class TorrentForegroundService : Service() {

    companion object {
        const val MSG_START_STREAM = 1
        const val MSG_GET_STATUS = 2
        const val MSG_STOP_STREAM = 3
        const val MSG_WARM_UP = 4

        const val REPLY_START_OK = 101
        const val REPLY_START_ERR = 102
        const val REPLY_STATUS = 103
        const val REPLY_STOP_OK = 104
    }

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    @Volatile
    private var controller: LocalTorrentStreamController? = null

    private fun ensureController(): LocalTorrentStreamController {
        val existing = controller
        if (existing != null) return existing
        synchronized(this) {
            val second = controller
            if (second != null) return second
            val cacheRoot = File(cacheDir, "muvio_nuvio_p2p").apply { mkdirs() }
            return LocalTorrentStreamController(cacheRoot).also {
                controller = it
            }
        }
    }

    private val incomingHandler = Handler(Looper.getMainLooper()) { msg ->
        val replyTo = msg.replyTo
        val reqId = msg.arg1
        val data = msg.data

        when (msg.what) {
            MSG_WARM_UP -> {
                ensureController().warmUp()
                true
            }

            MSG_START_STREAM -> {
                val uri = data.getString("uri") ?: ""
                val infoHash = data.getString("infoHash")
                val fileIdx = data.getInt("fileIdx", -1)
                val filenameHint = data.getString("filenameHint")
                val sources = data.getStringArrayList("sources") ?: arrayListOf()

                serviceScope.launch {
                    try {
                        val ctrl = ensureController()
                        val localUrl = ctrl.startSequentialStream(
                            magnetOrUri = uri,
                            infoHash = infoHash,
                            fileIndex = fileIdx,
                            filenameHint = filenameHint,
                            sources = sources
                        )
                        val reply = Message.obtain(null, REPLY_START_OK, reqId, 0).apply {
                            this.data = Bundle().apply {
                                putString("localUrl", localUrl)
                            }
                        }
                        try {
                            replyTo?.send(reply)
                        } catch (_: Throwable) {
                        }
                    } catch (t: Throwable) {
                        CrashLogManager.recordLog(
                            applicationContext,
                            source = "NuvioTorrentStart",
                            trace = t.stackTraceToString()
                        )
                        val reply = Message.obtain(null, REPLY_START_ERR, reqId, 0).apply {
                            this.data = Bundle().apply {
                                putString("error", t.message ?: t.toString())
                            }
                        }
                        try {
                            replyTo?.send(reply)
                        } catch (_: Throwable) {
                        }
                    }
                }
                true
            }

            MSG_GET_STATUS -> {
                val statusMap = controller?.getCachedStatus()
                    ?: LocalTorrentStreamController.emptyTelemetry()
                val bundle = Bundle().apply {
                    putBoolean("hasMetadata", statusMap["hasMetadata"] as? Boolean ?: false)
                    putBoolean("readyToPlay", statusMap["readyToPlay"] as? Boolean ?: false)
                    putInt("peers", (statusMap["peers"] as? Number)?.toInt() ?: 0)
                    putInt("seeds", (statusMap["seeds"] as? Number)?.toInt() ?: 0)
                    putInt("downloadSpeed", (statusMap["downloadSpeed"] as? Number)?.toInt() ?: 0)
                    putDouble("progress", (statusMap["progress"] as? Number)?.toDouble() ?: 0.0)
                    putLong("bufferedBytes", (statusMap["bufferedBytes"] as? Number)?.toLong() ?: 0L)
                    putLong("fileSize", (statusMap["fileSize"] as? Number)?.toLong() ?: 0L)
                }
                val reply = Message.obtain(null, REPLY_STATUS, reqId, 0).apply {
                    this.data = bundle
                }
                try {
                    replyTo?.send(reply)
                } catch (_: Throwable) {
                }
                true
            }

            MSG_STOP_STREAM -> {
                // Keep controller + DHT session alive! Only stop the active stream.
                controller?.stopCurrentStreamAsync()
                val reply = Message.obtain(null, REPLY_STOP_OK, reqId, 0)
                try {
                    replyTo?.send(reply)
                } catch (_: Throwable) {
                }
                true
            }

            else -> false
        }
    }

    private val serviceMessenger = Messenger(incomingHandler)

    override fun onCreate() {
        super.onCreate()
        CrashLogManager.install(applicationContext, processTag = "torrent")
        ensureController().warmUp()
    }

    override fun onBind(intent: Intent?): IBinder = serviceMessenger.binder

    override fun onDestroy() {
        val old = controller
        controller = null
        old?.shutdownAsync()
        serviceScope.cancel()
        super.onDestroy()
    }
}
