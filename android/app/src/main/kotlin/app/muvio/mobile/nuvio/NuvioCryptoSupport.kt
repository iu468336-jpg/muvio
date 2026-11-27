package app.muvio.mobile.nuvio

import android.util.Base64
import java.security.KeyFactory
import java.security.MessageDigest
import java.security.SecureRandom
import java.security.Signature
import java.security.spec.PKCS8EncodedKeySpec
import java.security.spec.X509EncodedKeySpec
import java.util.Locale
import javax.crypto.Cipher
import javax.crypto.Mac
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

internal object NuvioCryptoSupport {
    private val secureRandom = SecureRandom()

    fun getRandomValues(length: Int): ByteArray {
        val safeLen = length.coerceIn(0, 65536)
        val bytes = ByteArray(safeLen)
        secureRandom.nextBytes(bytes)
        return bytes
    }

    fun digest(algorithm: String, data: ByteArray): ByteArray {
        return MessageDigest.getInstance(normalizeDigestAlgorithm(algorithm)).digest(data)
    }

    fun pbkdf2(
        password: ByteArray,
        salt: ByteArray,
        iterations: Int,
        keySizeBits: Int,
        algorithm: String
    ): ByteArray {
        require(iterations > 0) { "PBKDF2 iterations must be positive" }
        require(keySizeBits > 0 && keySizeBits % 8 == 0) { "Invalid PBKDF2 keySizeBits" }

        val prfAlgo = normalizeHmacAlgorithm(algorithm)
        val mac = Mac.getInstance(prfAlgo)
        mac.init(SecretKeySpec(password, prfAlgo))

        val hLen = mac.macLength
        val dkLen = keySizeBits / 8
        val dk = ByteArray(dkLen)

        val blocks = (dkLen + hLen - 1) / hLen
        val u = ByteArray(hLen)
        val t = ByteArray(hLen)
        val blockIndexBytes = ByteArray(4)

        for (i in 1..blocks) {
            mac.reset()
            mac.update(salt)
            blockIndexBytes[0] = (i ushr 24).toByte()
            blockIndexBytes[1] = (i ushr 16).toByte()
            blockIndexBytes[2] = (i ushr 8).toByte()
            blockIndexBytes[3] = i.toByte()
            mac.update(blockIndexBytes)

            val u1 = mac.doFinal()
            u1.copyInto(t)
            u1.copyInto(u)

            for (j in 2..iterations) {
                mac.reset()
                val uj = mac.doFinal(u)
                uj.copyInto(u)
                for (k in 0 until hLen) {
                    t[k] = (t[k].toInt() xor uj[k].toInt()).toByte()
                }
            }

            val offset = (i - 1) * hLen
            val len = minOf(hLen, dkLen - offset)
            t.copyInto(dk, destinationOffset = offset, startIndex = 0, endIndex = len)
        }
        return dk
    }

    fun aesEncrypt(mode: String, key: ByteArray, iv: ByteArray, data: ByteArray): ByteArray {
        val normalizedMode = normalizeAesTransformation(mode)
        requireValidAesKey(key)
        val cipher = Cipher.getInstance(normalizedMode)
        val keySpec = SecretKeySpec(key, "AES")
        when {
            normalizedMode.contains("ECB") -> cipher.init(Cipher.ENCRYPT_MODE, keySpec)
            normalizedMode.contains("GCM") -> cipher.init(Cipher.ENCRYPT_MODE, keySpec, GCMParameterSpec(128, iv))
            else -> cipher.init(Cipher.ENCRYPT_MODE, keySpec, IvParameterSpec(iv))
        }
        return cipher.doFinal(data)
    }

    fun aesDecrypt(mode: String, key: ByteArray, iv: ByteArray, data: ByteArray): ByteArray {
        val normalizedMode = normalizeAesTransformation(mode)
        requireValidAesKey(key)
        val cipher = Cipher.getInstance(normalizedMode)
        val keySpec = SecretKeySpec(key, "AES")
        when {
            normalizedMode.contains("ECB") -> cipher.init(Cipher.DECRYPT_MODE, keySpec)
            normalizedMode.contains("GCM") -> cipher.init(Cipher.DECRYPT_MODE, keySpec, GCMParameterSpec(128, iv))
            else -> cipher.init(Cipher.DECRYPT_MODE, keySpec, IvParameterSpec(iv))
        }
        return cipher.doFinal(data)
    }

    fun sign(algorithm: String, privateKey: ByteArray, data: ByteArray): ByteArray {
        val (keyAlgo, sigAlgo) = when (algorithm.uppercase(Locale.US)) {
            "RSASSA-PKCS1-V1_5-SHA256", "RSASSA-PKCS1-V1_5" -> "RSA" to "SHA256withRSA"
            "ECDSA-SHA256", "ECDSA" -> "EC" to "SHA256withECDSA"
            else -> "RSA" to "SHA256withRSA"
        }
        val factory = KeyFactory.getInstance(keyAlgo)
        val privKey = factory.generatePrivate(PKCS8EncodedKeySpec(privateKey))
        val sig = Signature.getInstance(sigAlgo)
        sig.initSign(privKey)
        sig.update(data)
        return sig.sign()
    }

    fun verify(algorithm: String, publicKey: ByteArray, signature: ByteArray, data: ByteArray): Boolean {
        val (keyAlgo, sigAlgo) = when (algorithm.uppercase(Locale.US)) {
            "RSASSA-PKCS1-V1_5-SHA256", "RSASSA-PKCS1-V1_5" -> "RSA" to "SHA256withRSA"
            "ECDSA-SHA256", "ECDSA" -> "EC" to "SHA256withECDSA"
            else -> "RSA" to "SHA256withRSA"
        }
        val factory = KeyFactory.getInstance(keyAlgo)
        val pubKey = factory.generatePublic(X509EncodedKeySpec(publicKey))
        val sig = Signature.getInstance(sigAlgo)
        sig.initVerify(pubKey)
        sig.update(data)
        return sig.verify(signature)
    }

    fun hmac(algorithm: String, key: ByteArray, data: ByteArray): ByteArray {
        val normalized = normalizeHmacAlgorithm(algorithm)
        val mac = Mac.getInstance(normalized)
        mac.init(SecretKeySpec(key, normalized))
        return mac.doFinal(data)
    }

    fun digestHex(algorithm: String, data: String): String =
        digest(algorithm, data.toByteArray(Charsets.UTF_8)).toHexString()

    fun hmacHex(algorithm: String, key: String, data: String): String =
        hmac(algorithm, key.toByteArray(Charsets.UTF_8), data.toByteArray(Charsets.UTF_8)).toHexString()

    fun base64Encode(data: String): String =
        Base64.encodeToString(data.toByteArray(Charsets.UTF_8), Base64.NO_WRAP)

    fun base64Decode(data: String): String {
        var normalized = data.trim().replace("\n", "").replace("\r", "").replace(" ", "")
        normalized = normalized.replace("-", "+").replace("_", "/")
        val padNeeded = (4 - (normalized.length % 4)) % 4
        if (padNeeded > 0) {
            normalized += "=".repeat(padNeeded)
        }
        return Base64.decode(normalized, Base64.DEFAULT).toString(Charsets.UTF_8)
    }

    fun utf8ToHex(value: String): String =
        value.toByteArray(Charsets.UTF_8).toHexString()

    fun hexToByteArray(hex: String): ByteArray {
        val normalized = hex.trim().lowercase(Locale.US).replace(" ", "").removePrefix("0x")
        if (normalized.isEmpty()) return ByteArray(0)
        val evenHex = if (normalized.length % 2 == 0) normalized else "0$normalized"
        val out = ByteArray(evenHex.length / 2)
        for (idx in out.indices) {
            out[idx] = evenHex.substring(idx * 2, idx * 2 + 2).toInt(16).toByte()
        }
        return out
    }

    fun hexToUtf8(hex: String): String = hexToByteArray(hex).toString(Charsets.UTF_8)

    fun ByteArray.toHexString(): String {
        val chars = "0123456789abcdef"
        val sb = StringBuilder(size * 2)
        for (b in this) {
            val v = b.toInt() and 0xFF
            sb.append(chars[v ushr 4]).append(chars[v and 0x0F])
        }
        return sb.toString()
    }

    private fun normalizeDigestAlgorithm(algorithm: String): String {
        return when (algorithm.normalizedToken()) {
            "MD5" -> "MD5"
            "SHA1" -> "SHA-1"
            "SHA256" -> "SHA-256"
            "SHA384" -> "SHA-384"
            "SHA512" -> "SHA-512"
            else -> "SHA-256"
        }
    }

    private fun normalizeHmacAlgorithm(algorithm: String): String {
        return when (algorithm.normalizedToken().removePrefix("HMAC")) {
            "MD5" -> "HmacMD5"
            "SHA1" -> "HmacSHA1"
            "SHA256" -> "HmacSHA256"
            "SHA384" -> "HmacSHA384"
            "SHA512" -> "HmacSHA512"
            else -> "HmacSHA256"
        }
    }

    private fun normalizeAesTransformation(mode: String): String {
        val normalized = mode.normalizedToken()
        val padding = if (normalized.contains("NOPADDING")) "NoPadding" else "PKCS5Padding"
        return when {
            normalized.contains("GCM") -> "AES/GCM/NoPadding"
            normalized.contains("ECB") -> "AES/ECB/$padding"
            else -> "AES/CBC/$padding"
        }
    }

    private fun requireValidAesKey(key: ByteArray) {
        require(key.size == 16 || key.size == 24 || key.size == 32) {
            "AES key must be 16, 24, or 32 bytes"
        }
    }

    private fun String.normalizedToken(): String =
        uppercase(Locale.US)
            .replace("-", "")
            .replace("_", "")
            .replace("/", "")
            .replace(" ", "")
}
