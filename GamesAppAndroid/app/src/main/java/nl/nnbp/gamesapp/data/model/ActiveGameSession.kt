package nl.nnbp.gamesapp.data.model

import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class ActiveGameSession(
    val id: String = UUID.randomUUID().toString(),
    val gameName: String,
    val timestamp: Long = System.currentTimeMillis(),
    val playerNames: List<String>,
    val currentRound: Int,
    val summary: String,
    val stateData: Map<String, String> = emptyMap()
)
