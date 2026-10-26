package nl.nnbp.gamesapp.data

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import nl.nnbp.gamesapp.data.model.*
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.abs

class ScoreManager private constructor(context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences("GamesAppPrefs", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true; isLenient = true; encodeDefaults = true }

    private val scoresKey = "saved_game_scores"
    private val gamesKey = "saved_played_games"
    private val playersKey = "saved_player_names"
    private val profilesKey = "saved_player_profiles"

    private val _scores = MutableStateFlow<List<Score>>(emptyList())
    val scores: StateFlow<List<Score>> = _scores.asStateFlow()

    private val _playedGames = MutableStateFlow<List<PlayedGame>>(emptyList())
    val playedGames: StateFlow<List<PlayedGame>> = _playedGames.asStateFlow()

    private val _savedPlayerNames = MutableStateFlow<List<String>>(emptyList())
    val savedPlayerNames: StateFlow<List<String>> = _savedPlayerNames.asStateFlow()

    private val _playerProfiles = MutableStateFlow<Map<String, PlayerProfile>>(emptyMap())
    val playerProfiles: StateFlow<Map<String, PlayerProfile>> = _playerProfiles.asStateFlow()

    private val themeKey = "app_theme_mode"
    private val _themeMode = MutableStateFlow(prefs.getString(themeKey, "DARK_AMOLED") ?: "DARK_AMOLED")
    val themeMode: StateFlow<String> = _themeMode.asStateFlow()

    fun setThemeMode(mode: String) {
        prefs.edit().putString(themeKey, mode).apply()
        _themeMode.value = mode
    }

    init {
        refresh()
    }

    fun refresh() {
        val loadedScores = fetchScores()
        val loadedGames = fetchGames()
        _scores.value = loadedScores
        _playedGames.value = loadedGames
        _savedPlayerNames.value = fetchPlayerNames(loadedGames, loadedScores)
        _playerProfiles.value = fetchPlayerProfiles()
    }

    // MARK: - Spelersbeheer

    fun playerPlayCount(playerName: String): Int {
        val target = playerName.trim().lowercase()
        if (target.isEmpty()) return 0

        var count = 0
        for (game in _playedGames.value) {
            val inScores = game.scores.any { it.playerName.trim().lowercase() == target }
            val inTeams = game.teams?.any { team ->
                team.playerNames.any { it.trim().lowercase() == target }
            } ?: false

            if (inScores || inTeams) {
                count++
            }
        }
        return count
    }

    fun sortPlayersByPopularity(names: List<String>): List<String> {
        val countMap = mutableMapOf<String, Int>()
        for (game in _playedGames.value) {
            val countedForGame = mutableSetOf<String>()
            for (s in game.scores) {
                val norm = s.playerName.trim().lowercase()
                if (norm.isNotEmpty()) countedForGame.add(norm)
            }
            game.teams?.forEach { team ->
                team.playerNames.forEach { p ->
                    val norm = p.trim().lowercase()
                    if (norm.isNotEmpty()) countedForGame.add(norm)
                }
            }
            countedForGame.forEach { norm ->
                countMap[norm] = (countMap[norm] ?: 0) + 1
            }
        }

        return names.sortedWith { a, b ->
            val countA = countMap[a.trim().lowercase()] ?: 0
            val countB = countMap[b.trim().lowercase()] ?: 0
            if (countA != countB) {
                countB.compareTo(countA)
            } else {
                a.compareTo(b, ignoreCase = true)
            }
        }
    }

    fun fetchPlayerNames(
        gamesSource: List<PlayedGame> = _playedGames.value,
        scoresSource: List<Score> = _scores.value
    ): List<String> {
        val raw = prefs.getString(playersKey, null)
        if (raw != null) {
            return try {
                val list = json.decodeFromString<List<String>>(raw)
                sortPlayersByPopularity(list)
            } catch (e: Exception) {
                emptyList()
            }
        }

        val namesSet = mutableSetOf<String>()
        gamesSource.forEach { game ->
            game.scores.forEach {
                val tr = it.playerName.trim()
                if (tr.isNotEmpty()) namesSet.add(tr)
            }
            game.teams?.forEach { team ->
                team.playerNames.forEach {
                    val tr = it.trim()
                    if (tr.isNotEmpty()) namesSet.add(tr)
                }
            }
        }
        scoresSource.forEach {
            val tr = it.playerName.trim()
            if (tr.isNotEmpty()) namesSet.add(tr)
        }

        val sorted = sortPlayersByPopularity(namesSet.toList())
        persistPlayerNames(sorted)
        return sorted
    }

    fun savePlayerName(name: String) {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) return

        val current = _savedPlayerNames.value.toMutableList()
        if (current.none { it.equals(trimmed, ignoreCase = true) }) {
            current.add(trimmed)
            persistPlayerNames(current)
        }
    }

    fun savePlayerNames(names: Collection<String>) {
        names.forEach { savePlayerName(it) }
    }

    private fun persistPlayerNames(names: List<String>) {
        val sorted = sortPlayersByPopularity(names)
        try {
            prefs.edit().putString(playersKey, json.encodeToString(sorted)).apply()
            _savedPlayerNames.value = sorted
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun deletePlayer(name: String) {
        val current = _savedPlayerNames.value.toMutableList()
        current.removeAll { it.equals(name, ignoreCase = true) }
        persistPlayerNames(current)
        deletePlayerProfile(name)
    }

    fun clearAllPlayers() {
        prefs.edit().remove(playersKey).remove(profilesKey).apply()
        _savedPlayerNames.value = emptyList()
        _playerProfiles.value = emptyMap()
    }

    // MARK: - Spelersprofielen (Kleuren & Avatars)

    fun fetchPlayerProfiles(): Map<String, PlayerProfile> {
        val raw = prefs.getString(profilesKey, null) ?: return emptyMap()
        return try {
            val list = json.decodeFromString<List<PlayerProfile>>(raw)
            list.associateBy { it.name.trim().lowercase() }
        } catch (e: Exception) {
            emptyMap()
        }
    }

    fun getPlayerProfile(name: String): PlayerProfile {
        val norm = name.trim().lowercase()
        return _playerProfiles.value[norm] ?: PlayerProfile.defaultFor(name)
    }

    fun savePlayerProfile(profile: PlayerProfile) {
        val trimmed = profile.name.trim()
        val currentMap = _playerProfiles.value.toMutableMap()
        currentMap[trimmed.lowercase()] = profile.copy(name = trimmed)

        try {
            prefs.edit().putString(profilesKey, json.encodeToString(currentMap.values.toList())).apply()
            _playerProfiles.value = currentMap
            savePlayerName(trimmed)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun deletePlayerProfile(name: String) {
        val norm = name.trim().lowercase()
        val currentMap = _playerProfiles.value.toMutableMap()
        if (currentMap.containsKey(norm)) {
            currentMap.remove(norm)
            try {
                prefs.edit().putString(profilesKey, json.encodeToString(currentMap.values.toList())).apply()
                _playerProfiles.value = currentMap
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    // MARK: - Scores & Gespeelde Potjes ophalen

    fun fetchScores(): List<Score> {
        val raw = prefs.getString(scoresKey, null) ?: return emptyList()
        return try {
            json.decodeFromString<List<Score>>(raw)
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun fetchGames(): List<PlayedGame> {
        val raw = prefs.getString(gamesKey, null) ?: return emptyList()
        return try {
            json.decodeFromString<List<PlayedGame>>(raw)
        } catch (e: Exception) {
            emptyList()
        }
    }

    // MARK: - Spellen & Scores Opslaan

    fun saveScore(playerName: String, score: Int, gameName: String, isWinner: Boolean = false) {
        val trimmed = playerName.trim()
        savePlayerName(trimmed)

        val existing = fetchScores().toMutableList()
        val newScore = Score(
            timestamp = System.currentTimeMillis(),
            gameName = gameName,
            playerName = trimmed,
            score = score,
            isWinner = isWinner
        )
        existing.add(newScore)
        persistScores(existing)
    }

    fun saveGame(
        gameName: String,
        playerDetailedScores: List<PlayerScoreDetail>,
        winnerName: String,
        scoreProgression: List<RoundScoreDataPoint>? = null,
        crokinoleStats: CrokinoleGameStats? = null
    ) {
        val now = System.currentTimeMillis()
        val existingGames = fetchGames().toMutableList()
        val existingScores = fetchScores().toMutableList()

        // Debounce: voorkom dubbele registratie binnen 5 seconden
        val lastGame = existingGames.lastOrNull()
        if (lastGame != null &&
            lastGame.gameName.equals(gameName, ignoreCase = true) &&
            abs(now - lastGame.timestamp) < 5000L
        ) {
            val lastSummary = lastGame.scores.map { "${it.playerName}:${it.score}" }.sorted()
            val newSummary = playerDetailedScores.map { "${it.name.trim()}:${it.score}" }.sorted()
            if (lastSummary == newSummary) {
                return
            }
        }

        val trimmedWinner = winnerName.trim()
        if (trimmedWinner.isNotEmpty()) {
            savePlayerName(trimmedWinner)
        }

        val entries = playerDetailedScores.map { item ->
            val trimmed = item.name.trim()
            savePlayerName(trimmed)
            val isWinner = trimmedWinner.isNotEmpty() && trimmed.equals(trimmedWinner, ignoreCase = true)
            PlayerScore(
                playerName = trimmed,
                score = item.score,
                isWinner = isWinner,
                juisteBalzakken = item.juisteBalzakken,
                fouteBalzakken = item.fouteBalzakken
            )
        }

        val game = PlayedGame(
            timestamp = now,
            gameName = gameName,
            scores = entries,
            winner = trimmedWinner,
            scoreProgression = scoreProgression,
            crokinoleStats = crokinoleStats
        )
        existingGames.add(game)
        persistGames(existingGames)

        for (item in entries) {
            val scoreEntry = Score(
                timestamp = now,
                gameName = gameName,
                playerName = item.playerName,
                score = item.score,
                isWinner = item.isWinner
            )
            existingScores.add(scoreEntry)
        }
        persistScores(existingScores)
    }

    fun saveTeamGame(
        gameName: String,
        teams: List<TeamGameInput>,
        scoreProgression: List<RoundScoreDataPoint>? = null,
        crokinoleStats: CrokinoleGameStats? = null
    ) {
        val now = System.currentTimeMillis()
        val existingGames = fetchGames().toMutableList()
        val existingScores = fetchScores().toMutableList()

        val winningTeam = teams.firstOrNull { it.isWinner }
        val cleanWinningPlayers = winningTeam?.playerNames?.map { it.trim() }?.filter { it.isNotEmpty() } ?: emptyList()
        val cleanTeamName = winningTeam?.teamName?.trim() ?: ""

        val gameTeams = mutableListOf<GameTeam>()
        val playerScores = mutableListOf<PlayerScore>()

        for (t in teams) {
            val cleanCurrentTeamName = t.teamName.trim()
            val cleanPlayers = t.playerNames.map { it.trim() }.filter { it.isNotEmpty() }

            val effectiveName = if (cleanCurrentTeamName.isEmpty()) cleanPlayers.joinToString(" & ") else cleanCurrentTeamName
            val teamEntry = GameTeam(
                teamName = effectiveName,
                playerNames = cleanPlayers,
                score = t.score,
                isWinner = t.isWinner
            )
            gameTeams.add(teamEntry)

            for (pName in cleanPlayers) {
                savePlayerName(pName)
                val ps = PlayerScore(
                    playerName = pName,
                    score = t.score,
                    isWinner = t.isWinner
                )
                playerScores.add(ps)

                val scoreEntry = Score(
                    timestamp = now,
                    gameName = gameName,
                    playerName = pName,
                    score = t.score,
                    isWinner = t.isWinner
                )
                existingScores.add(scoreEntry)
            }
        }

        val effectiveWinnerName: String
        val playersJoined = cleanWinningPlayers.joinToString(" & ")
        effectiveWinnerName = if (cleanTeamName.isEmpty() || isDefaultTeamName(cleanTeamName)) {
            if (playersJoined.isEmpty()) cleanTeamName else playersJoined
        } else {
            if (playersJoined.isEmpty()) cleanTeamName else "$cleanTeamName ($playersJoined)"
        }

        val defaultWinner = gameTeams.firstOrNull { it.isWinner }?.teamName ?: ""
        val game = PlayedGame(
            timestamp = now,
            gameName = gameName,
            scores = playerScores,
            winner = if (effectiveWinnerName.isEmpty()) defaultWinner else effectiveWinnerName,
            teams = gameTeams,
            scoreProgression = scoreProgression,
            crokinoleStats = crokinoleStats
        )
        existingGames.add(game)
        persistGames(existingGames)
        persistScores(existingScores)
    }

    private fun isDefaultTeamName(name: String): Boolean {
        val trimmed = name.trim().lowercase()
        if (trimmed.isEmpty() || trimmed.startsWith("team ")) return true
        val defaults = setOf(
            "de breinen", "de bollebozen", "de genieën", "de creatievelingen",
            "team 1", "team 2", "team 3", "team 4",
            "team wit", "team zwart", "team oranje", "team blauw", "team groen", "team paars", "team rood"
        )
        return defaults.contains(trimmed)
    }

    // MARK: - Verwijderen

    fun deleteGame(id: String) {
        val games = fetchGames().toMutableList()
        val toDelete = games.firstOrNull { it.id == id }
        if (toDelete != null) {
            deleteScoresForGame(toDelete)
        }
        games.removeAll { it.id == id }
        persistGames(games)
        refresh()
    }

    private fun deleteScoresForGame(game: PlayedGame) {
        val existingScores = fetchScores().toMutableList()
        val gameDate = game.timestamp
        val gameName = game.gameName
        val pNames = game.scores.map { it.playerName.lowercase() }.toSet()

        existingScores.removeAll { sc ->
            sc.gameName.equals(gameName, ignoreCase = true) &&
                    abs(sc.timestamp - gameDate) < 5000L &&
                    pNames.contains(sc.playerName.lowercase())
        }
        persistScores(existingScores)
    }

    fun deleteGames(ids: Set<String>) {
        val games = fetchGames().toMutableList()
        val existingScores = fetchScores().toMutableList()

        for (game in games.filter { ids.contains(it.id) }) {
            val gameDate = game.timestamp
            val gameName = game.gameName
            val pNames = game.scores.map { it.playerName.lowercase() }.toSet()

            existingScores.removeAll { sc ->
                sc.gameName.equals(gameName, ignoreCase = true) &&
                        abs(sc.timestamp - gameDate) < 5000L &&
                        pNames.contains(sc.playerName.lowercase())
            }
        }

        games.removeAll { ids.contains(it.id) }
        persistGames(games)
        persistScores(existingScores)
        refresh()
    }

    fun deleteGamesForDay(dayTimestamp: Long) {
        val calTarget = Calendar.getInstance().apply { timeInMillis = dayTimestamp }
        val idsToDelete = _playedGames.value.filter {
            val calGame = Calendar.getInstance().apply { timeInMillis = it.timestamp }
            calGame.get(Calendar.YEAR) == calTarget.get(Calendar.YEAR) &&
                    calGame.get(Calendar.DAY_OF_YEAR) == calTarget.get(Calendar.DAY_OF_YEAR)
        }.map { it.id }.toSet()

        deleteGames(idsToDelete)
    }

    fun deleteGamesForGame(gameName: String) {
        val idsToDelete = _playedGames.value.filter {
            it.gameName.equals(gameName, ignoreCase = true)
        }.map { it.id }.toSet()
        deleteGames(idsToDelete)
    }

    fun deleteGamesBeforeYesterday() {
        val cal = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, -1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startOfYesterday = cal.timeInMillis
        val idsToDelete = _playedGames.value.filter { it.timestamp < startOfYesterday }.map { it.id }.toSet()
        deleteGames(idsToDelete)
    }

    fun clearHistory() {
        prefs.edit().remove(scoresKey).remove(gamesKey).remove(playersKey).apply()
        _scores.value = emptyList()
        _playedGames.value = emptyList()
        _savedPlayerNames.value = emptyList()
    }

    private fun persistScores(scores: List<Score>) {
        try {
            prefs.edit().putString(scoresKey, json.encodeToString(scores)).apply()
            _scores.value = scores
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun persistGames(games: List<PlayedGame>) {
        try {
            prefs.edit().putString(gamesKey, json.encodeToString(games)).apply()
            _playedGames.value = games
            _savedPlayerNames.value = fetchPlayerNames(games, _scores.value)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // MARK: - Statistieken Berekeningen

    fun isLowestScoreWins(gameName: String): Boolean {
        val name = gameName.lowercase().trim()
        return name == "beverbende" || name == "balzakken" || name == "pig hole" ||
                name == "pighole" || name == "quickstop" || name == "quick stop" ||
                name == "fifty fifty" || name == "fiftyfifty"
    }

    fun matchesGameName(a: String, b: String): Boolean {
        val la = a.lowercase().replace(" ", "")
        val lb = b.lowercase().replace(" ", "")
        if (la == lb) return true
        if ((la.contains("crok") || la.contains("crokinole")) && (lb.contains("crok") || lb.contains("crokinole"))) {
            return true
        }
        return false
    }

    fun mostPlayedGames(): List<Pair<String, Int>> {
        return _playedGames.value.groupBy { it.gameName }
            .map { Pair(it.key, it.value.size) }
            .sortedByDescending { it.second }
    }

    fun didPlayerWin(game: PlayedGame, playerName: String): Boolean {
        val cleanName = playerName.trim()
        if (cleanName.isEmpty()) return false

        // 1. Directe controle op isWinner vlag in de individuele score
        val ps = game.scores.firstOrNull { it.playerName.equals(cleanName, ignoreCase = true) }
        if (ps?.isWinner == true) return true

        // 2. Controle in de teamstructuur
        game.teams?.forEach { team ->
            if (team.playerNames.any { it.equals(cleanName, ignoreCase = true) }) {
                if (team.isWinner) return true
                if (!game.isTie && game.winner.isNotEmpty()) {
                    if (team.teamName.equals(game.winner, ignoreCase = true) ||
                        game.winner.contains(team.teamName, ignoreCase = true)
                    ) {
                        return true
                    }
                    val cleanWinner = game.winner.lowercase()
                    if (team.playerNames.isNotEmpty() && team.playerNames.all { p ->
                            val tr = p.trim().lowercase()
                            tr.isNotEmpty() && cleanWinner.contains(tr)
                        }) {
                        return true
                    }
                }
            }
        }

        // 3. Controle op game.winner string
        if (!game.isTie && game.winner.isNotEmpty()) {
            val w = game.winner.trim()
            if (w.equals(cleanName, ignoreCase = true)) return true

            val parts = w.split('&', '+', ',', '/', '(', ')').map { it.trim() }
            if (parts.any { it.equals(cleanName, ignoreCase = true) }) return true
        }

        return false
    }

    fun overallWinRankings(): List<OverallRankRecord> {
        val players = _savedPlayerNames.value
        val results = mutableListOf<OverallRankRecord>()

        for (player in players) {
            var totalGames = 0
            var wins = 0

            for (game in _playedGames.value) {
                if (game.playerNamesList.any { it.equals(player, ignoreCase = true) }) {
                    totalGames++
                    if (didPlayerWin(game, player)) {
                        wins++
                    }
                }
            }

            if (totalGames > 0) {
                val rate = (wins.toDouble() / totalGames.toDouble()) * 100.0
                results.add(OverallRankRecord(player, wins, totalGames, rate))
            }
        }

        return results.sortedWith { a, b ->
            if (a.wins != b.wins) b.wins.compareTo(a.wins) else b.winRate.compareTo(a.winRate)
        }
    }

    fun gameLeaderboard(gameName: String): List<GameSpecificPlayerStat> {
        val lowestWins = isLowestScoreWins(gameName)
        val matchingGames = _playedGames.value.filter { matchesGameName(it.gameName, gameName) }

        val playerMap = mutableMapOf<String, Triple<Int, Int, MutableList<Int>>>() // played, won, scores

        for (game in matchingGames) {
            val entries = mutableListOf<Pair<String, Int>>()
            if (game.scores.isNotEmpty()) {
                game.scores.forEach { entries.add(Pair(it.playerName, it.score)) }
            } else if (game.teams != null) {
                game.teams.forEach { t ->
                    t.playerNames.forEach { p -> entries.add(Pair(p, t.score)) }
                }
            }

            for (entry in entries) {
                val pName = entry.first.trim()
                if (pName.isEmpty()) continue
                val cur = playerMap[pName] ?: Triple(0, 0, mutableListOf())
                val won = cur.second + if (didPlayerWin(game, pName)) 1 else 0
                cur.third.add(entry.second)
                playerMap[pName] = Triple(cur.first + 1, won, cur.third)
            }
        }

        return playerMap.map { (name, data) ->
            val best = if (lowestWins) data.third.minOrNull() else data.third.maxOrNull()
            val avg = if (data.third.isEmpty()) null else data.third.average()
            GameSpecificPlayerStat(
                playerName = name,
                gamesPlayed = data.first,
                gamesWon = data.second,
                bestScore = best,
                averageScore = avg
            )
        }.sortedWith { a, b ->
            if (a.gamesWon != b.gamesWon) {
                b.gamesWon.compareTo(a.gamesWon)
            } else if (a.winRate != b.winRate) {
                b.winRate.compareTo(a.winRate)
            } else {
                b.gamesPlayed.compareTo(a.gamesPlayed)
            }
        }
    }

    fun bestScoreEver(gameName: String): Pair<String, Int>? {
        val lowestWins = isLowestScoreWins(gameName)
        val all = mutableListOf<Pair<String, Int>>()

        _scores.value.filter { matchesGameName(it.gameName, gameName) }.forEach {
            all.add(Pair(it.playerName, it.score))
        }

        if (all.isEmpty()) {
            _playedGames.value.filter { matchesGameName(it.gameName, gameName) }.forEach { g ->
                g.scores.forEach { sc -> all.add(Pair(sc.playerName, sc.score)) }
            }
        }

        if (all.isEmpty()) return null

        return if (lowestWins) {
            all.minByOrNull { it.second }
        } else {
            all.maxByOrNull { it.second }
        }
    }

    fun recentSessions(gameName: String, limit: Int = 10): List<PlayedGame> {
        return _playedGames.value
            .filter { matchesGameName(it.gameName, gameName) }
            .sortedByDescending { it.timestamp }
            .take(limit)
    }

    fun detailedStats(playerName: String): DetailedPlayerStats {
        val playerGames = _playedGames.value.filter { game ->
            game.playerNamesList.any { it.equals(playerName, ignoreCase = true) }
        }

        val totalGames = playerGames.size
        val totalWins = playerGames.count { didPlayerWin(it, playerName) }

        val grouped = playerGames.groupBy { it.gameName }
        val statsPerGame = grouped.map { (gName, gList) ->
            val played = gList.size
            val won = gList.count { didPlayerWin(it, playerName) }
            val scoresInGame = gList.mapNotNull { g ->
                g.scores.firstOrNull { it.playerName.equals(playerName, ignoreCase = true) }?.score
                    ?: g.teams?.firstOrNull { t -> t.playerNames.any { it.equals(playerName, ignoreCase = true) } }?.score
            }
            val best = if (isLowestScoreWins(gName)) scoresInGame.minOrNull() else scoresInGame.maxOrNull()
            GamePlayerStat(gName, played, won, best)
        }.sortedByDescending { it.played }

        return DetailedPlayerStats(playerName, totalGames, totalWins, statsPerGame)
    }

    fun headToHead(playerA: String, playerB: String, gameFilter: String? = null): HeadToHeadRecord {
        var relevant = _playedGames.value.filter { g ->
            val hasA = g.scores.any { it.playerName.equals(playerA, ignoreCase = true) }
            val hasB = g.scores.any { it.playerName.equals(playerB, ignoreCase = true) }
            hasA && hasB
        }

        if (!gameFilter.isNullOrEmpty() && gameFilter != "Alle Spellen") {
            relevant = relevant.filter { matchesGameName(it.gameName, gameFilter) }
        }

        var winsA = 0
        var winsB = 0
        var ties = 0

        for (game in relevant) {
            val lowestWins = isLowestScoreWins(game.gameName)

            if (!game.teams.isNullOrEmpty()) {
                val tA = game.teams.firstOrNull { it.playerNames.any { p -> p.equals(playerA, ignoreCase = true) } }
                val tB = game.teams.firstOrNull { it.playerNames.any { p -> p.equals(playerB, ignoreCase = true) } }

                if (tA != null && tB != null) {
                    if (tA.teamName == tB.teamName && tA.playerNames == tB.playerNames) {
                        continue
                    }
                    val aWon = didPlayerWin(game, playerA)
                    val bWon = didPlayerWin(game, playerB)
                    if (aWon && !bWon) winsA++
                    else if (bWon && !aWon) winsB++
                    else if (tA.score == tB.score) ties++
                    else if (lowestWins) {
                        if (tA.score < tB.score) winsA++ else winsB++
                    } else {
                        if (tA.score > tB.score) winsA++ else winsB++
                    }
                    continue
                }
            }

            val scoreA = game.scores.firstOrNull { it.playerName.equals(playerA, ignoreCase = true) }?.score
            val scoreB = game.scores.firstOrNull { it.playerName.equals(playerB, ignoreCase = true) }?.score
            if (scoreA == null || scoreB == null) continue

            if (scoreA == scoreB) ties++
            else if (lowestWins) {
                if (scoreA < scoreB) winsA++ else winsB++
            } else {
                if (scoreA > scoreB) winsA++ else winsB++
            }
        }

        return HeadToHeadRecord(playerA, playerB, winsA, winsB, ties, winsA + winsB + ties)
    }

    fun allRivalries(gameFilter: String? = null): List<HeadToHeadRecord> {
        val players = _savedPlayerNames.value
        if (players.size < 2) return emptyList()

        val records = mutableListOf<HeadToHeadRecord>()
        for (i in players.indices) {
            for (j in (i + 1) until players.size) {
                val rec = headToHead(players[i], players[j], gameFilter)
                if (rec.totalGames > 0) {
                    records.add(rec)
                }
            }
        }
        return records.sortedByDescending { it.totalGames }
    }

    fun balzakkenLeaderboard(): List<BalzakkenPlayerStat> {
        val map = mutableMapOf<String, Triple<Int, Int, Int>>() // juiste, foute, games

        for (game in _playedGames.value.filter { it.gameName.equals("balzakken", ignoreCase = true) }) {
            for (sc in game.scores) {
                val cur = map[sc.playerName] ?: Triple(0, 0, 0)
                map[sc.playerName] = Triple(
                    cur.first + sc.juisteBalzakken,
                    cur.second + sc.fouteBalzakken,
                    cur.third + 1
                )
            }
        }

        return map.map { (name, data) ->
            BalzakkenPlayerStat(name, data.first, data.second, data.third)
        }.sortedWith { a, b ->
            if (a.juisteBalzakken != b.juisteBalzakken) {
                b.juisteBalzakken.compareTo(a.juisteBalzakken)
            } else {
                a.fouteBalzakken.compareTo(b.fouteBalzakken)
            }
        }
    }

    fun teamLeaderboard(gameFilter: String? = null): List<TeamStat> {
        val teamMap = mutableMapOf<String, TeamStatAccumulator>()

        var relevant = _playedGames.value.filter { !it.teams.isNullOrEmpty() }
        if (!gameFilter.isNullOrEmpty() && gameFilter != "Alle Spellen") {
            relevant = relevant.filter { matchesGameName(it.gameName, gameFilter) }
        }

        for (game in relevant) {
            val teams = game.teams ?: continue
            for (team in teams) {
                val sortedPlayers = team.playerNames.sorted()
                if (sortedPlayers.size < 2) continue
                val teamKey = sortedPlayers.joinToString(" & ")
                val effectiveName = if (isDefaultTeamName(team.teamName)) sortedPlayers.joinToString(" & ") else team.teamName

                val teamWon = team.isWinner || (!game.isTie && game.winner.equals(team.teamName, ignoreCase = true))

                val cur = teamMap[teamKey] ?: TeamStatAccumulator(effectiveName, sortedPlayers, 0, 0, 0)
                cur.played++
                if (teamWon) cur.won++
                cur.totalScore += team.score
                teamMap[teamKey] = cur
            }
        }

        return teamMap.map { (key, data) ->
            TeamStat(key, data.displayName, data.players, data.played, data.won, data.totalScore)
        }.sortedWith { a, b ->
            if (a.won != b.won) b.won.compareTo(a.won)
            else if (a.winRate != b.winRate) b.winRate.compareTo(a.winRate)
            else b.played.compareTo(a.played)
        }
    }

    fun partnerSynergy(playerName: String): List<PartnerSynergyStat> {
        val norm = playerName.trim().lowercase()
        val partnerMap = mutableMapOf<String, Triple<Int, Int, Int>>() // partnerName -> (together, won, lost)

        for (game in _playedGames.value) {
            val teams = game.teams ?: continue
            for (team in teams) {
                val hasPlayer = team.playerNames.any { it.trim().lowercase() == norm }
                if (hasPlayer) {
                    val teamWon = team.isWinner || (!game.isTie && game.winner.equals(team.teamName, ignoreCase = true))
                    for (p in team.playerNames) {
                        if (p.trim().lowercase() != norm) {
                            val current = partnerMap[p] ?: Triple(0, 0, 0)
                            partnerMap[p] = Triple(
                                current.first + 1,
                                current.second + (if (teamWon) 1 else 0),
                                current.third + (if (!teamWon) 1 else 0)
                            )
                        }
                    }
                }
            }
        }

        return partnerMap.map { (partner, stats) ->
            PartnerSynergyStat(partner, stats.first, stats.second, stats.third)
        }.sortedWith { a, b ->
            if (a.winsTogether != b.winsTogether) b.winsTogether.compareTo(a.winsTogether)
            else if (a.winRate != b.winRate) b.winRate.compareTo(a.winRate)
            else b.gamesTogether.compareTo(a.gamesTogether)
        }
    }

    fun bestPartner(playerName: String): PartnerSynergyStat? = partnerSynergy(playerName).firstOrNull()

    fun playerStreaks(playerName: String): Pair<Int, Int> { // (currentStreak, bestStreak)
        val norm = playerName.trim().lowercase()
        val chronological = _playedGames.value
            .filter { g -> g.playerNamesList.any { it.trim().lowercase() == norm } }
            .sortedBy { it.timestamp }

        if (chronological.isEmpty()) return Pair(0, 0)

        var currentRunning = 0
        var maxStreak = 0

        for (game in chronological) {
            val won = didPlayerWin(game, playerName)
            if (won) {
                currentRunning++
                if (currentRunning > maxStreak) {
                    maxStreak = currentRunning
                }
            } else {
                currentRunning = 0
            }
        }

        var activeStreak = 0
        for (i in chronological.indices.reversed()) {
            if (didPlayerWin(chronological[i], playerName)) {
                activeStreak++
            } else {
                break
            }
        }

        return Pair(activeStreak, maxStreak)
    }

    fun playerNemesis(playerName: String): Pair<String, Double>? {
        val norm = playerName.trim().lowercase()
        val allOtherPlayers = _savedPlayerNames.value.filter { it.trim().lowercase() != norm }
        if (allOtherPlayers.isEmpty()) return null

        val records = allOtherPlayers.map { other ->
            headToHead(playerName, other)
        }.filter { it.totalGames >= 1 }

        val potentialNemesis = records.filter { it.winsB > it.winsA }
        if (potentialNemesis.isEmpty()) return null

        val filtered = if (potentialNemesis.any { it.totalGames >= 2 }) {
            potentialNemesis.filter { it.totalGames >= 2 }
        } else {
            potentialNemesis
        }

        val top = filtered.maxWithOrNull { a, b ->
            val rateA = (a.winsB.toDouble() / a.totalGames.toDouble())
            val rateB = (b.winsB.toDouble() / b.totalGames.toDouble())
            if (rateA != rateB) rateA.compareTo(rateB)
            else a.winsB.compareTo(b.winsB)
        } ?: return null

        val oppWinRate = (top.winsB.toDouble() / top.totalGames.toDouble()) * 100.0
        return Pair(top.playerB, oppWinRate)
    }

    fun playerBadges(playerName: String): List<PlayerBadge> {
        val norm = playerName.trim().lowercase()
        val playerGames = _playedGames.value.filter { g -> g.playerNamesList.any { it.trim().lowercase() == norm } }
        val totalGames = playerGames.size
        val totalWins = playerGames.count { didPlayerWin(it, playerName) }
        val streaks = playerStreaks(playerName)
        val bestStreak = streaks.second
        val winRate = if (totalGames > 0) (totalWins.toDouble() / totalGames.toDouble()) * 100.0 else 0.0

        val wonGames = playerGames.filter { didPlayerWin(it, playerName) }
        val wonGameNames = wonGames.map { it.gameName.lowercase() }

        var juisteBalzakken = 0
        playerGames.filter { it.gameName.equals("balzakken", ignoreCase = true) }.forEach { g ->
            g.scores.firstOrNull { it.playerName.trim().lowercase() == norm }?.let {
                juisteBalzakken += it.juisteBalzakken
            }
        }

        val teamWins = playerGames.count { g ->
            val teams = g.teams
            if (!teams.isNullOrEmpty()) {
                val myTeam = teams.firstOrNull { t -> t.playerNames.any { it.trim().lowercase() == norm } }
                myTeam != null && didPlayerWin(g, playerName)
            } else false
        }

        return listOf(
            PlayerBadge(
                title = "Eerste Winst",
                subtitle = "Win je allereerste bordspel",
                iconName = "🏆",
                colorHex = 0xFFFFD700L,
                isUnlocked = totalWins >= 1
            ),
            PlayerBadge(
                title = "Spelkampioen",
                subtitle = "Win minstens 5 spellen",
                iconName = "👑",
                colorHex = 0xFFFF9500L,
                isUnlocked = totalWins >= 5
            ),
            PlayerBadge(
                title = "Op Dreef",
                subtitle = "Win minstens 3 potjes op rij",
                iconName = "⚡️",
                colorHex = 0xFF007AFFL,
                isUnlocked = bestStreak >= 3
            ),
            PlayerBadge(
                title = "Bordspelveteraan",
                subtitle = "Speel minstens 10 spellen",
                iconName = "🎖️",
                colorHex = 0xFF8E8E93L,
                isUnlocked = totalGames >= 10
            ),
            PlayerBadge(
                title = "Kennisgigant",
                subtitle = "Winst in 30 Seconds of Cranium",
                iconName = "🧠",
                colorHex = 0xFFAF52DEL,
                isUnlocked = wonGameNames.any { it.contains("30 second") || it.contains("cranium") }
            ),
            PlayerBadge(
                title = "Balzakkoning",
                subtitle = "Minstens 3 juiste Balzakken geroepen",
                iconName = "🦹‍♂️",
                colorHex = 0xFFE53935L,
                isUnlocked = juisteBalzakken >= 3
            ),
            PlayerBadge(
                title = "Sluwe Vos",
                subtitle = "Winst in Beverbende of Love Letter",
                iconName = "🦊",
                colorHex = 0xFFFF7043L,
                isUnlocked = wonGameNames.any { it.contains("beverbende") || it.contains("love letter") }
            ),
            PlayerBadge(
                title = "Wormenvanger",
                subtitle = "Overwinning in Regenwormen",
                iconName = "🐛",
                colorHex = 0xFF43A047L,
                isUnlocked = wonGameNames.any { it.contains("regenworm") }
            ),
            PlayerBadge(
                title = "Spoorwegbaron",
                subtitle = "Overwinning in Ticket to Ride",
                iconName = "🚂",
                colorHex = 0xFF00ACC1L,
                isUnlocked = wonGameNames.any { it.contains("ticket to ride") }
            ),
            PlayerBadge(
                title = "Dobbelmeester",
                subtitle = "Winst in Qwixx of Pig Hole",
                iconName = "🎲",
                colorHex = 0xFF3949ABL,
                isUnlocked = wonGameNames.any { it.contains("qwixx") || it.contains("pig hole") }
            ),
            PlayerBadge(
                title = "Gouden Duo",
                subtitle = "Win minstens 3 teamspellen",
                iconName = "🤝",
                colorHex = 0xFFFFB300L,
                isUnlocked = teamWins >= 3
            ),
            PlayerBadge(
                title = "Grootmeester",
                subtitle = "Minimaal 50% winrate over 5+ spellen",
                iconName = "💎",
                colorHex = 0xFF00C853L,
                isUnlocked = totalGames >= 5 && winRate >= 50.0
            )
        )
    }

    fun playerPassport(playerName: String): PlayerPassportData {
        val cleanName = playerName.trim()
        val profile = getPlayerProfile(cleanName)
        val detailed = detailedStats(cleanName)
        val streaks = playerStreaks(cleanName)
        val nemesis = playerNemesis(cleanName)
        val partner = bestPartner(cleanName)
        val badges = playerBadges(cleanName)

        val favorite = detailed.statsPerGame.maxByOrNull { it.played }?.let {
            Pair(it.gameName, it.played)
        }

        val best = detailed.statsPerGame
            .filter { it.played >= 2 || (detailed.statsPerGame.all { s -> s.played < 2 } && it.played >= 1) }
            .maxByOrNull { it.winRate }?.let {
                Pair(it.gameName, it.winRate)
            }

        return PlayerPassportData(
            profile = profile,
            totalGames = detailed.totalGames,
            totalWins = detailed.totalWins,
            winRate = detailed.winRate,
            favoriteGame = favorite,
            bestGame = best,
            nemesis = nemesis,
            bestPartner = partner,
            currentStreak = streaks.first,
            bestStreak = streaks.second,
            badges = badges
        )
    }

    companion object {
        @Volatile
        private var INSTANCE: ScoreManager? = null

        fun initialize(context: Context): ScoreManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: ScoreManager(context.applicationContext).also { INSTANCE = it }
            }
        }

        fun getInstance(): ScoreManager {
            return INSTANCE ?: throw IllegalStateException("ScoreManager must be initialized in Application.onCreate")
        }
    }
}

data class PlayerScoreDetail(
    val name: String,
    val score: Int,
    val juisteBalzakken: Int = 0,
    val fouteBalzakken: Int = 0
)

data class TeamGameInput(
    val teamName: String,
    val playerNames: List<String>,
    val score: Int,
    val isWinner: Boolean
)

data class OverallRankRecord(
    val playerName: String,
    val wins: Int,
    val totalGames: Int,
    val winRate: Double
)

private class TeamStatAccumulator(
    val displayName: String,
    val players: List<String>,
    var played: Int,
    var won: Int,
    var totalScore: Int
)
