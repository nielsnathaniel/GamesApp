package nl.nnbp.gamesapp.ui.screens.games.jatten

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import nl.nnbp.gamesapp.data.ActiveGameManager
import nl.nnbp.gamesapp.data.PlayerScoreDetail
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.model.PlayerScore
import nl.nnbp.gamesapp.ui.components.AppCard
import nl.nnbp.gamesapp.ui.components.SavedPlayersQuickChips
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.components.StartspelerKiezerDialog
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.RoyalPurple

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun JattenScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }

    var isGameStarted by remember { mutableStateOf(false) }
    var selectedPlayerNames by remember { mutableStateOf(mutableListOf<String>()) }
    var startPlayerIndex by remember { mutableIntStateOf(0) }
    var currentRound by remember { mutableIntStateOf(1) }
    var showStartspelerDialog by remember { mutableStateOf(false) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }
    var showSixSameConfirm by remember { mutableStateOf<String?>(null) }

    val currentStarterIndex = remember(startPlayerIndex, currentRound, selectedPlayerNames) {
        if (selectedPlayerNames.isEmpty()) 0 else (startPlayerIndex + (currentRound - 1)) % selectedPlayerNames.size
    }

    if (isGameOver && winnerPlayer != null) {
        val playerScores = selectedPlayerNames.map { name ->
            PlayerScore(
                playerName = name,
                score = if (name == winnerPlayer) 1 else 0,
                isWinner = name == winnerPlayer
            )
        }
        WinnaarScreen(
            gameName = "Jatten",
            winnerName = winnerPlayer!!,
            scores = playerScores,
            onFinish = {
                activeGameManager.clearActiveGame()
                onNavigateBack()
            }
        )
        return
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Jatten", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Terug")
                    }
                }
            )
        }
    ) { padding ->
        if (!isGameStarted) {
            // SETUP
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(16.dp),
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    item {
                        AppCard {
                            Text(
                                text = "Spelregels Jatten 🦝",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Kaartspel met push-your-luck. Steel kaarten van elkaar. Zodra een speler als eerste 6 dezelfde kaarten in bezit heeft, wint diegene direct!",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                            )
                        }
                    }

                    item {
                        SavedPlayersQuickChips(
                            selectedPlayers = selectedPlayerNames,
                            onTogglePlayer = { name ->
                                val list = selectedPlayerNames.toMutableList()
                                if (list.contains(name)) list.remove(name) else list.add(name)
                                selectedPlayerNames = list
                            }
                        )
                    }

                    item {
                        SectionTitle(title = "Spelers (${selectedPlayerNames.size})")
                        if (selectedPlayerNames.isEmpty()) {
                            Text(
                                text = "Selecteer minimaal 2 spelers.",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                            )
                        } else {
                            AppCard {
                                selectedPlayerNames.forEachIndexed { idx, name ->
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(vertical = 4.dp),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text("${idx + 1}. $name", fontWeight = FontWeight.SemiBold)
                                        IconButton(onClick = {
                                            val list = selectedPlayerNames.toMutableList()
                                            list.removeAt(idx)
                                            selectedPlayerNames = list
                                        }) {
                                            Icon(Icons.Default.Close, contentDescription = null, tint = Color.Gray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Button(
                    onClick = {
                        startPlayerIndex = if (selectedPlayerNames.isNotEmpty()) (0 until selectedPlayerNames.size).random() else 0
                        isGameStarted = true
                    },
                    enabled = selectedPlayerNames.size >= 2,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text("Start Spel", style = MaterialTheme.typography.titleMedium)
                }
            }
        } else {
            // GAMEPLAY
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(14.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Default.PanTool, contentDescription = null, tint = RoyalPurple)
                                    Spacer(modifier = Modifier.width(10.dp))
                                    Column {
                                        Text("Aan de beurt om te jatten:", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                        Text(
                                            text = selectedPlayerNames.getOrElse(currentStarterIndex) { "" },
                                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                                        )
                                    }
                                }

                                TextButton(
                                    onClick = {
                                        currentRound += 1
                                    }
                                ) {
                                    Text("Volgende beurt ➡️")
                                }
                            }
                        }
                    }

                    itemsIndexed(selectedPlayerNames) { index, playerName ->
                        val isStarter = index == currentStarterIndex

                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = if (isStarter) RoyalPurple.copy(alpha = 0.08f) else MaterialTheme.colorScheme.surfaceVariant
                            )
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(14.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Text(playerName, style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
                                    if (isStarter) {
                                        Text("Aan de beurt", style = MaterialTheme.typography.labelSmall, color = RoyalPurple)
                                    }
                                }

                                Button(
                                    onClick = {
                                        showSixSameConfirm = playerName
                                    },
                                    colors = ButtonDefaults.buttonColors(containerColor = AccentOrange),
                                    shape = RoundedCornerShape(10.dp)
                                ) {
                                    Text("🏆 6 dezelfde!", fontWeight = FontWeight.Bold)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    showSixSameConfirm?.let { candidate ->
        AlertDialog(
            onDismissRequest = { showSixSameConfirm = null },
            title = { Text("6 dezelfde kaarten! 🎉") },
            text = { Text("Heeft $candidate inderdaad 6 dezelfde kaarten verzameld en wint daarmee het spel?") },
            confirmButton = {
                Button(
                    onClick = {
                        winnerPlayer = candidate
                        val detailed = selectedPlayerNames.map { name ->
                            PlayerScoreDetail(name = name, score = if (name == candidate) 1 else 0)
                        }
                        scoreManager.saveGame(
                            gameName = "Jatten",
                            playerDetailedScores = detailed,
                            winnerName = candidate
                        )
                        showSixSameConfirm = null
                        isGameOver = true
                    }
                ) {
                    Text("Ja, $candidate Wint!")
                }
            },
            dismissButton = {
                TextButton(onClick = { showSixSameConfirm = null }) {
                    Text("Nee, nog niet")
                }
            }
        )
    }

    if (showStartspelerDialog) {
        StartspelerKiezerDialog(
            players = selectedPlayerNames,
            onDismiss = { showStartspelerDialog = false },
            onStartspelerChosen = { chosen ->
                val idx = selectedPlayerNames.indexOf(chosen)
                if (idx != -1) startPlayerIndex = idx
                showStartspelerDialog = false
            }
        )
    }
}
