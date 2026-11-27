package app.muvio.mobile

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/**
 * Main-process IPC client talking to `TorrentForegroundService` (`android:process=":torrent"`).
 *
 * Pre-warms NuvioEngine's DHT session in the background so peer discovery is instant when the user
 * selects a P2P stream.
 */
class TorrentServiceClient(private val appContext: Context) {

    private val mainHandler = Handler(Looper.getMainLooper())
    private val nextRequestId = AtomicInteger(1)

    @Volatile
    private var serviceMessenger: Messenger? = null

    @Volatile
    private var bindingInProgress: Boolean = false

    private val pendingStartCallbacks = ConcurrentHashMap<Int, (String?, String?) -> Unit>()
    private val pendingStatusCallbacks = ConcurrentHashMap<Int, (Map<String, Any>) -> Unit>()
    private val waitQueue = ArrayList<(Messenger?) -> Unit>()

    private val clientMessenger = Messenger(
        Handler(Looper.getMainLooper()) { msg ->
            val reqId = msg.arg1
            val data = msg.data
            when (msg.what) {
                TorrentForegroundService.REPLY_START_OK -> {
                    val cb = pendingStartCallbacks.remove(reqId)
                    cb?.invoke(data.getString("localUrl"), null)
                    true
                }
                TorrentForegroundService.REPLY_START_ERR -> {
                    val cb = pendingStartCallbacks.remove(reqId)
                    cb?.invoke(null, data.getString("error") ?: "Torrent start error")
                    true
                }
                TorrentForegroundService.REPLY_STATUS -> {
                    val cb = pendingStatusCallbacks.remove(reqId)
                    if (cb != null) {
                        val map = mapOf<String, Any>(
                            "hasMetadata" to data.getBoolean("hasMetadata", false),
                            "readyToPlay" to data.getBoolean("readyToPlay", false),
                            "peers" to data.getInt("peers", 0),
                            "seeds" to data.getInt("seeds", 0),
                            "downloadSpeed" to data.getInt("downloadSpeed", 0),
                            "progress" to data.getDouble("progress", 0.0),
                            "bufferedBytes" to data.getLong("bufferedBytes", 0L),
                            "fileSize" to data.getLong("fileSize", 0L)
                        )
                        cb.invoke(map)
                    }
                    true
                }
                else -> false
            }
        }
    )

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val messenger = if (service != null) Messenger(service) else null
            serviceMessenger = messenger
            bindingInProgress = false
            val waiters: List<(Messenger?) -> Unit>
            synchronized(waitQueue) {
                waiters = ArrayList(waitQueue)
                waitQueue.clear()
            }
            for (w in waiters) {
                w.invoke(messenger)
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            serviceMessenger = null
            bindingInProgress = false
            failPendingCallbacks("Service torrent redémarré")
        }

        override fun onBindingDied(name: ComponentName?) {
            serviceMessenger = null
            bindingInProgress = false
            try {
                appContext.unbindService(this)
            } catch (_: Throwable) {
            }
            failPendingCallbacks("Connexion au service torrent interrompue")
        }
    }

    private fun failPendingCallbacks(reason: String) {
        val startKeys = pendingStartCallbacks.keys.toList()
        for (k in startKeys) {
            pendingStartCallbacks.remove(k)?.invoke(null, reason)
        }
        val statusKeys = pendingStatusCallbacks.keys.toList()
        for (k in statusKeys) {
            pendingStatusCallbacks.remove(k)?.invoke(emptyStatus())
        }
    }

    private fun emptyStatus(): Map<String, Any> = mapOf(
        "hasMetadata" to false,
        "readyToPlay" to false,
        "peers" to 0,
        "seeds" to 0,
        "downloadSpeed" to 0,
        "progress" to 0.0,
        "bufferedBytes" to 0L,
        "fileSize" to 0L
    )

    fun warmUp() {
        withConnectedMessenger { messenger ->
            if (messenger != null) {
                try {
                    messenger.send(Message.obtain(null, TorrentForegroundService.MSG_WARM_UP))
                } catch (_: Throwable) {
                }
            }
        }
    }

    private fun withConnectedMessenger(action: (Messenger?) -> Unit) {
        val existing = serviceMessenger
        if (existing != null && existing.binder.isBinderAlive) {
            action(existing)
            return
        }
        serviceMessenger = null
        synchronized(waitQueue) {
            waitQueue.add(action)
        }
        if (!bindingInProgress) {
            bindingInProgress = true
            try {
                val intent = Intent(appContext, TorrentForegroundService::class.java)
                val bound = appContext.bindService(
                    intent,
                    connection,
                    Context.BIND_AUTO_CREATE or Context.BIND_IMPORTANT
                )
                if (!bound) {
                    bindingInProgress = false
                    val waiters: List<(Messenger?) -> Unit>
                    synchronized(waitQueue) {
                        waiters = ArrayList(waitQueue)
                        waitQueue.clear()
                    }
                    for (w in waiters) w(null)
                }
            } catch (_: Throwable) {
                bindingInProgress = false
                val waiters: List<(Messenger?) -> Unit>
                synchronized(waitQueue) {
                    waiters = ArrayList(waitQueue)
                    waitQueue.clear()
                }
                for (w in waiters) w(null)
            }
        }
    }

    fun startStream(
        uri: String,
        infoHash: String?,
        fileIdx: Int,
        filenameHint: String?,
        sources: List<String>,
        result: MethodChannel.Result
    ) {
        withConnectedMessenger { messenger ->
            if (messenger == null) {
                mainHandler.post {
                    try {
                        result.error("BIND_ERR", "Impossible de joindre le moteur P2P Nuvio", null)
                    } catch (_: Throwable) {
                    }
                }
                return@withConnectedMessenger
            }

            val reqId = nextRequestId.getAndIncrement()
            pendingStartCallbacks[reqId] = { localUrl, err ->
                mainHandler.post {
                    try {
                        if (localUrl != null) {
                            result.success(localUrl)
                        } else {
                            result.error("TORRENT_ERR", err ?: "Erreur moteur P2P Nuvio", null)
                        }
                    } catch (_: Throwable) {
                    }
                }
            }

            // Safety timeout (42 s) matching NuvioEngine metadata timeout + margin
            mainHandler.postDelayed({
                val stale = pendingStartCallbacks.remove(reqId)
                if (stale != null) {
                    try {
                        result.error("TIMEOUT", "Aucun pair actif trouvé à temps pour cette source P2P", null)
                    } catch (_: Throwable) {
                    }
                }
            }, 42_000L)

            val msg = Message.obtain(null, TorrentForegroundService.MSG_START_STREAM, reqId, 0).apply {
                replyTo = clientMessenger
                data = Bundle().apply {
                    putString("uri", uri)
                    putString("infoHash", infoHash)
                    putInt("fileIdx", fileIdx)
                    putString("filenameHint", filenameHint)
                    putStringArrayList("sources", ArrayList(sources))
                }
            }

            try {
                messenger.send(msg)
            } catch (t: Throwable) {
                pendingStartCallbacks.remove(reqId)
                serviceMessenger = null
                mainHandler.post {
                    try {
                        result.error("IPC_ERR", t.message ?: t.toString(), null)
                    } catch (_: Throwable) {
                    }
                }
            }
        }
    }

    fun getStatus(result: MethodChannel.Result) {
        val messenger = serviceMessenger
        if (messenger == null || !messenger.binder.isBinderAlive) {
            try {
                result.success(emptyStatus())
            } catch (_: Throwable) {
            }
            return
        }

        val reqId = nextRequestId.getAndIncrement()
        pendingStatusCallbacks[reqId] = { status ->
            mainHandler.post {
                try {
                    result.success(status)
                } catch (_: Throwable) {
                }
            }
        }

        mainHandler.postDelayed({
            val stale = pendingStatusCallbacks.remove(reqId)
            if (stale != null) {
                try {
                    result.success(emptyStatus())
                } catch (_: Throwable) {
                }
            }
        }, 2_000L)

        val msg = Message.obtain(null, TorrentForegroundService.MSG_GET_STATUS, reqId, 0).apply {
            replyTo = clientMessenger
        }
        try {
            messenger.send(msg)
        } catch (_: Throwable) {
            pendingStatusCallbacks.remove(reqId)
            try {
                result.success(emptyStatus())
            } catch (_: Throwable) {
            }
        }
    }

    fun stopStream(result: MethodChannel.Result?) {
        val messenger = serviceMessenger
        if (messenger != null && messenger.binder.isBinderAlive) {
            val reqId = nextRequestId.getAndIncrement()
            val msg = Message.obtain(null, TorrentForegroundService.MSG_STOP_STREAM, reqId, 0).apply {
                replyTo = clientMessenger
            }
            try {
                messenger.send(msg)
            } catch (_: Throwable) {
            }
        }
        if (result != null) {
            try {
                result.success(null)
            } catch (_: Throwable) {
            }
        }
    }

    fun shutdown() {
        stopStream(null)
        serviceMessenger = null
        try {
            appContext.unbindService(connection)
        } catch (_: Throwable) {
        }
    }
}
