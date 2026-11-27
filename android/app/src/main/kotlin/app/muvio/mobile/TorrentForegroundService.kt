package app.muvio.mobile

import android.app.Service
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import java.io.File

/**
 * Isolated Android `:torrent` sub-process service (`android:process=":torrent"`)
 * hosting `libtorrent4j:2.1.0-38` (`SessionManager`) + `NanoHTTPD` (`127.0.0.1:<port>/stream`).
 *
 * Architectural guarantees:
 * 1. Runs in its own OS process (`:torrent`) with its own 32-bit/64-bit virtual address space,
 *    Java heap, file descriptor table, and POSIX signal handlers — completely isolated from
 *    Flutter's UI / Skia / Media3 `ExoPlayer` process!
 * 2. Bound via `bindService(..., Context.BIND_AUTO_CREATE or Context.BIND_IMPORTANT)` (no
 *    `startForeground()` needed, avoiding all Android 14/15 `targetSdk = 35`
 *    `ForegroundServiceStartNotAllowedException` / `SecurityException` restrictions).
 * 3. Even if an extreme torrent or peer ever triggers a native C++ error in `libtorrent`,
 *    only the `:torrent` worker restarts cleanly — the Muvio UI NEVER crashes!
 */
class TorrentForegroundService : Service() {

    companion object {
        const val MSG_START_STREAM = 1
        const val MSG_GET_STATUS = 2
        const val MSG_STOP_STREAM = 3

        const val REPLY_START_OK = 101
        const val REPLY_START_ERR = 102
        const val REPLY_STATUS = 103
        const val REPLY_STOP_OK = 104
    }

    @Volatile
    private var controller: LocalTorrentStreamController? = null

    private val incomingHandler = Handler(Looper.getMainLooper()) { msg ->
        val replyTo = msg.replyTo
        val reqId = msg.arg1
        val data = msg.data

        when (msg.what) {
            MSG_START_STREAM -> {
                val uri = data.getString("uri") ?: ""
                val infoHash = data.getString("infoHash")
                val fileIdx = data.getInt("fileIdx", 0)
                val sources = data.getStringArrayList("sources") ?: arrayListOf()

                Thread {
                    try {
                        var ctrl = controller
                        if (ctrl == null) {
                            val cacheRoot = File(cacheDir, "muvio_torrents")
                            cacheRoot.mkdirs()
                            ctrl = LocalTorrentStreamController(cacheRoot)
                            controller = ctrl
                        }
                        val localUrl = ctrl.startSequentialStream(
                            magnetOrUri = uri,
                            infoHash = infoHash,
                            fileIndex = fileIdx,
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
                            source = "TorrentProcessStart",
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
                }.apply {
                    name = "MuvioTorrentWorkerStart"
                    isDaemon = true
                    start()
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
                val old = controller
                controller = null
                old?.stopAsync()
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
    }

    override fun onBind(intent: Intent?): IBinder = serviceMessenger.binder

    override fun onDestroy() {
        val old = controller
        controller = null
        old?.stopAsync()
        super.onDestroy()
    }
}
