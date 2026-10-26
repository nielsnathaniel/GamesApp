package nl.nnbp.gamesapp.ui.screens.games.loveletter

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
import androidx.compose.ui.unit.sp
import nl.nnbp.gamesapp.data.ActiveGameManager
import nl.nnbp.gamesapp.data.PlayerScoreDetail
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.model.PlayerScore
import nl.nnbp.gamesapp.ui.components.AppCard
import nl.nnbp.gamesapp.ui.components.SavedPlayersQuickChips
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue

data class LoveLetterRoundLog(
    val round: Int,
    val winner: String,
    val reason: String
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LoveLetterScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }

    var isGameStarted by remember { mutableStateOf(false) }
    var selectedPlayerNames by remember { mutableStateOf(mutableListOf<String>()) }
    var targetTokens by remember { mutableIntStateOf(4) }

    var currentRound by remember { mutableIntStateOf(1) }
    var tokens by remember { mutableStateOf(mutableListOf<Int>()) }
    var roundLogs by remember { mutableStateOf(mutableListOf<LoveLetterRoundLog>()) }
    var showHistoryDialog by remember { mutableStateOf(false) }

    // Win dialog per ronde
    var roundWinnerCandidate by remember { mutableStateOf<String?>(null) }
    var winReason by remember { mutableStateOf("Enige overgebleven speler") }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(selectedPlayerNames.size) {
        targetTokens = when (selectedPlayerNames.size) {
            2 -> 7
            3 -> 5
            4 -> 4
            else -> 3
        }
    }

    if (isGameOver && winnerPlayer != null) {
        val playerScores = selectedPlayerNames.indices.map { i ->
            PlayerScore(
                playerName = selectedPlayerNames[i],
                score = tokens.getOrElse(i) { 0 },
                isWinner = selectedPlayerNames[i] == winnerPlayer
            )
        }
        WinnaarScreen(
            gameName = "Love Letter",
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
                title = { Text("Love Letter", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Terug")
                    }
                },
                actions = {
                    if (isGameStarted) {
                        TextButton(onClick = { showHistoryDialog = true }) {
                            Icon(Icons.Default.History, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Historie (${roundLogs.size})")
                        }
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
                                text = "Spelregels Love Letter ❤️",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Deductiekaartspel voor 2 tot 6 spelers. Verzamel tokens van affectie door rondes te winnen. Wie als eerste $targetTokens tokens verzamelt wint!",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                            )
                        }
                    }

                    item {
                        AppCard {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("Doel tokens:", fontWeight = FontWeight.SemiBold)
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    listOf(3, 4, 5, 7).forEach { t ->
                                        FilterChip(
                                            selected = targetTokens == t,
                                            onClick = { targetTokens = t },
                                            label = { Text("$t tokens") },
                                            shape = RoundedCornerShape(12.dp)
                                        )
                                    }
                                }
                            }
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
                        tokens = MutableList(selectedPlayerNames.size) { 0 }
                        isGameStarted = true
                    },
                    enabled = selectedPlayerNames.size >= 2,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text("Start Spel (Doel: $targetTokens tokens)", style = MaterialTheme.typography.titleMedium)
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
                    verticalArrangement = Arrangement.spacedBy(10.dp)
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
                                Column {
                                    Text("Ronde $currentRound", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
                                    Text("Eerste tot $targetTokens tokens wint", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                                }
                                val leadingIdx = selectedPlayerNames.indices.maxByOrNull { tokens.getOrElse(it) { 0 } }
                                if (leadingIdx != null) {
                                    Text(
                                        text = "Leider: ${selectedPlayerNames[leadingIdx]} (${tokens[leadingIdx]} ❤️)",
                                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold, color = PrimaryBlue)
                                    )
                                }
                            }
                        }
                    }

                    itemsIndexed(selectedPlayerNames) { index, playerName ->
                        val currentTokens = tokens.getOrElse(index) { 0 }

                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
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
                                    Text(
                                        text = "$currentTokens / $targetTokens tokens ❤️",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = if (currentTokens >= targetTokens - 1) AccentOrange else Color.Gray
                                    )
                                }

                                Button(
                                    onClick = { roundWinnerCandidate = playerName },
                                    shape = RoundedCornerShape(10.dp)
                                ) {
                                    Text("Wint Ronde 🏆")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    roundWinnerCandidate?.let { winnerName ->
        AlertDialog(
            onDismissRequest = { roundWinnerCandidate = null },
            title = { Text("$winnerName wint Ronde $currentRound! ❤️") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Selecteer reden van winst:")
                    listOf("Enige overgebleven speler", "Handen vergelijken (hoogste kaart)").forEach { reason ->
                        FilterChip(
                            selected = winReason == reason,
                            onClick = { winReason = reason },
                            label = { Text(reason) },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(10.dp)
                        )
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val winnerIdx = selectedPlayerNames.indexOf(winnerName)
                        val newTokens = tokens.toMutableList()
                        if (winnerIdx != -1) {
                            newTokens[winnerIdx] += 1
                        }
                        tokens = newTokens

                        val log = LoveLetterRoundLog(round = currentRound, winner = winnerName, reason = winReason)
                        val newLogs = roundLogs.toMutableList()
                        newLogs.add(log)
                        roundLogs = newLogs

                        roundWinnerCandidate = null

                        if (newTokens.any { it >= targetTokens }) {
                            winnerPlayer = winnerName
                            val detailed = selectedPlayerNames.indices.map { idx ->
                                PlayerScoreDetail(name = selectedPlayerNames[idx], score = newTokens[idx])
                            }
                            scoreManager.saveGame(
                                gameName = "Love Letter",
                                playerDetailedScores = detailed,
                                winnerName = winnerName
                            )
                            isGameOver = true
                        } else {
                            currentRound += 1
                        }
                    }
                ) {
                    Text("+1 Token & Volgende Ronde")
                }
            },
            dismissButton = {
                TextButton(onClick = { roundWinnerCandidate = null }) {
                    Text("Annuleren")
                }
            }
        )
    }

    if (showHistoryDialog) {
        AlertDialog(
            onDismissRequest = { showHistoryDialog = false },
            title = { Text("Historie Love Letter") },
            text = {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 300.dp)
                ) {
                    if (roundLogs.isEmpty()) {
                        item { Text("Nog geen rondes afgerond.") }
                    } else {
                        items(roundLogs.reversed()) { log ->
                            AppCard(modifier = Modifier.padding(vertical = 4.dp)) {
                                Text("Ronde ${log.round} gewonnen door ${log.winner} ❤️", fontWeight = FontWeight.Bold)
                                Text(log.reason, style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showHistoryDialog = false }) {
                    Text("Sluiten")
                }
            }
        )
    }
}
