package nl.nnbp.gamesapp.data.model

import kotlinx.serialization.Serializable
import kotlin.math.abs

val PresetTableColors: List<Long> = listOf(
    0xFF007AFFL, // Koningsblauw
    0xFFE53935L, // Vurig Rood
    0xFF43A047L, // Smaragdgroen
    0xFFFF9500L, // Oranje
    0xFFAF52DEL, // Koninklijk Paars
    0xFF00ACC1L, // Cyaan / Oceaan
    0xFFE91E63L, // Fuchsia Roze
    0xFFFFB300L, // Warm Geel / Amber
    0xFF3949ABL, // Diep Indigo
    0xFF00897BL, // Zeegroen / Teal
    0xFF8D6E63L, // Houtbruin
    0xFF546E7AL  // Donker Leisteen
)

val PresetAvatarEmojis: List<String> = listOf(
    "🦁", "🦊", "👑", "🎲", "🚀", "🧙‍♂️", "🎯", "⚡️",
    "🦄", "🦉", "🐯", "🐼", "🤖", "🏆", "🔥", "💎"
)

@Serializable
data class PlayerProfile(
    val name: String,
    val colorHex: Long = 0xFF007AFFL,
    val avatarEmoji: String? = null
) {
    companion object {
        fun defaultFor(name: String): PlayerProfile {
            val idx = abs(name.trim().lowercase().hashCode()) % PresetTableColors.size
            return PlayerProfile(
                name = name.trim(),
                colorHex = PresetTableColors[idx],
                avatarEmoji = null
            )
        }
    }
}

data class PlayerPassportData(
    val profile: PlayerProfile,
    val totalGames: Int,
    val totalWins: Int,
    val winRate: Double,
    val favoriteGame: Pair<String, Int>?, // Spelnaam, aantal keren gespeeld
    val bestGame: Pair<String, Double>?,  // Spelnaam, winpercentage
    val nemesis: Pair<String, Double>?,   // Aartsvijand naam, win% van nemesis tegen deze speler
    val bestPartner: PartnerSynergyStat?, // Beste teamgenoot
    val currentStreak: Int,
    val bestStreak: Int,
    val badges: List<PlayerBadge>
)
