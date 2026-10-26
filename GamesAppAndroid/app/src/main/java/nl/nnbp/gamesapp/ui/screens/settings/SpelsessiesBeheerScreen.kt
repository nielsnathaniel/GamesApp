package nl.nnbp.gamesapp.ui.screens.settings

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.model.GameType
import nl.nnbp.gamesapp.data.model.PlayedGame
import nl.nnbp.gamesapp.ui.components.AppCard
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SpelsessiesBeheerScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val games by scoreManager.playedGames.collectAsState()

    var selectedGameFilter by remember { mutableStateOf<String?>(null) }
    var sessionToDelete by remember { mutableStateOf<PlayedGame?>(null) }

    val filteredGames = remember(games, selectedGameFilter) {
        if (selectedGameFilter == null || selectedGameFilter == "Alle") {
            games.sortedByDescending { it.timestamp }
        } else {
            games.filter { scoreManager.matchesGameName(it.gameName, selectedGameFilter!!) }
                .sortedByDescending { it.timestamp }
        }
    }

    // Groepeer per dag (Vandaag, Gisteren, of Datum)
    val groupedGames = remember(filteredGames) {
        val calNow = Calendar.getInstance()
        val calYesterday = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, -1) }
        val dateFormat = SimpleDateFormat("EEEE d MMMM", Locale("nl", "NL"))

        val map = linkedMapOf<String, MutableList<PlayedGame>>()

        for (game in filteredGames) {
            val calGame = Calendar.getInstance().apply { timeInMillis = game.timestamp }
            val key = when {
                calGame.get(Calendar.YEAR) == calNow.get(Calendar.YEAR) &&
                        calGame.get(Calendar.DAY_OF_YEAR) == calNow.get(Calendar.DAY_OF_YEAR) -> "Vandaag"
                calGame.get(Calendar.YEAR) == calYesterday.get(Calendar.YEAR) &&
                        calGame.get(Calendar.DAY_OF_YEAR) == calYesterday.get(Calendar.DAY_OF_YEAR) -> "Gisteren"
                else -> dateFormat.format(Date(game.timestamp)).replaceFirstChar { it.uppercase() }
            }
            map.getOrPut(key) { mutableListOf() }.add(game)
        }
        map
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Spelsessies", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Terug")
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
            // Filter chips per spel
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    selected = selectedGameFilter == null || selectedGameFilter == "Alle",
                    onClick = { selectedGameFilter = "Alle" },
                    label = { Text("Alle (${games.size})") },
                    shape = RoundedCornerShape(16.dp)
                )

                GameType.entries.forEach { game ->
                    val count = games.count { scoreManager.matchesGameName(it.gameName, game.displayName) }
                    if (count > 0) {
                        FilterChip(
                            selected = selectedGameFilter == game.displayName,
                            onClick = { selectedGameFilter = game.displayName },
                            label = { Text("${game.displayName} ($count)") },
                            shape = RoundedCornerShape(16.dp)
                        )
                    }
                }
            }

            if (filteredGames.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Geen spelsessies gevonden.",
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    groupedGames.forEach { (dagTitel, dagGames) ->
                        item(key = dagTitel) {
                            SectionTitle(
                                title = dagTitel,
                                trailingText = "${dagGames.size} potjes"
                            )
                        }

                        items(dagGames, key = { it.id }) { game ->
                            AppCard {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            text = game.sessionTitle,
                                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                                        )
                                        Spacer(modifier = Modifier.height(2.dp))
                                        val timeStr = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(game.timestamp))
                                        Text(
                                            text = "$timeStr • Winnaar: ${if (game.winner.isEmpty()) "Gelijkspel" else game.winner}",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                        )
                                        Spacer(modifier = Modifier.height(4.dp))
                                        Text(
                                            text = game.scores.joinToString(", ") { "${it.playerName}: ${it.score}" },
                                            style = MaterialTheme.typography.bodySmall,
                                            color = PrimaryBlue
                                        )
                                    }

                                    IconButton(onClick = { sessionToDelete = game }) {
                                        Icon(
                                            Icons.Default.Delete,
                                            contentDescription = "Verwijderen",
                                            tint = MaterialTheme.colorScheme.error.copy(alpha = 0.7f),
                                            modifier = Modifier.size(20.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    sessionToDelete?.let { session ->
        AlertDialog(
            onDismissRequest = { sessionToDelete = null },
            title = { Text("Spelsessie verwijderen?") },
            text = { Text("Weet je zeker dat je ${session.sessionTitle} wilt verwijderen?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        scoreManager.deleteGame(session.id)
                        sessionToDelete = null
                    }
                ) {
                    Text("Verwijderen", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { sessionToDelete = null }) {
                    Text("Annuleren")
                }
            }
        )
    }
}
