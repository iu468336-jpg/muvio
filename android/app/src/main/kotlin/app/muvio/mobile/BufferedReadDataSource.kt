package app.muvio.mobile

import android.net.Uri
import android.util.Base64
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.TransferListener
import kotlin.math.min

/**
 * 64 KiB read-ahead wrapper modeled on NuvioMobile's `BufferedReadDataSource`.
 * Coalesces tiny Matroska/MP4 extractor seeks/reads into 64 KiB HTTP chunks so
 * both CDN streams and `127.0.0.1` P2P streams start rapidly without thrashing sockets.
 */
@OptIn(UnstableApi::class)
class BufferedReadDataSource(
    private val upstream: DataSource,
    bufferSizeBytes: Int = DEFAULT_BUFFER_SIZE_BYTES
) : DataSource {

    companion object {
        const val DEFAULT_BUFFER_SIZE_BYTES = 64 * 1024
    }

    private val scratch = ByteArray(bufferSizeBytes.coerceAtLeast(4 * 1024))
    private var scratchLength = 0
    private var scratchOffset = 0
    private var upstreamEnded = false

    override fun addTransferListener(transferListener: TransferListener) {
        upstream.addTransferListener(transferListener)
    }

    override fun open(dataSpec: DataSpec): Long {
        scratchLength = 0
        scratchOffset = 0
        upstreamEnded = false
        return upstream.open(dataSpec)
    }

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
        if (length == 0) return 0
        val available = scratchLength - scratchOffset
        if (available > 0) {
            val toCopy = min(length, available)
            System.arraycopy(scratch, scratchOffset, buffer, offset, toCopy)
            scratchOffset += toCopy
            return toCopy
        }
        if (upstreamEnded) return C.RESULT_END_OF_INPUT
        if (length >= scratch.size) {
            val direct = upstream.read(buffer, offset, length)
            if (direct == C.RESULT_END_OF_INPUT) upstreamEnded = true
            return direct
        }
        val filled = upstream.read(scratch, 0, scratch.size)
        if (filled == C.RESULT_END_OF_INPUT) {
            upstreamEnded = true
            return C.RESULT_END_OF_INPUT
        }
        scratchLength = filled
        scratchOffset = min(length, filled)
        System.arraycopy(scratch, 0, buffer, offset, scratchOffset)
        return scratchOffset
    }

    override fun getUri(): Uri? = upstream.uri

    override fun getResponseHeaders(): Map<String, List<String>> = upstream.responseHeaders

    override fun close() {
        scratchLength = 0
        scratchOffset = 0
        upstreamEnded = false
        upstream.close()
    }

    class Factory(
        private val upstreamFactory: DataSource.Factory,
        private val bufferSizeBytes: Int = DEFAULT_BUFFER_SIZE_BYTES
    ) : DataSource.Factory {
        override fun createDataSource(): DataSource {
            return BufferedReadDataSource(upstreamFactory.createDataSource(), bufferSizeBytes)
        }
    }
}

/**
 * Resolves `data:application/vnd.apple.mpegurl;base64,...` or `data:text/plain,...` inline
 * playlists emitted by scrapers such as VixSrc directly in memory for Media3 HLS.
 */
@OptIn(UnstableApi::class)
class InlineDataUriDataSource : DataSource {
    private var dataBytes: ByteArray? = null
    private var readPosition = 0
    private var bytesRemaining = 0
    private var currentUri: Uri? = null

    override fun addTransferListener(transferListener: TransferListener) = Unit

    override fun open(dataSpec: DataSpec): Long {
        val uri = dataSpec.uri
        currentUri = uri
        val raw = uri.toString()
        val commaIdx = raw.indexOf(',')
        if (!raw.startsWith("data:", ignoreCase = true) || commaIdx < 0) {
            throw IllegalArgumentException("Unsupported data URI")
        }
        val meta = raw.substring(5, commaIdx)
        val payload = raw.substring(commaIdx + 1)
        val bytes = if (meta.contains(";base64", ignoreCase = true)) {
            Base64.decode(payload, Base64.DEFAULT)
        } else {
            Uri.decode(payload).toByteArray(Charsets.UTF_8)
        }
        val start = dataSpec.position.toInt().coerceIn(0, bytes.size)
        val totalAvailable = bytes.size - start
        val requested = if (dataSpec.length != C.LENGTH_UNSET.toLong()) {
            min(totalAvailable.toLong(), dataSpec.length).toInt()
        } else {
            totalAvailable
        }
        dataBytes = bytes
        readPosition = start
        bytesRemaining = requested
        return requested.toLong()
    }

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
        if (length == 0) return 0
        if (bytesRemaining <= 0) return C.RESULT_END_OF_INPUT
        val bytes = dataBytes ?: return C.RESULT_END_OF_INPUT
        val toRead = min(length, bytesRemaining)
        System.arraycopy(bytes, readPosition, buffer, offset, toRead)
        readPosition += toRead
        bytesRemaining -= toRead
        return toRead
    }

    override fun getUri(): Uri? = currentUri

    override fun close() {
        dataBytes = null
        currentUri = null
        readPosition = 0
        bytesRemaining = 0
    }
}
