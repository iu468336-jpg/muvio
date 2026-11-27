package app.muvio.mobile

import android.content.Context
import android.os.Build
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Persists uncaught JVM/Kotlin and Dart exceptions to disk so the user can inspect
 * or copy any crash trace directly inside Muvio Settings without needing `adb logcat`.
 */
object CrashLogManager {
    private const val FILE_NAME = "muvio_last_crash.txt"

    @Volatile
    private var installed = false

    fun install(context: Context, processTag: String = "ui") {
        if (installed) return
        installed = true
        val appCtx = context.applicationContext
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                val sw = StringWriter()
                throwable.printStackTrace(PrintWriter(sw))
                recordLog(
                    appCtx,
                    source = "AndroidUncaught[$processTag/${thread.name}]",
                    trace = sw.toString()
                )
            } catch (_: Throwable) {
            }
            previous?.uncaughtException(thread, throwable)
        }
    }

    fun recordLog(context: Context, source: String, trace: String) {
        try {
            val stamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())
            val abis = Build.SUPPORTED_ABIS?.joinToString(",") ?: "unknown"
            val header = buildString {
                appendLine("=== Muvio Crash / Error Report ===")
                appendLine("Time: $stamp")
                appendLine("Source: $source")
                appendLine("Device: ${Build.MANUFACTURER} ${Build.MODEL} (SDK ${Build.VERSION.SDK_INT}, ABIs: $abis)")
                appendLine("----------------------------------")
                appendLine(trace.take(12_000))
                appendLine()
            }
            val file = File(context.filesDir, FILE_NAME)
            val existing = if (file.exists()) file.readText().takeLast(12_000) else ""
            file.writeText(header + existing)
        } catch (_: Throwable) {
        }
    }

    fun readLog(context: Context): String {
        return try {
            val file = File(context.filesDir, FILE_NAME)
            if (file.exists()) file.readText() else ""
        } catch (_: Throwable) {
            ""
        }
    }

    fun clearLog(context: Context) {
        try {
            val file = File(context.filesDir, FILE_NAME)
            if (file.exists()) {
                file.delete()
            }
        } catch (_: Throwable) {
        }
    }
}
