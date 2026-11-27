package app.muvio.mobile.nuvio

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Base64
import app.muvio.mobile.CrashLogManager
import app.muvio.mobile.nuvio.NuvioCryptoSupport.toHexString
import com.dokar.quickjs.QuickJs
import com.dokar.quickjs.binding.asyncFunction
import com.dokar.quickjs.binding.define
import com.dokar.quickjs.binding.function
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element
import org.jsoup.select.Elements
import java.io.File
import java.net.URI
import java.security.SecureRandom
import java.security.cert.X509Certificate
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager
import kotlin.random.Random

/**
 * Native QuickJS Nuvio Scraper Engine (`app.muvio.mobile/nuvio_plugins`).
 *
 * Executes real Nuvio JS scrapers (`flix-dlp/All-in-One-Nuvio`, `niakw/NiakVIO`,
 * `yoruix/nuvio-providers`, or any custom Nuvio `manifest.json` repo) directly on-device
 * in parallel to produce instant Direct HTTP / HLS / MKV streams with custom headers & subtitles!
 */
class NuvioPluginRuntimeController(private val appContext: Context) {

    companion object {
        private const val DEFAULT_TMDB_API_KEY = "439c478a771f35c05022f9feabcca01c"
        private const val SCRAPER_TIMEOUT_MS = 14_000L
        private const val MAX_PARALLEL_SCRAPERS = 4
        private const val SCRIPT_CACHE_TTL_MS = 6L * 60L * 60L * 1000L // 6 hours
        private const val MAX_FETCH_BYTES = 4 * 1024 * 1024 // 4 MiB cap per scraper fetch

        // Fast-path telemetry/ad hosts ignored immediately without network round-trip
        private val BLOCKED_TELEMETRY_HOSTS = setOf(
            "eittyweb.fr",
            "www.eittyweb.fr",
            "google-analytics.com",
            "www.google-analytics.com"
        )

        // Skip known dead/retired scrapers so slots go to fast active scrapers
        private val SKIPPED_SCRAPER_IDS = setOf(
            "movieblast",
            "guardahd",
            "dramafull",
            "kisskh"
        )

        private val followClient: OkHttpClient by lazy { buildScraperHttpClient(followRedirects = true) }
        private val manualClient: OkHttpClient by lazy { buildScraperHttpClient(followRedirects = false) }

        private fun buildScraperHttpClient(followRedirects: Boolean): OkHttpClient {
            val builder = OkHttpClient.Builder()
                .connectTimeout(9L, TimeUnit.SECONDS)
                .readTimeout(11L, TimeUnit.SECONDS)
                .writeTimeout(9L, TimeUnit.SECONDS)
                .followRedirects(followRedirects)
                .followSslRedirects(followRedirects)
                .retryOnConnectionFailure(true)

            try {
                val trustAll = arrayOf<TrustManager>(
                    object : X509TrustManager {
                        override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) = Unit
                        override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) = Unit
                        override fun getAcceptedIssuers(): Array<X509Certificate> = emptyArray()
                    }
                )
                val ssl = SSLContext.getInstance("TLS").apply {
                    init(null, trustAll, SecureRandom())
                }
                builder.sslSocketFactory(ssl.socketFactory, trustAll[0] as X509TrustManager)
                builder.hostnameVerifier { _, _ -> true }
            } catch (_: Throwable) {
            }

            return builder.build()
        }
    }

    private data class ScraperDef(
        val id: String,
        val name: String,
        val scriptUrl: String,
        val supportedTypes: Set<String>
    )

    private val mainHandler = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val scraperSemaphore = Semaphore(MAX_PARALLEL_SCRAPERS)

    private val imdbToTmdbCache = ConcurrentHashMap<String, String>()
    private val manifestCache = ConcurrentHashMap<String, Pair<Long, List<ScraperDef>>>()
    private val memoryScriptCache = ConcurrentHashMap<String, String>()
    private val cacheDir = File(appContext.cacheDir, "muvio_nuvio_scripts").apply { mkdirs() }

    fun handleMethodCall(
        method: String,
        args: Map<String, Any?>?,
        result: MethodChannel.Result
    ) {
        when (method) {
            "fetchStreams" -> {
                val manifestUrl = args?.get("manifestUrl")?.toString()?.trim() ?: ""
                val addonId = args?.get("addonId")?.toString()?.trim() ?: "nuvio.plugin"
                val addonName = args?.get("addonName")?.toString()?.trim() ?: "Nuvio"
                val mediaType = args?.get("type")?.toString()?.trim() ?: "movie"
                val mediaId = args?.get("mediaId")?.toString()?.trim() ?: ""

                scope.launch {
                    try {
                        val streams = resolveRepoStreams(
                            manifestUrl = manifestUrl,
                            addonId = addonId,
                            addonName = addonName,
                            rawType = mediaType,
                            rawMediaId = mediaId
                        )
                        mainHandler.post {
                            try {
                                result.success(streams)
                            } catch (_: Throwable) {
                            }
                        }
                    } catch (t: Throwable) {
                        CrashLogManager.recordLog(
                            appContext,
                            source = "NuvioPlugin[$addonId]",
                            trace = t.stackTraceToString()
                        )
                        mainHandler.post {
                            try {
                                result.success(emptyList<Map<String, Any?>>())
                            } catch (_: Throwable) {
                            }
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private suspend fun resolveRepoStreams(
        manifestUrl: String,
        addonId: String,
        addonName: String,
        rawType: String,
        rawMediaId: String
    ): List<Map<String, Any?>> {
        if (manifestUrl.isEmpty() || rawMediaId.isEmpty()) return emptyList()

        // Parse Stremio/TMDB videoId (`tt15239678`, `tt0944947:1:1`, `tmdb:693134`, `tmdb:1399:1:1`)
        val normalizedType = if (rawType.equals("series", ignoreCase = true) || rawType.equals("tv", ignoreCase = true)) {
            "tv"
        } else {
            "movie"
        }

        val parsedTarget = resolveTmdbTarget(rawMediaId, normalizedType) ?: return emptyList()
        val (tmdbId, season, episode) = parsedTarget

        val scrapers = loadRepoScrapers(manifestUrl)
            .filter { def ->
                val matchesType = if (normalizedType == "tv") {
                    def.supportedTypes.contains("tv") || def.supportedTypes.contains("series")
                } else {
                    def.supportedTypes.contains("movie")
                }
                matchesType && !SKIPPED_SCRAPER_IDS.contains(def.id.lowercase(Locale.US))
            }
            .take(8) // Cap per-repo scrapers to keep battery/CPU snappy on 32-bit mobile devices

        if (scrapers.isEmpty()) return emptyList()

        return coroutineScope {
            scrapers.map { scraper ->
                async(Dispatchers.IO) {
                    scraperSemaphore.withPermit {
                        runSingleScraperSafely(
                            scraper = scraper,
                            addonId = addonId,
                            addonName = addonName,
                            tmdbId = tmdbId,
                            mediaType = normalizedType,
                            season = season,
                            episode = episode
                        )
                    }
                }
            }.awaitAll().flatten()
        }
    }

    private suspend fun resolveTmdbTarget(
        rawMediaId: String,
        normalizedType: String
    ): Triple<String, Int?, Int?>? {
        val trimmed = rawMediaId.trim()
        var baseId = trimmed
        var season: Int? = null
        var episode: Int? = null

        val parts = trimmed.split(':')
        if (trimmed.startsWith("tmdb:", ignoreCase = true)) {
            baseId = parts.getOrNull(1)?.trim() ?: ""
            season = parts.getOrNull(2)?.toIntOrNull()
            episode = parts.getOrNull(3)?.toIntOrNull()
            if (baseId.isEmpty()) return null
            return Triple(baseId, season, episode)
        }

        if (parts.size >= 3) {
            baseId = parts[0].trim()
            season = parts[1].toIntOrNull()
            episode = parts[2].toIntOrNull()
        }

        if (baseId.all { it.isDigit() } && baseId.isNotEmpty()) {
            return Triple(baseId, season, episode)
        }

        if (!baseId.startsWith("tt", ignoreCase = true)) {
            return null
        }

        val cacheKey = "$normalizedType:$baseId"
        imdbToTmdbCache[cacheKey]?.let { cachedTmdb ->
            return Triple(cachedTmdb, season, episode)
        }

        val findUrl =
            "https://api.themoviedb.org/3/find/${URI.create(baseId).toASCIIString()}?api_key=$DEFAULT_TMDB_API_KEY&external_source=imdb_id"
        val body = fetchStringFast(findUrl) ?: return null
        val json = JSONObject(body)

        val primaryKey = if (normalizedType == "tv") "tv_results" else "movie_results"
        val secondaryKey = if (normalizedType == "tv") "movie_results" else "tv_results"

        val arr = json.optJSONArray(primaryKey)?.takeIf { it.length() > 0 }
            ?: json.optJSONArray(secondaryKey)?.takeIf { it.length() > 0 }
            ?: return null

        val idVal = arr.optJSONObject(0)?.optInt("id", 0) ?: 0
        if (idVal <= 0) return null

        val resolved = idVal.toString()
        imdbToTmdbCache[cacheKey] = resolved
        return Triple(resolved, season, episode)
    }

    private suspend fun loadRepoScrapers(manifestUrl: String): List<ScraperDef> {
        val now = System.currentTimeMillis()
        manifestCache[manifestUrl]?.let { (ts, list) ->
            if (now - ts < SCRIPT_CACHE_TTL_MS && list.isNotEmpty()) {
                return list
            }
        }

        val raw = fetchStringFast(manifestUrl) ?: return emptyList()
        val root = JSONObject(raw)
        val arr = root.optJSONArray("scrapers") ?: return emptyList()
        val baseUri = URI(manifestUrl)

        val parsed = ArrayList<ScraperDef>()
        for (i in 0 until arr.length()) {
            val obj = arr.optJSONObject(i) ?: continue
            if (obj.has("enabled") && !obj.optBoolean("enabled", true)) continue

            val id = obj.optString("id").trim()
            val name = obj.optString("name", id).trim()
            val filename = obj.optString("filename", obj.optString("url", "")).trim()
            if (id.isEmpty() || filename.isEmpty()) continue

            val resolvedUrl = try {
                baseUri.resolve(filename).toString()
            } catch (_: Throwable) {
                continue
            }

            val types = LinkedHashSet<String>()
            val typesArr = obj.optJSONArray("supportedTypes") ?: obj.optJSONArray("contentTypes")
            if (typesArr != null) {
                for (j in 0 until typesArr.length()) {
                    val t = typesArr.optString(j).trim().lowercase(Locale.US)
                    if (t.isNotEmpty()) types.add(t)
                }
            }
            if (types.isEmpty()) {
                types.add("movie")
                types.add("tv")
            }

            parsed.add(
                ScraperDef(
                    id = id,
                    name = name.ifEmpty { id },
                    scriptUrl = resolvedUrl,
                    supportedTypes = types
                )
            )
        }

        // Prioritize ultra-fast verified multi-audio / 4K / VF scrapers first
        val priorityOrder = listOf(
            "net77",
            "bingr",
            "purstream",
            "vidlink",
            "videasy",
            "vixsrc",
            "castle",
            "sadisflix",
            "webflix",
            "french-manga",
            "mugiwarastream",
            "neko-sama"
        )
        val sorted = parsed.sortedBy { s ->
            val idx = priorityOrder.indexOf(s.id.lowercase(Locale.US))
            if (idx >= 0) idx else 100
        }

        if (sorted.isNotEmpty()) {
            manifestCache[manifestUrl] = now to sorted
        }
        return sorted
    }

    private suspend fun loadScraperCode(scriptUrl: String): String? {
        memoryScriptCache[scriptUrl]?.let { return it }

        val hashKey = NuvioCryptoSupport.digestHex("SHA256", scriptUrl)
        val diskFile = File(cacheDir, "$hashKey.js")
        val now = System.currentTimeMillis()
        if (diskFile.exists() && now - diskFile.lastModified() < SCRIPT_CACHE_TTL_MS) {
            runCatching { diskFile.readText(Charsets.UTF_8) }.getOrNull()?.takeIf { it.isNotBlank() }?.let {
                memoryScriptCache[scriptUrl] = it
                return it
            }
        }

        val fetched = fetchStringFast(scriptUrl)
        if (!fetched.isNullOrBlank()) {
            memoryScriptCache[scriptUrl] = fetched
            runCatching { diskFile.writeText(fetched, Charsets.UTF_8) }
            return fetched
        }

        // Offline fallback to older cached script if present
        if (diskFile.exists()) {
            return runCatching { diskFile.readText(Charsets.UTF_8) }.getOrNull()
        }
        return null
    }

    private suspend fun runSingleScraperSafely(
        scraper: ScraperDef,
        addonId: String,
        addonName: String,
        tmdbId: String,
        mediaType: String,
        season: Int?,
        episode: Int?
    ): List<Map<String, Any?>> {
        val code = loadScraperCode(scraper.scriptUrl) ?: return emptyList()
        if (code.length > 1_200_000) return emptyList() // Guard 32-bit RAM against multi-MB bundles

        var runtime: QuickJs? = null
        val domBridge = JsoupDomBridge()
        var capturedJson = "[]"

        return try {
            withTimeout(SCRAPER_TIMEOUT_MS) {
                val qjs = QuickJs.create(Dispatchers.Default)
                runtime = qjs
                qjs.memoryLimit = 24L * 1024L * 1024L      // 24 MiB per QuickJS isolate (32-bit safe)
                qjs.maxStackSize = 512L * 1024L

                val callArgsJson = JSONObject().apply {
                    put("tmdbId", tmdbId)
                    put("mediaType", mediaType)
                    if (season != null) put("season", season) else put("season", JSONObject.NULL)
                    if (episode != null) put("episode", episode) else put("episode", JSONObject.NULL)
                }.toString()

                registerHostFunctions(
                    runtime = qjs,
                    scraperId = scraper.id,
                    callArgsJson = callArgsJson,
                    onCaptureResult = { res -> capturedJson = res }
                )
                registerFetchAndUrlBridges(qjs)
                registerCryptoBridge(qjs)
                domBridge.register(qjs)

                val fullEvalScript = buildString(JsBindings.staticPolyfillCode.length + code.length + 512) {
                    append("var module = { exports: {} }; var exports = module.exports;\n")
                    append(JsBindings.staticPolyfillCode)
                    append("\n;\n")
                    append(code)
                    append("\n;\n")
                    append(JsBindings.staticCallCode)
                }

                qjs.evaluate<Any?>(fullEvalScript, "${scraper.id}.js", false)
                parseScraperStreamsJson(
                    rawJson = capturedJson,
                    scraper = scraper,
                    addonId = addonId,
                    addonName = addonName
                )
            }
        } catch (_: Throwable) {
            emptyList()
        } finally {
            domBridge.clear()
            try {
                runtime?.requestInterrupt()
            } catch (_: Throwable) {
            }
            try {
                runtime?.close()
            } catch (_: Throwable) {
            }
        }
    }

    private fun parseScraperStreamsJson(
        rawJson: String,
        scraper: ScraperDef,
        addonId: String,
        addonName: String
    ): List<Map<String, Any?>> {
        val trimmed = rawJson.trim()
        if (!trimmed.startsWith("[")) return emptyList()
        val arr = runCatching { JSONArray(trimmed) }.getOrNull() ?: return emptyList()
        val out = ArrayList<Map<String, Any?>>()

        for (i in 0 until arr.length()) {
            val obj = arr.optJSONObject(i) ?: continue
            val url = obj.optString("url").trim()
            if (url.isEmpty()) continue
            val lower = url.lowercase(Locale.US)
            if (!lower.startsWith("https://") &&
                !lower.startsWith("http://") &&
                !lower.startsWith("data:")
            ) {
                continue
            }

            val rawName = obj.optString("name", scraper.name).trim()
            val rawTitle = obj.optString("title", obj.optString("description", "")).trim()
            val qualityField = obj.optString("quality", "").trim()

            val headersMap = HashMap<String, String>()
            val headersObj = obj.optJSONObject("headers")
                ?: obj.optJSONObject("behaviorHints")
                    ?.optJSONObject("proxyHeaders")
                    ?.optJSONObject("request")
            if (headersObj != null) {
                val keys = headersObj.keys()
                while (keys.hasNext()) {
                    val k = keys.next()
                    val v = headersObj.optString(k, "").trim()
                    if (k.isNotBlank() && v.isNotEmpty()) {
                        headersMap[k] = v
                    }
                }
            }

            val subsList = ArrayList<Map<String, String>>()
            val subsArr = obj.optJSONArray("subtitles")
            if (subsArr != null) {
                for (sIdx in 0 until minOf(subsArr.length(), 24)) {
                    val sObj = subsArr.optJSONObject(sIdx) ?: continue
                    val sUrl = sObj.optString("url", sObj.optString("file", "")).trim()
                    if (sUrl.startsWith("https://") || sUrl.startsWith("http://")) {
                        val lang = sObj.optString("lang", sObj.optString("language", sObj.optString("srclang", "en"))).trim()
                        val label = sObj.optString("label", sObj.optString("display", lang)).trim()
                        subsList.add(
                            mapOf(
                                "id" to "${scraper.id}_sub_$sIdx",
                                "url" to sUrl,
                                "lang" to lang.ifEmpty { "en" },
                                "label" to label.ifEmpty { "Sous-titres" }
                            )
                        )
                    }
                }
            }

            val displayTitle = buildString {
                if (rawTitle.isNotEmpty()) {
                    append(rawTitle)
                } else {
                    append(rawName.ifEmpty { scraper.name })
                }
                if (qualityField.isNotEmpty() && !contains(qualityField, ignoreCase = true)) {
                    append(" • ").append(qualityField)
                }
                if (subsList.isNotEmpty() && !contains("SUB", ignoreCase = true)) {
                    append(" • ${subsList.size} Sous-titres")
                }
            }

            out.add(
                mapOf(
                    "addonId" to addonId,
                    "addonName" to "$addonName • ${scraper.name}",
                    "name" to rawName.ifEmpty { scraper.name },
                    "title" to displayTitle,
                    "quality" to qualityField,
                    "url" to url,
                    "headers" to headersMap,
                    "subtitles" to subsList,
                    "sizeBytes" to parseSizeField(obj.opt("size"))
                )
            )
        }
        return out
    }

    private fun parseSizeField(raw: Any?): Long {
        if (raw is Number) return raw.toLong().coerceAtLeast(0L)
        val text = raw?.toString()?.trim() ?: return 0L
        val m = Regex("(\\d+(?:[.,]\\d+)?)\\s*(GB|GiB|MB|MiB)", RegexOption.IGNORE_CASE).find(text)
            ?: return 0L
        val num = m.groupValues[1].replace(',', '.').toDoubleOrNull() ?: return 0L
        val unit = m.groupValues[2].uppercase(Locale.US)
        val mult = if (unit.startsWith("G")) 1024.0 * 1024.0 * 1024.0 else 1024.0 * 1024.0
        return (num * mult).toLong()
    }

    private fun registerHostFunctions(
        runtime: QuickJs,
        scraperId: String,
        callArgsJson: String,
        onCaptureResult: (String) -> Unit
    ) {
        runtime.asyncFunction("__plugin_sleep") { args ->
            val ms = ((args.getOrNull(0) as? Number)?.toLong() ?: 0L).coerceIn(0L, 8_000L)
            if (ms > 0L) delay(ms)
            null
        }
        runtime.define("console") {
            function("log") { null }
            function("info") { null }
            function("debug") { null }
            function("warn") { null }
            function("error") { null }
        }
        runtime.function("__get_scraper_id") { scraperId }
        runtime.function("__get_scraper_settings") { "{}" }
        runtime.function("__get_tmdb_api_key") { DEFAULT_TMDB_API_KEY }
        runtime.function("__get_call_args") { callArgsJson }
        runtime.function("__capture_result") { args ->
            onCaptureResult(args.getOrNull(0)?.toString() ?: "[]")
            null
        }
    }

    private fun registerFetchAndUrlBridges(runtime: QuickJs) {
        runtime.function("__parse_url") { args ->
            val raw = args.getOrNull(0)?.toString() ?: ""
            try {
                val u = URI(raw)
                val scheme = u.scheme?.lowercase(Locale.US) ?: ""
                val defaultPort = when (scheme) {
                    "https" -> 443
                    "http" -> 80
                    else -> -1
                }
                val hostOnly = u.host ?: ""
                val explicitPort = if (u.port > 0 && u.port != defaultPort) u.port.toString() else ""
                val fullHost = if (explicitPort.isNotEmpty()) "$hostOnly:$explicitPort" else hostOnly
                JSONObject().apply {
                    put("protocol", if (scheme.isNotEmpty()) "$scheme:" else "")
                    put("host", fullHost)
                    put("hostname", hostOnly)
                    put("port", explicitPort)
                    put("pathname", u.rawPath?.takeIf { it.isNotEmpty() } ?: "/")
                    put("search", u.rawQuery?.let { "?$it" } ?: "")
                    put("hash", u.rawFragment?.let { "#$it" } ?: "")
                }.toString()
            } catch (_: Throwable) {
                JSONObject().apply {
                    put("protocol", "")
                    put("host", "")
                    put("hostname", "")
                    put("port", "")
                    put("pathname", "/")
                    put("search", "")
                    put("hash", "")
                }.toString()
            }
        }

        runtime.asyncFunction("__native_fetch") { args ->
            val url = args.getOrNull(0)?.toString()?.trim() ?: ""
            val method = (args.getOrNull(1)?.toString() ?: "GET").uppercase(Locale.US)
            val headersJson = args.getOrNull(2)?.toString() ?: "{}"
            val bodyKind = args.getOrNull(3)?.toString() ?: "none"
            val bodyVal = args.getOrNull(4)?.toString() ?: ""
            val followRedirects = args.getOrNull(5) as? Boolean ?: true

            withContext(Dispatchers.IO) {
                performNativeFetch(url, method, headersJson, bodyKind, bodyVal, followRedirects)
            }
        }
    }

    private fun performNativeFetch(
        url: String,
        method: String,
        headersJson: String,
        bodyKind: String,
        bodyVal: String,
        followRedirects: Boolean
    ): String {
        try {
            val parsedUri = URI(url)
            val host = parsedUri.host?.lowercase(Locale.US) ?: ""
            if (BLOCKED_TELEMETRY_HOSTS.contains(host)) {
                return JSONObject().apply {
                    put("ok", true)
                    put("status", 204)
                    put("statusText", "No Content")
                    put("url", url)
                    put("body", "{}")
                    put("bodyBase64", Base64.encodeToString("{}".toByteArray(), Base64.NO_WRAP))
                    put("headers", JSONObject())
                }.toString()
            }

            val reqHeaders = HashMap<String, String>()
            runCatching {
                val obj = JSONObject(headersJson)
                val keys = obj.keys()
                while (keys.hasNext()) {
                    val k = keys.next()
                    reqHeaders[k] = obj.optString(k, "")
                }
            }
            if (reqHeaders.keys.none { it.equals("User-Agent", ignoreCase = true) }) {
                reqHeaders["User-Agent"] =
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
            }

            val contentTypeHeader = reqHeaders.entries
                .firstOrNull { it.key.equals("Content-Type", ignoreCase = true) }
                ?.value
                ?.toMediaTypeOrNull()

            val requestBody: RequestBody? = when {
                method == "GET" || method == "HEAD" -> null
                bodyKind == "base64" -> Base64.decode(bodyVal, Base64.DEFAULT).toRequestBody(contentTypeHeader)
                bodyKind == "text" -> bodyVal.toRequestBody(contentTypeHeader)
                method == "POST" || method == "PUT" || method == "PATCH" -> ByteArray(0).toRequestBody(contentTypeHeader)
                else -> null
            }

            val reqBuilder = Request.Builder().url(url).method(method, requestBody)
            for ((k, v) in reqHeaders) {
                if (k.isNotBlank()) {
                    reqBuilder.header(k, v)
                }
            }

            val client = if (followRedirects) followClient else manualClient
            client.newCall(reqBuilder.build()).execute().use { resp ->
                val rawBytes = resp.body?.bytes()?.let { bytes ->
                    if (bytes.size > MAX_FETCH_BYTES) bytes.copyOf(MAX_FETCH_BYTES) else bytes
                } ?: ByteArray(0)
                val textBody = rawBytes.toString(Charsets.UTF_8)

                val respHeadersJson = JSONObject()
                for (name in resp.headers.names()) {
                    val lowerName = name.lowercase(Locale.US)
                    val values = resp.headers.values(name)
                    val joined = if (lowerName == "set-cookie") {
                        values.joinToString("; ")
                    } else {
                        values.joinToString(", ")
                    }
                    respHeadersJson.put(lowerName, joined.take(8192))
                }

                return JSONObject().apply {
                    put("ok", resp.code in 200..299)
                    put("status", resp.code)
                    put("statusText", resp.message)
                    put("url", resp.request.url.toString())
                    put("body", textBody)
                    put("bodyBase64", Base64.encodeToString(rawBytes, Base64.NO_WRAP))
                    put("headers", respHeadersJson)
                }.toString()
            }
        } catch (t: Throwable) {
            return JSONObject().apply {
                put("ok", false)
                put("status", 0)
                put("statusText", t.message ?: "Fetch failed")
                put("url", url)
                put("body", "")
                put("bodyBase64", "")
                put("headers", JSONObject())
            }.toString()
        }
    }

    private fun registerCryptoBridge(runtime: QuickJs) {
        runtime.function("__crypto_get_random_values_hex") { args ->
            val len = (args.getOrNull(0) as? Number)?.toInt() ?: 0
            NuvioCryptoSupport.getRandomValues(len).toHexString()
        }
        runtime.function("__crypto_digest_hex_raw") { args ->
            val algo = args.getOrNull(0)?.toString() ?: "SHA256"
            val data = NuvioCryptoSupport.hexToByteArray(args.getOrNull(1)?.toString() ?: "")
            NuvioCryptoSupport.digest(algo, data).toHexString()
        }
        runtime.function("__crypto_hmac_hex_raw") { args ->
            val algo = args.getOrNull(0)?.toString() ?: "SHA256"
            val key = NuvioCryptoSupport.hexToByteArray(args.getOrNull(1)?.toString() ?: "")
            val data = NuvioCryptoSupport.hexToByteArray(args.getOrNull(2)?.toString() ?: "")
            NuvioCryptoSupport.hmac(algo, key, data).toHexString()
        }
        runtime.function("__crypto_pbkdf2_hex") { args ->
            val pwd = NuvioCryptoSupport.hexToByteArray(args.getOrNull(0)?.toString() ?: "")
            val salt = NuvioCryptoSupport.hexToByteArray(args.getOrNull(1)?.toString() ?: "")
            val iter = (args.getOrNull(2) as? Number)?.toInt() ?: 1000
            val bits = (args.getOrNull(3) as? Number)?.toInt() ?: 256
            val algo = args.getOrNull(4)?.toString() ?: "SHA256"
            NuvioCryptoSupport.pbkdf2(pwd, salt, iter, bits, algo).toHexString()
        }
        runtime.function("__crypto_aes_encrypt_hex") { args ->
            val mode = args.getOrNull(0)?.toString() ?: "AES-CBC"
            val key = NuvioCryptoSupport.hexToByteArray(args.getOrNull(1)?.toString() ?: "")
            val iv = NuvioCryptoSupport.hexToByteArray(args.getOrNull(2)?.toString() ?: "")
            val data = NuvioCryptoSupport.hexToByteArray(args.getOrNull(3)?.toString() ?: "")
            NuvioCryptoSupport.aesEncrypt(mode, key, iv, data).toHexString()
        }
        runtime.function("__crypto_aes_decrypt_hex") { args ->
            val mode = args.getOrNull(0)?.toString() ?: "AES-CBC"
            val key = NuvioCryptoSupport.hexToByteArray(args.getOrNull(1)?.toString() ?: "")
            val iv = NuvioCryptoSupport.hexToByteArray(args.getOrNull(2)?.toString() ?: "")
            val data = NuvioCryptoSupport.hexToByteArray(args.getOrNull(3)?.toString() ?: "")
            NuvioCryptoSupport.aesDecrypt(mode, key, iv, data).toHexString()
        }
        runtime.function("__crypto_sign_hex") { args ->
            val algo = args.getOrNull(0)?.toString() ?: ""
            val priv = NuvioCryptoSupport.hexToByteArray(args.getOrNull(1)?.toString() ?: "")
            val data = NuvioCryptoSupport.hexToByteArray(args.getOrNull(2)?.toString() ?: "")
            NuvioCryptoSupport.sign(algo, priv, data).toHexString()
        }
        runtime.function("__crypto_verify_hex") { args ->
            val algo = args.getOrNull(0)?.toString() ?: ""
            val pub = NuvioCryptoSupport.hexToByteArray(args.getOrNull(1)?.toString() ?: "")
            val sig = NuvioCryptoSupport.hexToByteArray(args.getOrNull(2)?.toString() ?: "")
            val data = NuvioCryptoSupport.hexToByteArray(args.getOrNull(3)?.toString() ?: "")
            NuvioCryptoSupport.verify(algo, pub, sig, data)
        }
        runtime.function("__crypto_digest_hex") { args ->
            val algo = args.getOrNull(0)?.toString() ?: "SHA256"
            val data = args.getOrNull(1)?.toString() ?: ""
            runCatching { NuvioCryptoSupport.digestHex(algo, data) }.getOrDefault("")
        }
        runtime.function("__crypto_hmac_hex") { args ->
            val algo = args.getOrNull(0)?.toString() ?: "SHA256"
            val key = args.getOrNull(1)?.toString() ?: ""
            val data = args.getOrNull(2)?.toString() ?: ""
            runCatching { NuvioCryptoSupport.hmacHex(algo, key, data) }.getOrDefault("")
        }
        runtime.function("__crypto_base64_encode") { args ->
            runCatching { NuvioCryptoSupport.base64Encode(args.getOrNull(0)?.toString() ?: "") }.getOrDefault("")
        }
        runtime.function("__crypto_base64_decode") { args ->
            runCatching { NuvioCryptoSupport.base64Decode(args.getOrNull(0)?.toString() ?: "") }.getOrDefault("")
        }
        runtime.function("__crypto_utf8_to_hex") { args ->
            runCatching { NuvioCryptoSupport.utf8ToHex(args.getOrNull(0)?.toString() ?: "") }.getOrDefault("")
        }
        runtime.function("__crypto_hex_to_utf8") { args ->
            runCatching { NuvioCryptoSupport.hexToUtf8(args.getOrNull(0)?.toString() ?: "") }.getOrDefault("")
        }
    }

    private suspend fun fetchStringFast(url: String): String? = withContext(Dispatchers.IO) {
        try {
            val req = Request.Builder()
                .url(url)
                .header(
                    "User-Agent",
                    "Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36"
                )
                .get()
                .build()
            followClient.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) return@withContext null
                resp.body?.string()
            }
        } catch (_: Throwable) {
            null
        }
    }

    fun shutdown() {
        scope.cancel()
    }

    private class JsoupDomBridge {
        private val documentCache = HashMap<String, Document>()
        private val elementCache = HashMap<String, Element>()
        private val loadedDocIds = ArrayList<String>()
        private var idCounter = 0
        private val containsRegex = Regex(""":contains\([\"']([^\"']+)[\"']\)""")

        fun register(runtime: QuickJs) {
            runtime.function("__cheerio_load") { args ->
                val html = args.getOrNull(0)?.toString() ?: ""
                val docId = "doc_${idCounter++}_${Random.nextInt(0, Int.MAX_VALUE)}"
                documentCache[docId] = Jsoup.parse(html)
                loadedDocIds.add(docId)
                while (loadedDocIds.size > 8) {
                    val evicted = loadedDocIds.removeAt(0)
                    documentCache.remove(evicted)
                    val stale = elementCache.keys.filter { it.startsWith("$evicted:") }
                    stale.forEach { elementCache.remove(it) }
                }
                docId
            }

            runtime.function("__cheerio_select") { args ->
                val docId = args.getOrNull(0)?.toString() ?: ""
                var selector = args.getOrNull(1)?.toString() ?: ""
                val doc = documentCache[docId] ?: return@function "[]"
                try {
                    selector = selector.replace(containsRegex, ":contains($1)")
                    val elements = if (selector.isEmpty()) Elements() else doc.select(selector)
                    val arr = JSONArray()
                    elements.forEachIndexed { idx, el ->
                        val id = "$docId:$idx:${el.hashCode()}"
                        elementCache[id] = el
                        arr.put(id)
                    }
                    arr.toString()
                } catch (_: Throwable) {
                    "[]"
                }
            }

            runtime.function("__cheerio_find") { args ->
                val docId = args.getOrNull(0)?.toString() ?: ""
                val elementId = args.getOrNull(1)?.toString() ?: ""
                var selector = args.getOrNull(2)?.toString() ?: ""
                val el = elementCache[elementId] ?: return@function "[]"
                try {
                    selector = selector.replace(containsRegex, ":contains($1)")
                    val elements = el.select(selector)
                    val arr = JSONArray()
                    elements.forEachIndexed { idx, child ->
                        val id = "$docId:find:$idx:${child.hashCode()}"
                        elementCache[id] = child
                        arr.put(id)
                    }
                    arr.toString()
                } catch (_: Throwable) {
                    "[]"
                }
            }

            runtime.function("__cheerio_text") { args ->
                val ids = args.getOrNull(1)?.toString() ?: ""
                ids.split(",")
                    .filter { it.isNotEmpty() }
                    .mapNotNull { elementCache[it]?.text() }
                    .joinToString(" ")
            }

            runtime.function("__cheerio_html") { args ->
                val docId = args.getOrNull(0)?.toString() ?: ""
                val elId = args.getOrNull(1)?.toString() ?: ""
                if (elId.isEmpty()) {
                    documentCache[docId]?.html() ?: ""
                } else {
                    elementCache[elId]?.html() ?: ""
                }
            }

            runtime.function("__cheerio_inner_html") { args ->
                val elId = args.getOrNull(1)?.toString() ?: ""
                elementCache[elId]?.html() ?: ""
            }

            runtime.function("__cheerio_attr") { args ->
                val elId = args.getOrNull(1)?.toString() ?: ""
                val attrName = args.getOrNull(2)?.toString() ?: ""
                val v = elementCache[elId]?.attr(attrName)
                if (v.isNullOrEmpty()) "__UNDEFINED__" else v
            }

            runtime.function("__cheerio_next") { args ->
                val docId = args.getOrNull(0)?.toString() ?: ""
                val elId = args.getOrNull(1)?.toString() ?: ""
                val next = elementCache[elId]?.nextElementSibling() ?: return@function "__NONE__"
                val nextId = "$docId:next:${next.hashCode()}"
                elementCache[nextId] = next
                nextId
            }

            runtime.function("__cheerio_prev") { args ->
                val docId = args.getOrNull(0)?.toString() ?: ""
                val elId = args.getOrNull(1)?.toString() ?: ""
                val prev = elementCache[elId]?.previousElementSibling() ?: return@function "__NONE__"
                val prevId = "$docId:prev:${prev.hashCode()}"
                elementCache[prevId] = prev
                prevId
            }
        }

        fun clear() {
            documentCache.clear()
            elementCache.clear()
            loadedDocIds.clear()
        }
    }
}
