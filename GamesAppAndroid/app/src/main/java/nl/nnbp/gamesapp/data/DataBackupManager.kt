package nl.nnbp.gamesapp.data

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import kotlinx.serialization.json.*
import nl.nnbp.gamesapp.data.model.*
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

data class BackupParsedData(
    val appVersion: String,
    val exportDate: String,
    val playerNames: List<String>,
    val playedGames: List<PlayedGame>,
    val scores: List<Score>,
    val playerProfiles: Map<String, PlayerProfile> = emptyMap(),
    val tafelschikking: List<String> = emptyList()
)

object DataBackupManager {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        encodeDefaults = true
        prettyPrint = true
    }

    private val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }

    private val fileDateFormat = SimpleDateFormat("yyyy-MM-dd_HHmm", Locale.getDefault())

    fun generateBackupFileName(): String {
        val dateStr = fileDateFormat.format(Date())
        return "GamesApp_Backup_$dateStr.json"
    }

    fun generateBackupJson(context: Context): String {
        val scoreManager = ScoreManager.getInstance(context)
        val players = scoreManager.fetchPlayerNames()
        val games = scoreManager.playedGames.value
        val scores = scoreManager.scores.value
        val profiles = scoreManager.playerProfiles.value

        val root = buildJsonObject {
            put("appVersion", "1.3.1")
            put("exportDate", isoFormat.format(Date()))
            put("playerNames", buildJsonArray {
                players.forEach { add(JsonPrimitive(it)) }
            })
            val tafelschikking = scoreManager.getSavedTafelschikking()
            put("tafelschikking", buildJsonArray {
                tafelschikking.forEach { add(JsonPrimitive(it)) }
            })
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
            put("playerProfiles", buildJsonArray {
                profiles.values.forEach { pr ->
                    add(buildJsonObject {
                        put("name", pr.name)
                        put("colorHex", pr.colorHex)
                        pr.avatarEmoji?.let { put("avatarEmoji", it) }
                    })
                }
            })
        }

        return json.encodeToString(JsonObject.serializer(), root)
    }

    fun writeBackupToUri(context: Context, uri: Uri): Result<String> {
        return try {
            val content = generateBackupJson(context)
            context.contentResolver.openOutputStream(uri)?.use { os ->
                os.write(content.toByteArray(Charsets.UTF_8))
            } ?: return Result.failure(Exception("Kan uitvoerbestand niet openen"))
            Result.success("Back-up succesvol opgeslagen!")
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun createShareIntent(context: Context): Result<Intent> {
        return try {
            val content = generateBackupJson(context)
            val fileName = generateBackupFileName()
            val file = File(context.cacheDir, fileName)
            file.writeText(content, Charsets.UTF_8)

            val fileUri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )

            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "application/json"
                putExtra(Intent.EXTRA_STREAM, fileUri)
                putExtra(Intent.EXTRA_SUBJECT, "GamesApp Back-up ($fileName)")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            Result.success(Intent.createChooser(shareIntent, "Deel GamesApp Back-up via"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun parseBackupJson(rawJson: String): BackupParsedData {
        val root = json.parseToJsonElement(rawJson).jsonObject

        val appVersion = root["appVersion"]?.jsonPrimitive?.contentOrNull ?: "1.0"
        val exportDate = root["exportDate"]?.jsonPrimitive?.contentOrNull ?: ""

        val playerNames = mutableListOf<String>()
        root["playerNames"]?.jsonArray?.forEach {
            val name = it.jsonPrimitive.contentOrNull?.trim()
            if (!name.isNullOrEmpty() && !playerNames.contains(name)) {
                playerNames.add(name)
            }
        }

        val playedGames = mutableListOf<PlayedGame>()
        root["playedGames"]?.jsonArray?.forEach { gElem ->
            try {
                val obj = gElem.jsonObject
                val id = obj["id"]?.jsonPrimitive?.contentOrNull ?: UUID.randomUUID().toString()
                val timestamp = parseTimestamp(obj["timestamp"], obj["date"])
                val gameName = obj["gameName"]?.jsonPrimitive?.contentOrNull ?: "Onbekend"
                val winner = obj["winner"]?.jsonPrimitive?.contentOrNull ?: ""

                val scores = mutableListOf<PlayerScore>()
                obj["scores"]?.jsonArray?.forEach { sElem ->
                    val sObj = sElem.jsonObject
                    val pName = sObj["playerName"]?.jsonPrimitive?.contentOrNull?.trim() ?: ""
                    val sc = sObj["score"]?.jsonPrimitive?.intOrNull ?: 0
                    val isWin = sObj["isWinner"]?.jsonPrimitive?.booleanOrNull ?: false
                    val jb = sObj["juisteBalzakken"]?.jsonPrimitive?.intOrNull ?: 0
                    val fb = sObj["fouteBalzakken"]?.jsonPrimitive?.intOrNull ?: 0
                    if (pName.isNotEmpty()) {
                        scores.add(PlayerScore(playerName = pName, score = sc, isWinner = isWin, juisteBalzakken = jb, fouteBalzakken = fb))
                    }
                }

                val teams = mutableListOf<GameTeam>()
                obj["teams"]?.jsonArray?.forEach { tElem ->
                    val tObj = tElem.jsonObject
                    val tName = tObj["teamName"]?.jsonPrimitive?.contentOrNull ?: "Team"
                    val tScore = tObj["score"]?.jsonPrimitive?.intOrNull ?: 0
                    val tWin = tObj["isWinner"]?.jsonPrimitive?.booleanOrNull ?: false
                    val pList = tObj["playerNames"]?.jsonArray?.mapNotNull { it.jsonPrimitive.contentOrNull?.trim() }?.filter { it.isNotEmpty() } ?: emptyList()
                    teams.add(GameTeam(teamName = tName, playerNames = pList, score = tScore, isWinner = tWin))
                }

                val progression = mutableListOf<RoundScoreDataPoint>()
                obj["scoreProgression"]?.jsonArray?.forEach { pElem ->
                    val pObj = pElem.jsonObject
                    val r = pObj["round"]?.jsonPrimitive?.intOrNull ?: 0
                    val pn = pObj["playerName"]?.jsonPrimitive?.contentOrNull?.trim() ?: ""
                    val cs = pObj["cumulativeScore"]?.jsonPrimitive?.intOrNull ?: 0
                    if (pn.isNotEmpty()) {
                        progression.add(RoundScoreDataPoint(round = r, playerName = pn, cumulativeScore = cs))
                    }
                }

                playedGames.add(
                    PlayedGame(
                        id = id,
                        timestamp = timestamp,
                        gameName = gameName,
                        scores = scores,
                        winner = winner,
                        teams = if (teams.isNotEmpty()) teams else null,
                        scoreProgression = if (progression.isNotEmpty()) progression else null
                    )
                )
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        val scores = mutableListOf<Score>()
        root["scores"]?.jsonArray?.forEach { scElem ->
            try {
                val obj = scElem.jsonObject
                val id = obj["id"]?.jsonPrimitive?.contentOrNull ?: UUID.randomUUID().toString()
                val timestamp = parseTimestamp(obj["timestamp"], obj["date"])
                val gameName = obj["gameName"]?.jsonPrimitive?.contentOrNull ?: ""
                val playerName = obj["playerName"]?.jsonPrimitive?.contentOrNull?.trim() ?: ""
                val sc = obj["score"]?.jsonPrimitive?.intOrNull ?: 0
                val isWin = obj["isWinner"]?.jsonPrimitive?.booleanOrNull ?: false
                if (playerName.isNotEmpty()) {
                    scores.add(Score(id = id, timestamp = timestamp, gameName = gameName, playerName = playerName, score = sc, isWinner = isWin))
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        val profiles = mutableMapOf<String, PlayerProfile>()
        root["playerProfiles"]?.jsonArray?.forEach { prElem ->
            try {
                val obj = prElem.jsonObject
                val name = obj["name"]?.jsonPrimitive?.contentOrNull?.trim() ?: ""
                val colorHexRaw = obj["colorHex"]?.jsonPrimitive
                val colorHexLong = colorHexRaw?.longOrNull ?: run {
                    val str = colorHexRaw?.contentOrNull ?: ""
                    if (str.startsWith("#")) {
                        try {
                            android.graphics.Color.parseColor(str).toLong() and 0xFFFFFFFFL
                        } catch (_: Exception) {
                            0xFF007AFFL
                        }
                    } else 0xFF007AFFL
                }
                val avatarEmoji = obj["avatarEmoji"]?.jsonPrimitive?.contentOrNull?.ifEmpty { null }
                if (name.isNotEmpty()) {
                    profiles[name.lowercase()] = PlayerProfile(name = name, colorHex = colorHexLong, avatarEmoji = avatarEmoji)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        val tafelschikking = mutableListOf<String>()
        root["tafelschikking"]?.jsonArray?.forEach {
            val name = it.jsonPrimitive.contentOrNull?.trim()
            if (!name.isNullOrEmpty()) {
                tafelschikking.add(name)
            }
        }

        return BackupParsedData(
            appVersion = appVersion,
            exportDate = exportDate,
            playerNames = playerNames,
            playedGames = playedGames,
            scores = scores,
            playerProfiles = profiles,
            tafelschikking = tafelschikking
        )
    }

    private fun parseTimestamp(timestampElem: JsonElement?, dateElem: JsonElement?): Long {
        timestampElem?.jsonPrimitive?.longOrNull?.let { return it }

        dateElem?.jsonPrimitive?.longOrNull?.let {
            return if (it < 10000000000L) it * 1000L else it
        }
        dateElem?.jsonPrimitive?.doubleOrNull?.let {
            return (it * 1000.0).toLong()
        }

        dateElem?.jsonPrimitive?.contentOrNull?.let { str ->
            try {
                val iso = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).apply {
                    timeZone = TimeZone.getTimeZone("UTC")
                }
                iso.parse(str)?.let { return it.time }
            } catch (e: Exception) {}

            try {
                val isoMillis = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                    timeZone = TimeZone.getTimeZone("UTC")
                }
                isoMillis.parse(str)?.let { return it.time }
            } catch (e: Exception) {}
        }

        return System.currentTimeMillis()
    }

    fun importBackupFromUri(context: Context, uri: Uri, merge: Boolean): Result<String> {
        return try {
            val content = context.contentResolver.openInputStream(uri)?.use { stream ->
                stream.bufferedReader(Charsets.UTF_8).readText()
            } ?: return Result.failure(Exception("Kan geselecteerd bestand niet lezen"))

            val backup = parseBackupJson(content)
            val scoreManager = ScoreManager.getInstance(context)

            if (merge) {
                // Samenvoegen:
                // 1. Spelersamenvoeging
                val currentPlayers = scoreManager.fetchPlayerNames().toMutableSet()
                backup.playerNames.forEach { currentPlayers.add(it) }
                backup.playedGames.forEach { g ->
                    g.playerNamesList.forEach { currentPlayers.add(it) }
                }

                // 2. Gespeelde potjes samenvoeging (geen dubbele IDs of zelfde potje binnen 10 sec)
                val currentGames = scoreManager.playedGames.value.toMutableList()
                val existingIds = currentGames.map { it.id }.toSet()
                var addedGamesCount = 0

                for (bg in backup.playedGames) {
                    if (!existingIds.contains(bg.id)) {
                        val isDuplicate = currentGames.any {
                            it.gameName.equals(bg.gameName, ignoreCase = true) &&
                                    kotlin.math.abs(it.timestamp - bg.timestamp) < 10000L &&
                                    it.scores.size == bg.scores.size
                        }
                        if (!isDuplicate) {
                            currentGames.add(bg)
                            addedGamesCount++
                        }
                    }
                }

                // 3. Scores samenvoeging
                val currentScores = scoreManager.scores.value.toMutableList()
                val existingScoreIds = currentScores.map { it.id }.toSet()
                for (sc in backup.scores) {
                    if (!existingScoreIds.contains(sc.id)) {
                        currentScores.add(sc)
                    }
                }

                // 4. Spelersprofielen samenvoeging
                val currentProfiles = scoreManager.playerProfiles.value.toMutableMap()
                backup.playerProfiles.forEach { (key, prof) ->
                    if (!currentProfiles.containsKey(key)) {
                        currentProfiles[key] = prof
                    }
                }

                scoreManager.saveAllPlayerNames(currentPlayers.toList())
                scoreManager.saveAllGames(currentGames)
                scoreManager.saveAllScores(currentScores)
                scoreManager.saveAllPlayerProfiles(currentProfiles)
                if (backup.tafelschikking.isNotEmpty()) {
                    scoreManager.saveTafelschikking(backup.tafelschikking)
                }
                scoreManager.refresh()

                Result.success("Succesvol samengevoegd! $addedGamesCount nieuwe potjes en ${currentPlayers.size} spelers bijgewerkt.")
            } else {
                // Alles overschrijven:
                scoreManager.saveAllPlayerNames(backup.playerNames)
                scoreManager.saveAllGames(backup.playedGames)
                scoreManager.saveAllScores(backup.scores)
                scoreManager.saveAllPlayerProfiles(backup.playerProfiles)
                if (backup.tafelschikking.isNotEmpty()) {
                    scoreManager.saveTafelschikking(backup.tafelschikking)
                }
                scoreManager.refresh()

                Result.success("Back-up succesvol hersteld! ${backup.playedGames.size} potjes en ${backup.playerNames.size} spelers geladen.")
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
