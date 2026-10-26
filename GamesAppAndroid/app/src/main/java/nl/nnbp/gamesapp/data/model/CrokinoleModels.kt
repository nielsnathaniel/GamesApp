package nl.nnbp.gamesapp.data.model

import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class CrokinoleRoundRecord(
    val id: String = UUID.randomUUID().toString(),
    val roundNumber: Int,
    val setNumber: Int,
    val scoreWit: Int,
    val scoreZwart: Int,
    val differential: Int,
    val roundWinner: String,
    val setScoresAfterRound: List<Int> = emptyList(),
    val pointsInSetAfterRound: List<Int> = emptyList(),
    val setWonInThisRound: Boolean = false,
    val winningTeamName: String? = null,
    val finalSetScore: Int? = null
)

@Serializable
data class CrokinoleGameStats(
    val maxRoundScore: Int = 0,
    val maxRoundScorePlayer: String = "",
    val maxRoundScoreRound: Int = 0,
    val maxDifferential: Int = 0,
    val maxSetScore: Int = 0,
    val maxSetScorePlayer: String = "",
    val totalRounds: Int = 0,
    val totalSets: Int = 0,
    val rounds: List<CrokinoleRoundRecord> = emptyList()
)

data class CrokinolePlayerRecord(
    val playerName: String,
    val gamesPlayed: Int,
    val gamesWon: Int,
    val setsWon: Int,
    val setsLost: Int,
    val highestRoundScore: Int,
    val highestSetScore: Int,
    val averageRoundScore: Double
)

data class CrokinoleOverallStats(
    val totalGamesPlayed: Int,
    val totalRoundsPlayed: Int,
    val totalSetsPlayed: Int,
    val allTimeHighestRound: Triple<Int, String, Long>?, // score, player, timestamp
    val allTimeHighestSet: Triple<Int, String, Long>?,
    val allTimeHighestDifferential: Triple<Int, String, Long>?,
    val topRoundScores: List<Triple<Int, String, Long>>,
    val topSetScores: List<Triple<Int, String, Long>>,
    val averageRoundsPerSet: Double,
    val averageRoundsPerGame: Double,
    val cleanSweepsCount: Int, // 3-0
    val regularWinsCount: Int, // 3-1
    val thrillerWinsCount: Int, // 3-2
    val playerLeaderboard: List<CrokinolePlayerRecord>
)
