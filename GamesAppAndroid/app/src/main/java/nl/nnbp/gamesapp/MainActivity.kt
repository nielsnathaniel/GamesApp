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
import androidx.navigation.compose.*
import nl.nnbp.gamesapp.data.model.GameType
import nl.nnbp.gamesapp.ui.navigation.Screen
import nl.nnbp.gamesapp.ui.screens.games.GamesOverviewScreen
import nl.nnbp.gamesapp.ui.screens.games.balzakken.BalzakkenScreen
import nl.nnbp.gamesapp.ui.screens.games.beverbende.BeverbendeScreen
import nl.nnbp.gamesapp.ui.screens.games.cranium.CraniumScreen
import nl.nnbp.gamesapp.ui.screens.games.crockinole.CrockinoleScreen
import nl.nnbp.gamesapp.ui.screens.games.duizenden.DuizendenScreen
import nl.nnbp.gamesapp.ui.screens.games.fiftyfifty.FiftyFiftyScreen
import nl.nnbp.gamesapp.ui.screens.games.jatten.JattenScreen
import nl.nnbp.gamesapp.ui.screens.games.loveletter.LoveLetterScreen
import nl.nnbp.gamesapp.ui.screens.games.nmbr9.Nmbr9Screen
import nl.nnbp.gamesapp.ui.screens.games.pighole.PigHoleScreen
import nl.nnbp.gamesapp.ui.screens.games.quickstop.QuickstopScreen
import nl.nnbp.gamesapp.ui.screens.games.qwixx.QwixxScreen
import nl.nnbp.gamesapp.ui.screens.games.regenwormen.RegenwormenScreen
import nl.nnbp.gamesapp.ui.screens.games.thirtyseconds.ThirtySecondsScreen
import nl.nnbp.gamesapp.ui.screens.games.tickettoride.TicketToRideScreen
import nl.nnbp.gamesapp.ui.screens.settings.OpgeslagenSpelersScreen
import nl.nnbp.gamesapp.ui.screens.settings.SettingsScreen
import nl.nnbp.gamesapp.ui.screens.settings.SpelsessiesBeheerScreen
import nl.nnbp.gamesapp.ui.screens.statistics.StatisticsScreen
import nl.nnbp.gamesapp.ui.theme.GamesAppTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val scoreManager = remember { nl.nnbp.gamesapp.data.ScoreManager.getInstance() }
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
                    Screen.bottomNavItems.forEach { screen ->
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
                        navController.navigate(Screen.GameSetup.createRoute(game.id))
                    },
                    onResumeActiveGame = { gameId ->
                        navController.navigate(Screen.GameSetup.createRoute(gameId))
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
                    }
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

            // Route handler voor elk van de 15 spellen
            composable(Screen.GameSetup.route) { backStackEntry ->
                val gameId = backStackEntry.arguments?.getString("gameId") ?: ""
                val gameType = GameType.fromId(gameId) ?: GameType.BALZAKKEN

                when (gameType) {
                    GameType.BALZAKKEN -> BalzakkenScreen(onNavigateBack = { navController.popBackStack() })
                    GameType.BEVERBENDE -> BeverbendeScreen(onNavigateBack = { navController.popBackStack() })
                    GameType.DUIZENDEN -> DuizendenScreen(onNavigateBack = { navController.popBackStack() })
                    GameType.CROCKINOLE -> CrockinoleScreen(onNavigateBack = { navController.popBackStack() })
                    GameType.NMBR9 -> Nmbr9Screen(onNavigateBack = { navController.popBackStack() })
                    GameType.REGENWORMEN -> RegenwormenScreen(onNavigateBack = { navController.popBackStack() })
                    GameType.JATTEN -> JattenScreen(onNavigateBack = { navController.popBackStack() })
                    GameType.LOVE_LETTER -> LoveLetterScreen(onNavigateBack = { navController.popBackStack() })
                    GameType.QWIXX -> QwixxScreen(onNavigateBack = { navController.popBackStack() })
                    GameType.PIG_HOLE -> PigHoleScreen(onNavigateBack = { navController.popBackStack() })
                    GameType.TICKET_TO_RIDE -> TicketToRideScreen(onNavigateBack = { navController.popBackStack() })
                    GameType.QUICKSTOP -> QuickstopScreen(onNavigateBack = { navController.popBackStack() })
                    GameType.THIRTY_SECONDS -> ThirtySecondsScreen(onNavigateBack = { navController.popBackStack() })
                    GameType.CRANIUM -> CraniumScreen(onNavigateBack = { navController.popBackStack() })
                    GameType.FIFTY_FIFTY -> FiftyFiftyScreen(onNavigateBack = { navController.popBackStack() })
                }
            }
        }
    }
}
