package app.muvio.mobile

import fi.iki.elonen.NanoHTTPD
import org.libtorrent4j.SessionManager
import org.libtorrent4j.TorrentFlags
import java.io.File
import java.io.FileInputStream

/**
 * Progressive torrent engine powered by libtorrent4j + NanoHTTPD.
 * Prioritizes sequential piece downloading and serves byte-range HTTP streams
 * on `http://127.0.0.1:<port>/stream` for instant `media_kit` playback.
 */
class LocalTorrentStreamController(private val saveDir: File) {
    private var sessionManager: SessionManager? = null
    private var httpServer: ProgressiveHttpServer? = null

    fun startSequentialStream(
        magnetOrUri: String,
        infoHash: String?,
        fileIndex: Int
    ): String {
        stop()
        val session = SessionManager()
        session.start()
        sessionManager = session

        val magnet = when {
            magnetOrUri.startsWith("magnet:?") -> magnetOrUri
            !infoHash.isNullOrBlank() -> "magnet:?xt=urn:btih:$infoHash"
            else -> magnetOrUri
        }

        val server = ProgressiveHttpServer(saveDir, magnet, fileIndex, session)
        server.start(NanoHTTPD.SOCKET_READ_TIMEOUT, false)
        httpServer = server

        return "http://127.0.0.1:${server.listeningPort}/stream"
    }

    fun stop() {
        try {
            httpServer?.stop()
        } catch (_: Throwable) {
        }
        httpServer = null
        try {
            sessionManager?.stop()
        } catch (_: Throwable) {
        }
        sessionManager = null
    }

    private class ProgressiveHttpServer(
        private val rootDir: File,
        private val magnetUri: String,
        private val fileIndex: Int,
        private val session: SessionManager
    ) : NanoHTTPD("127.0.0.1", 0) {

        init {
            Thread {
                try {
                    session.download(magnetUri, rootDir, TorrentFlags.SEQUENTIAL_DOWNLOAD)
                } catch (_: Throwable) {
                }
            }.apply { isDaemon = true }.start()
        }

        override fun serve(httpSession: IHTTPSession): Response {
            val videoFiles = rootDir.walkTopDown()
                .filter { it.isFile && it.length() > 0 }
                .sortedByDescending { it.length() }
                .toList()

            val chosen = videoFiles.getOrNull(fileIndex) ?: videoFiles.firstOrNull()
            if (chosen == null || !chosen.exists()) {
                return newFixedLengthResponse(
                    Response.Status.SERVICE_UNAVAILABLE,
                    MIME_PLAINTEXT,
                    "Buffering initial torrent pieces..."
                )
            }

            val fileLen = chosen.length()
            val rangeHeader = httpSession.headers["range"]
            if (rangeHeader != null && rangeHeader.startsWith("bytes=")) {
                val start = rangeHeader.removePrefix("bytes=")
                    .substringBefore("-")
                    .toLongOrNull() ?: 0L
                val fis = FileInputStream(chosen)
                fis.skip(start)
                val res = newFixedLengthResponse(
                    Response.Status.PARTIAL_CONTENT,
                    "video/mp4",
                    fis,
                    fileLen - start
                )
                res.addHeader("Accept-Ranges", "bytes")
                res.addHeader("Content-Range", "bytes $start-${fileLen - 1}/$fileLen")
                return res
            }

            val fis = FileInputStream(chosen)
            val res = newFixedLengthResponse(Response.Status.OK, "video/mp4", fis, fileLen)
            res.addHeader("Accept-Ranges", "bytes")
            return res
        }
    }
}
