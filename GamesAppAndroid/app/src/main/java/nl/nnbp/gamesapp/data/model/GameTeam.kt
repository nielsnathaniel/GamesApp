package nl.nnbp.gamesapp.data.model

import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class GameTeam(
    val id: String = UUID.randomUUID().toString(),
    val teamName: String,
    val playerNames: List<String>,
    val score: Int,
    val isWinner: Boolean = false
)
