package nl.nnbp.gamesapp.ui.screens.games

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import nl.nnbp.gamesapp.data.ActiveGameManager
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.model.GameSortOption
import nl.nnbp.gamesapp.data.model.GameType
import nl.nnbp.gamesapp.data.model.Player
import nl.nnbp.gamesapp.ui.components.TafelschikkingDialog
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.RoyalPurple

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GamesOverviewScreen(
    onGameSelected: (GameType) -> Unit,
    onResumeActiveGame: (String) -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }

    val playedGames by scoreManager.playedGames.collectAsState()
    val activeSession by activeGameManager.activeSession.collectAsState()

    var sortOption by remember { mutableStateOf(GameSortOption.TOEGEVOEGD) }
    var showSortMenu by remember { mutableStateOf(false) }
    var showDiscardDraftDialog by remember { mutableStateOf(false) }
    var showTafelschikkingDialog by remember { mutableStateOf(false) }
    val savedPlayerNames by scoreManager.savedPlayerNames.collectAsState()

    val sortedGames = remember(sortOption, playedGames) {
        when (sortOption) {
            GameSortOption.POPULAIR -> {
                val counts = scoreManager.mostPlayedGames().toMap()
                GameType.entries.sortedByDescending { counts[it.displayName] ?: 0 }
            }
            GameSortOption.ALFABETISCH -> {
                GameType.entries.sortedBy { it.displayName }
            }
            GameSortOption.TOEGEVOEGD -> {
                GameType.entries
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Spellen",
                        style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold)
                    )
                },
                actions = {
                    Box {
                        IconButton(onClick = { showSortMenu = true }) {
                            Icon(
                                imageVector = Icons.Default.FilterList,
                                contentDescription = "Sorteer spellen",
                                tint = if (sortOption != GameSortOption.TOEGEVOEGD) AccentOrange else MaterialTheme.colorScheme.onSurface
                            )
                        }
                        DropdownMenu(
                            expanded = showSortMenu,
                            onDismissRequest = { showSortMenu = false }
                        ) {
                            GameSortOption.entries.forEach { option ->
                                DropdownMenuItem(
                                    text = { Text(option.title) },
                                    onClick = {
                                        sortOption = option
                                        showSortMenu = false
                                    },
                                    leadingIcon = {
                                        when (option) {
                                            GameSortOption.POPULAIR -> Icon(Icons.Default.Whatshot, null, tint = AccentOrange)
                                            GameSortOption.TOEGEVOEGD -> Icon(Icons.Default.Schedule, null, tint = PrimaryBlue)
                                            GameSortOption.ALFABETISCH -> Icon(Icons.Default.SortByAlpha, null, tint = RoyalPurple)
                                        }
                                    },
                                    trailingIcon = {
                                        if (sortOption == option) {
                                            Icon(Icons.Default.Check, null, tint = PrimaryBlue)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Actieve sessie banner (als er een concept/actief spel is)
            activeSession?.let { session ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = PrimaryBlue.copy(alpha = 0.12f))
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(8.dp)
                                        .clip(CircleShape)
                                        .background(PrimaryBlue)
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = "Lopend potje: ${session.gameName}",
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                    color = PrimaryBlue
                                )
                            }
                            Text(
                                text = "Ronde ${session.currentRound} • ${session.playerNames.joinToString(", ")}",
                                style = MaterialTheme.typography.bodySmall,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }

                        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                            IconButton(onClick = { showDiscardDraftDialog = true }) {
                                Icon(Icons.Default.Close, contentDescription = "Verwijderen", tint = MaterialTheme.colorScheme.error)
                            }
                            Button(
                                onClick = { onResumeActiveGame(session.gameName) },
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                            ) {
                                Text("Hervat")
                            }
                        }
                    }
                }
            }

            // Tafelschikking Assistent Teaser Card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 6.dp)
                    .clickable { showTafelschikkingDialog = true },
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .background(AccentOrange.copy(alpha = 0.15f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text("🎲", fontSize = 22.sp)
                        }
                        Column {
                            Text(
                                text = "Tafelschikking Assistent",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Text(
                                text = "Wie zit waar? Draai & bepaal startspeler",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                            )
                        }
                    }
                    Icon(
                        imageVector = Icons.Default.ChevronRight,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    )
                }
            }

            // Grid met spellen
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                contentPadding = PaddingValues(16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxSize()
            ) {
                items(sortedGames) { game ->
                    val playCount = playedGames.count { scoreManager.matchesGameName(it.gameName, game.displayName) }
                    GameGridCard(
                        game = game,
                        playCount = playCount,
                        onClick = { onGameSelected(game) }
                    )
                }
            }
        }
    }

    if (showDiscardDraftDialog) {
        AlertDialog(
            onDismissRequest = { showDiscardDraftDialog = false },
            title = { Text("Lopend spel verwijderen?") },
            text = { Text("Weet je zeker dat je het opgeslagen lopende spel wilt wissen?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        activeGameManager.clearActiveGame()
                        showDiscardDraftDialog = false
                    }
                ) {
                    Text("Wissen", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDiscardDraftDialog = false }) {
                    Text("Annuleren")
                }
            }
        )
    }

    if (showTafelschikkingDialog) {
        val players = if (savedPlayerNames.isNotEmpty()) {
            savedPlayerNames.map { name ->
                val prof = scoreManager.getPlayerProfile(name)
                Player(name = name, colorHex = prof.colorHex, avatarEmoji = prof.avatarEmoji)
            }
        } else {
            listOf("Speler 1", "Speler 2", "Speler 3", "Speler 4").map { name ->
                val prof = scoreManager.getPlayerProfile(name)
                Player(name = name, colorHex = prof.colorHex, avatarEmoji = prof.avatarEmoji)
            }
        }
        TafelschikkingDialog(
            players = players,
            onDismiss = { showTafelschikkingDialog = false },
            onApplyOrder = { /* Ordered applied */ }
        )
    }
}

@Composable
fun GameGridCard(
    game: GameType,
    playCount: Int,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(180.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(14.dp)
        ) {
            Column(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Top
                ) {
                    Box(
                        modifier = Modifier
                            .size(46.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(PrimaryBlue.copy(alpha = 0.12f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = when (game) {
                                GameType.BALZAKKEN -> Icons.Default.SportsBaseball
                                GameType.TICKET_TO_RIDE -> Icons.Default.DirectionsTransit
                                GameType.THIRTY_SECONDS -> Icons.Default.Timer
                                GameType.CRANIUM -> Icons.Default.Psychology
                                GameType.QWIXX -> Icons.Default.Casino
                                GameType.LOVE_LETTER -> Icons.Default.Favorite
                                GameType.REGENWORMEN -> Icons.Default.BugReport
                                GameType.JATTEN -> Icons.Default.PanTool
                                GameType.BEVERBENDE -> Icons.Default.Pets
                                GameType.PIG_HOLE -> Icons.Default.Savings
                                GameType.QUICKSTOP -> Icons.Default.FlashOn
                                else -> Icons.Default.Extension
                            },
                            contentDescription = null,
                            tint = PrimaryBlue,
                            modifier = Modifier.size(26.dp)
                        )
                    }

                    if (playCount > 0) {
                        Surface(
                            shape = RoundedCornerShape(10.dp),
                            color = AccentOrange.copy(alpha = 0.15f)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "🔥 ${playCount}x",
                                    style = MaterialTheme.typography.labelSmall.copy(
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = AccentOrange
                                    )
                                )
                            }
                        }
                    }
                }

                Column {
                    Text(
                        text = game.displayName,
                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = "${game.minPlayers}-${game.maxPlayers} spelers",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = if (game.isLowestScoreWins) "Minste punten wint" else "Hoogste score wint",
                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                        color = if (game.isLowestScoreWins) AccentOrange else PrimaryBlue
                    )
                }
            }
        }
    }
}
