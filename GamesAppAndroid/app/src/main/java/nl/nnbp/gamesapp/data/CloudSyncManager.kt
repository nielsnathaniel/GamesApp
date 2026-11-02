package nl.nnbp.gamesapp.data

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.*
import nl.nnbp.gamesapp.data.model.PlayedGame
import nl.nnbp.gamesapp.data.model.Score
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*

class CloudSyncManager private constructor(private val context: Context) {

    companion object {
        const val DEFAULT_DATABASE_URL = "https://gamesapp-sync-default-rtdb.europe-west1.firebasedatabase.app"

        private const val PREFS_NAME = "cloud_sync_prefs_v1"
        private const val KEY_SYNC_CODE = "sync_vault_code"
        private const val KEY_DATABASE_URL = "sync_database_url"
        private const val KEY_AUTO_SYNC = "sync_auto_enabled"
        private const val KEY_LAST_TIMESTAMP = "sync_last_timestamp"
        private const val KEY_LAST_SUMMARY = "sync_last_summary"
        private const val KEY_DELETED_IDS = "sync_deleted_game_ids"

        @Volatile
        private var INSTANCE: CloudSyncManager? = null

        fun getInstance(context: Context): CloudSyncManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: CloudSyncManager(context.applicationContext).also { INSTANCE = it }
            }
        }
    }

    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var autoSyncJob: Job? = null

    private val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }

    // State Flows voor UI reactiviteit
    private val _syncCode = MutableStateFlow(prefs.getString(KEY_SYNC_CODE, "") ?: "")
    val syncCode: StateFlow<String> = _syncCode.asStateFlow()

    private val _databaseUrl = MutableStateFlow(prefs.getString(KEY_DATABASE_URL, DEFAULT_DATABASE_URL) ?: DEFAULT_DATABASE_URL)
    val databaseUrl: StateFlow<String> = _databaseUrl.asStateFlow()

    private val _isAutoSyncEnabled = MutableStateFlow(prefs.getBoolean(KEY_AUTO_SYNC, true))
    val isAutoSyncEnabled: StateFlow<Boolean> = _isAutoSyncEnabled.asStateFlow()

    private val _isSyncing = MutableStateFlow(false)
    val isSyncing: StateFlow<Boolean> = _isSyncing.asStateFlow()

    private val _lastSyncDate = MutableStateFlow<Long?>(
        if (prefs.contains(KEY_LAST_TIMESTAMP)) prefs.getLong(KEY_LAST_TIMESTAMP, 0L) else null
    )
    val lastSyncDate: StateFlow<Long?> = _lastSyncDate.asStateFlow()

    private val _lastSyncSummary = MutableStateFlow(prefs.getString(KEY_LAST_SUMMARY, "") ?: "")
    val lastSyncSummary: StateFlow<String> = _lastSyncSummary.asStateFlow()

    private val _lastErrorMessage = MutableStateFlow<String?>(null)
    val lastErrorMessage: StateFlow<String?> = _lastErrorMessage.asStateFlow()

    val isConnected: Boolean
        get() = _syncCode.value.trim().isNotEmpty()

    val cleanSyncCode: String
        get() = _syncCode.value.trim().uppercase(Locale.getDefault())

    val cleanDatabaseUrl: String
        get() {
            var url = _databaseUrl.value.trim()
            if (url.isEmpty()) url = DEFAULT_DATABASE_URL
            while (url.endsWith("/")) {
                url = url.substring(0, url.length - 1)
            }
            if (!url.startsWith("http://", ignoreCase = true) && !url.startsWith("https://", ignoreCase = true)) {
                url = "https://$url"
            }
            return url
        }

    init {
        // Initiële automatische synchronisatie bij starten
        if (isConnected && _isAutoSyncEnabled.value) {
            scope.launch {
                delay(2000)
                syncNow()
            }
        }
    }

    // MARK: - Configuratie

    fun updateDatabaseUrl(newUrl: String) {
        val trimmed = newUrl.trim()
        val finalUrl = if (trimmed.isEmpty()) DEFAULT_DATABASE_URL else trimmed
        _databaseUrl.value = finalUrl
        prefs.edit().putString(KEY_DATABASE_URL, finalUrl).apply()
    }

    fun resetDatabaseUrlToDefault() {
        _databaseUrl.value = DEFAULT_DATABASE_URL
        prefs.edit().putString(KEY_DATABASE_URL, DEFAULT_DATABASE_URL).apply()
    }

    fun setAutoSyncEnabled(enabled: Boolean) {
        _isAutoSyncEnabled.value = enabled
        prefs.edit().putBoolean(KEY_AUTO_SYNC, enabled).apply()
    }

    // MARK: - Koppelcode Beheer

    fun generateNewCode(onComplete: (Result<String>) -> Unit) {
        val alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        val randomChars = (1..4).map { alphabet.random() }.joinToString("")
        val newCode = "SPEL-$randomChars"

        _syncCode.value = newCode
        prefs.edit().putString(KEY_SYNC_CODE, newCode).apply()

        // Upload huidige lokale gegevens naar de kluis
        scope.launch {
            val result = performUpload(newCode)
            withContext(Dispatchers.Main) {
                if (result.isSuccess) {
                    onComplete(Result.success(newCode))
                } else {
                    onComplete(Result.failure(result.exceptionOrNull() ?: Exception("Upload mislukt")))
                }
            }
        }
    }

    fun connectWithCode(code: String, onComplete: (Result<String>) -> Unit) {
        val clean = code.trim().uppercase(Locale.getDefault())
        if (clean.isEmpty()) {
            onComplete(Result.failure(Exception("Voer een geldige koppelcode in.")))
            return
        }

        _syncCode.value = clean
        prefs.edit().putString(KEY_SYNC_CODE, clean).apply()

        scope.launch {
            val result = executeFullSync(clean)
            withContext(Dispatchers.Main) {
                onComplete(result)
            }
        }
    }

    fun disconnect() {
        _syncCode.value = ""
        prefs.edit().remove(KEY_SYNC_CODE).apply()
        _lastSyncSummary.value = "Niet gekoppeld"
        prefs.edit().putString(KEY_LAST_SUMMARY, "Niet gekoppeld").apply()
    }

    // MARK: - Automatische Debounced Sync

    fun recordDeletedGameId(gameId: String) {
        val existing = prefs.getStringSet(KEY_DELETED_IDS, emptySet())?.toMutableSet() ?: mutableSetOf()
        existing.add(gameId)
        prefs.edit().putStringSet(KEY_DELETED_IDS, existing).apply()
        scheduleAutoSync()
    }

    fun scheduleAutoSync() {
        if (!isConnected || !_isAutoSyncEnabled.value) return

        autoSyncJob?.cancel()
        autoSyncJob = scope.launch {
            delay(1500)
            syncNow()
        }
    }

    fun syncNowIfNeeded() {
        if (isConnected && _isAutoSyncEnabled.value) {
            syncNow()
        }
    }

    fun syncNow(onComplete: ((Result<String>) -> Unit)? = null) {
        if (!isConnected) {
            onComplete?.invoke(Result.failure(Exception("Geen koppelcode ingesteld.")))
            return
        }

        val code = cleanSyncCode
        scope.launch {
            val result = executeFullSync(code)
            withContext(Dispatchers.Main) {
                onComplete?.invoke(result)
            }
        }
    }

    // MARK: - Volledige Tweewegs-synchronisatie

    private suspend fun executeFullSync(code: String): Result<String> {
        if (_isSyncing.value) {
            return Result.success("Synchronisatie al bezig...")
        }

        _isSyncing.value = true
        _lastErrorMessage.value = null

        return try {
            val targetUrl = "$cleanDatabaseUrl/vaults/$code.json"
            val remoteJson = httpGet(targetUrl)

            if (remoteJson == null || remoteJson == "null" || remoteJson.trim().isEmpty()) {
                // Online kluis bestaat nog niet: upload huidige lokale data
                performUpload(code)
            } else {
                // Parseer remote JSON en voeg samen
                val parsed = DataBackupManager.parseBackupJson(remoteJson)
                mergeWithLocalData(parsed, remoteJson)

                // Upload het samengevoegde resultaat terug
                performUpload(code)
            }
        } catch (e: Exception) {
            _lastErrorMessage.value = e.localizedMessage
            Result.failure(e)
        } finally {
            _isSyncing.value = false
        }
    }

    private fun mergeWithLocalData(cloudData: BackupParsedData, rawCloudJson: String) {
        val scoreManager = ScoreManager.getInstance(context)

        // 1. Tombstones (verwijderde game IDs)
        val localDeletedIds = prefs.getStringSet(KEY_DELETED_IDS, emptySet())?.toMutableSet() ?: mutableSetOf()
        try {
            val root = Json.parseToJsonElement(rawCloudJson).jsonObject
            root["deletedGameIds"]?.jsonArray?.forEach {
                it.jsonPrimitive.contentOrNull?.let { id -> localDeletedIds.add(id) }
            }
            prefs.edit().putStringSet(KEY_DELETED_IDS, localDeletedIds).apply()
        } catch (_: Exception) {}

        // 2. Spelersnamen samenvoegen
        val currentPlayers = scoreManager.fetchPlayerNames().toMutableSet()
        cloudData.playerNames.forEach { name ->
            val trimmed = name.trim()
            if (trimmed.isNotEmpty()) currentPlayers.add(trimmed)
        }

        // 3. Spellen samenvoegen
        val localGames = scoreManager.playedGames.value.filter { !localDeletedIds.contains(it.id) }
        val gamesMap = mutableMapOf<String, PlayedGame>()
        localGames.forEach { gamesMap[it.id] = it }

        cloudData.playedGames.forEach { cg ->
            if (!localDeletedIds.contains(cg.id) && !gamesMap.containsKey(cg.id)) {
                gamesMap[cg.id] = cg
            }
        }

        val mergedGames = gamesMap.values.sortedByDescending { it.timestamp }

        // 4. Scores samenvoegen
        val localScores = scoreManager.scores.value.filter { !localDeletedIds.contains(it.id) }
        val scoresMap = mutableMapOf<String, Score>()
        localScores.forEach { scoresMap[it.id] = it }

        cloudData.scores.forEach { cs ->
            if (!localDeletedIds.contains(cs.id) && !scoresMap.containsKey(cs.id)) {
                scoresMap[cs.id] = cs
            }
        }

        val mergedScores = scoresMap.values.sortedByDescending { it.timestamp }

        // 5. Tafelschikking bijwerken
        if (cloudData.tafelschikking.isNotEmpty() && scoreManager.getSavedTafelschikking().isEmpty()) {
            scoreManager.saveTafelschikking(cloudData.tafelschikking)
        }

        // 6. Opslaan in ScoreManager
        scoreManager.saveAllPlayerNames(currentPlayers.sorted())
        scoreManager.saveAllGames(mergedGames)
        scoreManager.saveAllScores(mergedScores)
        scoreManager.refresh()
    }

    private suspend fun performUpload(code: String): Result<String> {
        return try {
            val scoreManager = ScoreManager.getInstance(context)
            val players = scoreManager.fetchPlayerNames()
            val games = scoreManager.playedGames.value
            val scores = scoreManager.scores.value
            val tafelschikking = scoreManager.getSavedTafelschikking()
            val localDeletedIds = prefs.getStringSet(KEY_DELETED_IDS, emptySet())?.toList() ?: emptyList()

            val now = System.currentTimeMillis()
            val payload = buildJsonObject {
                put("appVersion", "1.0")
                put("exportDate", isoFormat.format(Date(now)))
                put("lastUpdated", now)
                put("lastUpdatedDevice", "Android")

                put("playerNames", buildJsonArray {
                    players.forEach { add(JsonPrimitive(it)) }
                })
                put("tafelschikking", buildJsonArray {
                    tafelschikking.forEach { add(JsonPrimitive(it)) }
                })
                put("deletedGameIds", buildJsonArray {
                    localDeletedIds.forEach { add(JsonPrimitive(it)) }
                })

                // Volledige games
                put("playedGames", buildJsonArray {
                    games.forEach { g ->
                        add(buildJsonObject {
                            put("id", g.id)
                            put("timestamp", g.timestamp)
                            put("date", isoFormat.format(Date(g.timestamp)))
                            put("gameName", g.gameName)
                            put("winner", g.winner)
                            put("scores", buildJsonArray {
                                g.scores.forEach { s ->
                                    add(buildJsonObject {
                                        put("playerName", s.playerName)
                                        put("score", s.score)
                                        put("isWinner", s.isWinner)
                                        put("juisteBalzakken", s.juisteBalzakken)
                                        put("fouteBalzakken", s.fouteBalzakken)
                                    })
                                }
                            })
                            g.teams?.let { teams ->
                                put("teams", buildJsonArray {
                                    teams.forEach { t ->
                                        add(buildJsonObject {
                                            put("teamName", t.teamName)
                                            put("score", t.score)
                                            put("isWinner", t.isWinner)
                                            put("playerNames", buildJsonArray {
                                                t.playerNames.forEach { add(JsonPrimitive(it)) }
                                            })
                                        })
                                    }
                                })
                            }
                            g.scoreProgression?.let { prog ->
                                put("scoreProgression", buildJsonArray {
                                    prog.forEach { p ->
                                        add(buildJsonObject {
                                            put("round", p.round)
                                            put("playerName", p.playerName)
                                            put("cumulativeScore", p.cumulativeScore)
                                        })
                                    }
                                })
                            }
                        })
                    }
                })

                // Scores
                put("scores", buildJsonArray {
                    scores.forEach { sc ->
                        add(buildJsonObject {
                            put("id", sc.id)
                            put("timestamp", sc.timestamp)
                            put("date", isoFormat.format(Date(sc.timestamp)))
                            put("gameName", sc.gameName)
                            put("playerName", sc.playerName)
                            put("score", sc.score)
                            put("isWinner", sc.isWinner)
                        })
                    }
                })
            }

            val jsonString = Json.encodeToString(JsonObject.serializer(), payload)
            val targetUrl = "$cleanDatabaseUrl/vaults/$code.json"
            val responseCode = httpPut(targetUrl, jsonString)

            if (responseCode in 200..299) {
                val summary = "Gesynchroniseerd: ${games.size} potjes en ${players.size} spelers up-to-date."
                _lastSyncDate.value = now
                _lastSyncSummary.value = summary
                prefs.edit().putLong(KEY_LAST_TIMESTAMP, now).putString(KEY_LAST_SUMMARY, summary).apply()
                Result.success(summary)
            } else {
                val err = "Upload mislukt met HTTP code $responseCode. Controleer database-regels."
                _lastErrorMessage.value = err
                Result.failure(Exception(err))
            }
        } catch (e: Exception) {
            _lastErrorMessage.value = e.localizedMessage
            Result.failure(e)
        }
    }

    // MARK: - Eenvoudige HTTP Client

    private fun httpGet(urlString: String): String? {
        val url = URL(urlString)
        val conn = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 12000
            readTimeout = 12000
        }

        val code = conn.responseCode
        if (code in 200..299) {
            return conn.inputStream.bufferedReader().use(BufferedReader::readText)
        } else if (code == 404) {
            return null
        } else {
            throw Exception("Server gaf HTTP statuscode $code terug.")
        }
    }

    private fun httpPut(urlString: String, jsonBody: String): Int {
        val url = URL(urlString)
        val conn = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "PUT"
            doOutput = true
            connectTimeout = 12000
            readTimeout = 12000
            setRequestProperty("Content-Type", "application/json; charset=UTF-8")
        }

        OutputStreamWriter(conn.outputStream, Charsets.UTF_8).use { writer ->
            writer.write(jsonBody)
            writer.flush()
        }

        return conn.responseCode
    }

    // MARK: - Testen van Database Verbinding

    fun testConnection(onResult: (Boolean, String) -> Unit) {
        scope.launch {
            try {
                val testUrl = "$cleanDatabaseUrl/.json?shallow=true"
                val url = URL(testUrl)
                val conn = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "GET"
                    connectTimeout = 8000
                    readTimeout = 8000
                }

                val code = conn.responseCode
                withContext(Dispatchers.Main) {
                    when (code) {
                        200 -> onResult(true, "Verbinding met Firebase Realtime Database is geslaagd! (HTTP 200)")
                        401, 403 -> onResult(false, "Toegang geweigerd (HTTP $code). Controleer de Firebase Security Rules.")
                        else -> onResult(false, "Server gaf HTTP statuscode $code terug.")
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    onResult(false, "Verbindingsfout: ${e.localizedMessage ?: "Onbekende fout"}")
                }
            }
        }
    }
}
