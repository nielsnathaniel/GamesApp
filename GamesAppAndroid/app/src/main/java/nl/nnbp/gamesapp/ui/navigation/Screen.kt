package nl.nnbp.gamesapp.ui.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Casino
import androidx.compose.material.icons.filled.Leaderboard
import androidx.compose.material.icons.filled.Settings
import androidx.compose.ui.graphics.vector.ImageVector

sealed class Screen(val route: String, val title: String, val icon: ImageVector? = null) {
    object Games : Screen("games", "Spellen", Icons.Default.Casino)
    object Statistics : Screen("statistics", "Statistieken", Icons.Default.Leaderboard)
    object Settings : Screen("settings", "Instellingen", Icons.Default.Settings)

    object OpgeslagenSpelers : Screen("saved_players", "Opgeslagen Spelers")
    object SpelsessiesBeheer : Screen("sessions_manager", "Spelsessies")
    object Gegevensbeheer : Screen("data_management", "Gegevensbeheer")
    object CloudSync : Screen("cloud_sync", "Cloud Synchronisatie")
    object GameSetup : Screen("game_setup/{gameId}?resume={resume}", "Spel Instellen") {
        fun createRoute(gameId: String, resume: Boolean = false) = "game_setup/$gameId?resume=$resume"
    }
    object ActiveGame : Screen("active_game/{gameId}", "Spelsessie") {
        fun createRoute(gameId: String) = "active_game/$gameId"
    }
    object Winner : Screen("winner/{gameName}/{winnerName}", "Winnaar") {
        fun createRoute(gameName: String, winnerName: String) = "winner/$gameName/$winnerName"
    }

    companion object {
        val bottomNavItems: List<Screen>
            get() = listOf(Games, Statistics, Settings)
    }
}
