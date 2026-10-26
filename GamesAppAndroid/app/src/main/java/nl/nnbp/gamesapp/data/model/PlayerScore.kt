package nl.nnbp.gamesapp.data.model

import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class PlayerScore(
    val id: String = UUID.randomUUID().toString(),
    val playerName: String,
    val score: Int,
    val isWinner: Boolean = false,
    val juisteBalzakken: Int = 0,
    val fouteBalzakken: Int = 0
)
