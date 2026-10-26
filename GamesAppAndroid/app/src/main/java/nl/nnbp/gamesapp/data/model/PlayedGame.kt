package nl.nnbp.gamesapp.data.model

import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class RoundScoreDataPoint(
    val round: Int,
    val playerName: String,
    val cumulativeScore: Int
)

@Serializable
data class PlayedGame(
    val id: String = UUID.randomUUID().toString(),
    val timestamp: Long = System.currentTimeMillis(),
    val gameName: String,
    val scores: List<PlayerScore>,
    val winner: String,
    val teams: List<GameTeam>? = null,
    val scoreProgression: List<RoundScoreDataPoint>? = null,
    val crokinoleStats: CrokinoleGameStats? = null
) {
    val isTie: Boolean
        get() = winner.trim().isEmpty()

    val playerNamesList: List<String>
        get() {
            if (!teams.isNullOrEmpty()) {
                return teams.flatMap { it.playerNames }
            }
            return scores.map { it.playerName }
        }

    val playersDescription: String
        get() {
            val names = playerNamesList
            return when (names.size) {
                0 -> ""
                1 -> names[0]
                2 -> "${names[0]} & ${names[1]}"
                else -> {
                    val head = names.dropLast(1).joinToString(", ")
                    "$head & ${names.last()}"
                }
            }
        }

    val sessionTitle: String
        get() {
            val desc = playersDescription
            return if (desc.isEmpty()) "Spelsessie $gameName" else "Spelsessie $gameName met $desc"
        }

    val effectiveScoreProgression: List<RoundScoreDataPoint>
        get() {
            if (!scoreProgression.isNullOrEmpty()) {
                return scoreProgression
            }
            val points = mutableListOf<RoundScoreDataPoint>()
            for (s in scores) {
                points.add(RoundScoreDataPoint(round = 0, playerName = s.playerName, cumulativeScore = 0))
                points.add(RoundScoreDataPoint(round = 1, playerName = s.playerName, cumulativeScore = s.score))
            }
            return points
        }
}
