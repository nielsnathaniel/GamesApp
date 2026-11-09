package nl.nnbp.gamesapp

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.*
import androidx.navigation.navArgument
import nl.nnbp.gamesapp.data.model.GameType
import nl.nnbp.gamesapp.ui.navigation.Screen
import nl.nnbp.gamesapp.ui.screens.games.GamesOverviewScreen
import nl.nnbp.gamesapp.ui.screens.games.balzakken.BalzakkenScreen
import nl.nnbp.gamesapp.ui.screens.games.beverbende.BeverbendeScreen
import nl.nnbp.gamesapp.ui.screens.games.cranium.CraniumScreen
import nl.nnbp.gamesapp.ui.screens.games.crockinole.CrockinoleScreen
import nl.nnbp.gamesapp.ui.screens.games.duizenden.DuizendenScreen
import nl.nnbp.gamesapp.ui.screens.games.fiftyfifty.FiftyFiftyScreen
import nl.nnbp.gamesapp.ui.screens.games.risk.RiskScreen
import nl.nnbp.gamesapp.ui.screens.games.jatten.JattenScreen
import nl.nnbp.gamesapp.ui.screens.games.loveletter.LoveLetterScreen
import nl.nnbp.gamesapp.ui.screens.games.nmbr9.Nmbr9Screen
import nl.nnbp.gamesapp.ui.screens.games.pighole.PigHoleScreen
import nl.nnbp.gamesapp.ui.screens.games.quickstop.QuickstopScreen
import nl.nnbp.gamesapp.ui.screens.games.qwixx.QwixxScreen
import nl.nnbp.gamesapp.ui.screens.games.regenwormen.RegenwormenScreen
import nl.nnbp.gamesapp.ui.screens.games.thirtyseconds.ThirtySecondsScreen
import nl.nnbp.gamesapp.ui.screens.games.tickettoride.TicketToRideScreen
import nl.nnbp.gamesapp.ui.screens.settings.CloudSyncScreen
import nl.nnbp.gamesapp.ui.screens.settings.GegevensbeheerScreen
import nl.nnbp.gamesapp.ui.screens.settings.OpgeslagenSpelersScreen
import nl.nnbp.gamesapp.ui.screens.settings.SettingsScreen
import nl.nnbp.gamesapp.ui.screens.settings.SpelsessiesBeheerScreen
import nl.nnbp.gamesapp.ui.screens.statistics.StatisticsScreen
import nl.nnbp.gamesapp.ui.theme.GamesAppTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val scoreManager = remember { nl.nnbp.gamesapp.data.ScoreManager.getInstance(applicationContext) }
            val themeMode by scoreManager.themeMode.collectAsState()
            val isDark = when (themeMode) {
                "LIGHT" -> false
                "SYSTEM" -> androidx.compose.foundation.isSystemInDarkTheme()
                else -> true
            }

            GamesAppTheme(darkTheme = isDark) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    GamesAppMainShell()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        nl.nnbp.gamesapp.data.CloudSyncManager.getInstance(applicationContext).syncNowIfNeeded()
    }
}

@Composable
fun GamesAppMainShell() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    val isTopLevelRoute = currentRoute in listOf(
        Screen.Games.route,
        Screen.Statistics.route,
        Screen.Settings.route
    )

    Scaffold(
        bottomBar = {
            if (isTopLevelRoute) {
                NavigationBar {
                    Screen.bottomNavItems.filterNotNull().forEach { screen ->
                        NavigationBarItem(
                            icon = { screen.icon?.let { Icon(it, contentDescription = screen.title) } },
                            label = { Text(screen.title) },
                            selected = currentRoute == screen.route,
                            onClick = {
                                navController.navigate(screen.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Games.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.Games.route) {
                GamesOverviewScreen(
                    onGameSelected = { game ->
                        navController.navigate(Screen.GameSetup.createRoute(game.id, resume = false))
                    },
                    onResumeActiveGame = { gameId ->
                        navController.navigate(Screen.GameSetup.createRoute(gameId, resume = true))
                    }
                )
            }

            composable(Screen.Statistics.route) {
                StatisticsScreen(
                    onNavigateToSessions = {
                        navController.navigate(Screen.SpelsessiesBeheer.route)
                    }
                )
            }

            composable(Screen.Settings.route) {
                SettingsScreen(
                    onNavigateToPlayers = {
                        navController.navigate(Screen.OpgeslagenSpelers.route)
                    },
                    onNavigateToSessions = {
                        navController.navigate(Screen.SpelsessiesBeheer.route)
                    },
                    onNavigateToDataManagement = {
                        navController.navigate(Screen.Gegevensbeheer.route)
                    },
                    onNavigateToCloudSync = {
                        navController.navigate(Screen.CloudSync.route)
                    }
                )
            }

            composable(Screen.Gegevensbeheer.route) {
                GegevensbeheerScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToPlayers = { navController.navigate(Screen.OpgeslagenSpelers.route) },
                    onNavigateToSessions = { navController.navigate(Screen.SpelsessiesBeheer.route) },
                    onNavigateToCloudSync = { navController.navigate(Screen.CloudSync.route) }
                )
            }

            composable(Screen.CloudSync.route) {
                CloudSyncScreen(
                    onNavigateBack = { navController.popBackStack() }
                )
            }

            composable(Screen.OpgeslagenSpelers.route) {
                OpgeslagenSpelersScreen(
                    onNavigateBack = { navController.popBackStack() }
                )
            }

            composable(Screen.SpelsessiesBeheer.route) {
                SpelsessiesBeheerScreen(
                    onNavigateBack = { navController.popBackStack() }
                )
            }

            // Route handler voor elk van de 16 spellen
            composable(
                route = Screen.GameSetup.route,
                arguments = listOf(
                    navArgument("gameId") { type = NavType.StringType },
                    navArgument("resume") {
                        type = NavType.BoolType
                        defaultValue = false
                    }
                )
            ) { backStackEntry ->
                val gameId = backStackEntry.arguments?.getString("gameId") ?: ""
                val resume = backStackEntry.arguments?.getBoolean("resume") ?: false
                val gameType = GameType.fromId(gameId) ?: GameType.BALZAKKEN

                when (gameType) {
                    GameType.BALZAKKEN -> BalzakkenScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.BEVERBENDE -> BeverbendeScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.DUIZENDEN -> DuizendenScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.CROCKINOLE -> CrockinoleScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.NMBR9 -> Nmbr9Screen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.REGENWORMEN -> RegenwormenScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.JATTEN -> JattenScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.LOVE_LETTER -> LoveLetterScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.QWIXX -> QwixxScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.PIG_HOLE -> PigHoleScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.TICKET_TO_RIDE -> TicketToRideScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.QUICKSTOP -> QuickstopScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.THIRTY_SECONDS -> ThirtySecondsScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.CRANIUM -> CraniumScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.FIFTY_FIFTY -> FiftyFiftyScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                    GameType.RISK -> RiskScreen(onNavigateBack = { navController.popBackStack() }, autoResume = resume)
                }
            }
        }
    }
}
