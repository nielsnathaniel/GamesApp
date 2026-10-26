package nl.nnbp.gamesapp.ui.screens.games.duizenden

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
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
import nl.nnbp.gamesapp.data.model.Player
import nl.nnbp.gamesapp.data.model.PlayerScore
import nl.nnbp.gamesapp.ui.components.AppCard
import nl.nnbp.gamesapp.ui.components.InhaalslagBanner
import nl.nnbp.gamesapp.ui.components.NumericScoreStepper
import nl.nnbp.gamesapp.ui.components.PuntenWijzigenDialog
import nl.nnbp.gamesapp.ui.components.SavedPlayersQuickChips
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.components.TafelschikkingDialog
import nl.nnbp.gamesapp.ui.components.WieHeeftGelijkDialog
import nl.nnbp.gamesapp.ui.screens.games.SnelleEindscoreScreen
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue

data class DuizendenRoundEntry(
    val round: Int,
    val roundScores: List<Int>,
    val totals: List<Int>
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DuizendenScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }

    var isGameStarted by remember { mutableStateOf(false) }
    var selectedPlayerNames by remember { mutableStateOf(mutableListOf<String>()) }
    var targetScore by remember { mutableIntStateOf(1000) }

    var currentRound by remember { mutableIntStateOf(1) }
    var roundScores by remember { mutableStateOf(mutableListOf<Int>()) }
    var totalScores by remember { mutableStateOf(mutableListOf<Int>()) }
    var expandedPlayerIndex by remember { mutableStateOf<Int?>(null) }
    var history by remember { mutableStateOf(mutableListOf<DuizendenRoundEntry>()) }
    var showHistorySheet by remember { mutableStateOf(false) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }
    var showTafelschikkingDialog by remember { mutableStateOf(false) }
    var showDisputeDialog by remember { mutableStateOf(false) }
    var showEditScoresDialog by remember { mutableStateOf(false) }
    var isQuickScoreMode by remember { mutableStateOf(false) }
    var startQuickScoreGame by remember { mutableStateOf(false) }

    if (startQuickScoreGame) {
        SnelleEindscoreScreen(
            gameName = "Duizenden",
            playerNames = selectedPlayerNames,
            isLowestScoreWins = false,
            scoreUnit = "pt",
            onNavigateBack = { startQuickScoreGame = false }
        )
        return
    }

    if (isGameOver && winnerPlayer != null) {
        val playerScores = selectedPlayerNames.indices.map { i ->
            PlayerScore(
                playerName = selectedPlayerNames[i],
                score = totalScores.getOrElse(i) { 0 },
                isWinner = selectedPlayerNames[i] == winnerPlayer
            )
        }
        WinnaarScreen(
            gameName = "Duizenden",
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
                title = { Text("Duizenden", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Terug")
                    }
                },
                actions = {
                    if (isGameStarted) {
                        IconButton(onClick = { showEditScoresDialog = true }) {
                            Icon(Icons.Default.Edit, contentDescription = "Punten wijzigen", tint = AccentOrange)
                        }
                        TextButton(onClick = { showHistorySheet = true }) {
                            Icon(Icons.Default.History, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Historie (${history.size})")
                        }
                    }
                    IconButton(onClick = { showDisputeDialog = true }) {
                        Text("⚖️", fontSize = 18.sp)
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
                                text = "Spelregels Duizenden 🃏",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Klassiek kaartspel met melds, slagen en minpunten. Wie als eerste het doel (bijv. 1000 pt) bereikt wint!",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                            )
                        }
                    }

                    item {
                        AppCard {
                            Text("Spelmodus:", fontWeight = FontWeight.SemiBold)
                            Spacer(modifier = Modifier.height(8.dp))
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                FilterChip(
                                    selected = !isQuickScoreMode,
                                    onClick = { isQuickScoreMode = false },
                                    label = { Text("Rondes bijhouden") },
                                    modifier = Modifier.weight(1f)
                                )
                                FilterChip(
                                    selected = isQuickScoreMode,
                                    onClick = { isQuickScoreMode = true },
                                    label = { Text("⚡️ Alleen eindscore") },
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }
                    }

                    if (!isQuickScoreMode) {
                        item {
                            AppCard {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("Doelscore:", fontWeight = FontWeight.SemiBold)
                                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                        listOf(500, 1000, 1500).forEach { pts ->
                                            FilterChip(
                                                selected = targetScore == pts,
                                                onClick = { targetScore = pts },
                                                label = { Text("$pts pt") },
                                                shape = RoundedCornerShape(12.dp)
                                            )
                                        }
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
                                text = "Voeg minimaal 2 spelers toe.",
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

                if (selectedPlayerNames.size >= 2) {
                    OutlinedButton(
                        onClick = { showTafelschikkingDialog = true },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(48.dp),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Tafelschikking (Wie zit waar?)")
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                }

                Button(
                    onClick = {
                        if (isQuickScoreMode) {
                            startQuickScoreGame = true
                        } else {
                            roundScores = MutableList(selectedPlayerNames.size) { 0 }
                            totalScores = MutableList(selectedPlayerNames.size) { 0 }
                            isGameStarted = true
                        }
                    },
                    enabled = selectedPlayerNames.size >= 2,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text(
                        if (isQuickScoreMode) "Start Snelle Eindscore" else "Start Spel (Doel: $targetScore pt)",
                        style = MaterialTheme.typography.titleMedium
                    )
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
                        InhaalslagBanner(
                            playerNames = selectedPlayerNames,
                            scores = totalScores,
                            lowestWins = false
                        )
                    }

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
                                    Text("Doel: $targetScore punten", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                                }
                                val leadingPlayer = selectedPlayerNames.indices.maxByOrNull { totalScores.getOrElse(it) { 0 } }
                                if (leadingPlayer != null) {
                                    Surface(
                                        shape = RoundedCornerShape(8.dp),
                                        color = PrimaryBlue.copy(alpha = 0.12f)
                                    ) {
                                        Text(
                                            text = "Leider: ${selectedPlayerNames[leadingPlayer]} (${totalScores[leadingPlayer]})",
                                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold, color = PrimaryBlue),
                                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }

                    itemsIndexed(selectedPlayerNames) { index, playerName ->
                        val isExpanded = expandedPlayerIndex == index
                        val currentRoundScore = roundScores.getOrElse(index) { 0 }
                        val currentTotal = totalScores.getOrElse(index) { 0 }

                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    expandedPlayerIndex = if (isExpanded) null else index
                                },
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Column(modifier = Modifier.padding(14.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column {
                                        Text(playerName, style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
                                        Text(
                                            text = "Totaal: $currentTotal / $targetScore pt",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = if (currentTotal >= targetScore) PrimaryBlue else Color.Gray
                                        )
                                    }

                                    Column(horizontalAlignment = Alignment.End) {
                                        Text(
                                            text = "${if (currentRoundScore >= 0) "+" else ""}$currentRoundScore",
                                            style = MaterialTheme.typography.headlineSmall.copy(
                                                fontWeight = FontWeight.Bold,
                                                color = if (currentRoundScore >= 0) PrimaryBlue else AccentOrange
                                            )
                                        )
                                        Text("deze ronde", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                    }
                                }

                                AnimatedVisibility(visible = isExpanded) {
                                    Column(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(top = 12.dp),
                                        horizontalAlignment = Alignment.CenterHorizontally
                                    ) {
                                        HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))
                                        Spacer(modifier = Modifier.height(10.dp))

                                        Text(
                                            text = "Score invoer deze ronde (Tafel + Slagen - Hand):",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = Color.Gray
                                        )
                                        Spacer(modifier = Modifier.height(8.dp))

                                        NumericScoreStepper(
                                            score = currentRoundScore,
                                            onScoreChange = { newScore ->
                                                val list = roundScores.toMutableList()
                                                list[index] = newScore
                                                roundScores = list
                                            },
                                            enableLargeStep = true
                                        )

                                        Spacer(modifier = Modifier.height(8.dp))

                                        // Snelle preset buttons (+20, +50, +100, -50)
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                                        ) {
                                            FilledTonalButton(
                                                onClick = {
                                                    val list = roundScores.toMutableList()
                                                    list[index] += 20
                                                    roundScores = list
                                                },
                                                modifier = Modifier.weight(1f),
                                                shape = RoundedCornerShape(8.dp)
                                            ) {
                                                Text("+20", fontSize = 12.sp)
                                            }

                                            FilledTonalButton(
                                                onClick = {
                                                    val list = roundScores.toMutableList()
                                                    list[index] += 50
                                                    roundScores = list
                                                },
                                                modifier = Modifier.weight(1f),
                                                shape = RoundedCornerShape(8.dp)
                                            ) {
                                                Text("+50", fontSize = 12.sp)
                                            }

                                            FilledTonalButton(
                                                onClick = {
                                                    val list = roundScores.toMutableList()
                                                    list[index] += 100
                                                    roundScores = list
                                                },
                                                modifier = Modifier.weight(1f),
                                                shape = RoundedCornerShape(8.dp)
                                            ) {
                                                Text("+100", fontSize = 12.sp)
                                            }

                                            FilledTonalButton(
                                                onClick = {
                                                    val list = roundScores.toMutableList()
                                                    list[index] -= 50
                                                    roundScores = list
                                                },
                                                modifier = Modifier.weight(1f),
                                                shape = RoundedCornerShape(8.dp)
                                            ) {
                                                Text("-50", fontSize = 12.sp)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Button(
                    onClick = {
                        val newTotals = totalScores.toMutableList()
                        selectedPlayerNames.indices.forEach { i ->
                            newTotals[i] += roundScores.getOrElse(i) { 0 }
                        }
                        totalScores = newTotals

                        val record = DuizendenRoundEntry(
                            round = currentRound,
                            roundScores = roundScores.toList(),
                            totals = newTotals.toList()
                        )
                        val newHistory = history.toMutableList()
                        newHistory.add(record)
                        history = newHistory

                        val hasReachedTarget = newTotals.any { it >= targetScore }
                        if (hasReachedTarget) {
                            val maxScore = newTotals.maxOrNull() ?: 0
                            val winnerIdx = newTotals.indexOf(maxScore)
                            val winner = selectedPlayerNames.getOrElse(winnerIdx) { "" }
                            winnerPlayer = winner

                            val detailed = selectedPlayerNames.indices.map { idx ->
                                PlayerScoreDetail(
                                    name = selectedPlayerNames[idx],
                                    score = newTotals[idx]
                                )
                            }
                            scoreManager.saveGame(
                                gameName = "Duizenden",
                                playerDetailedScores = detailed,
                                winnerName = winner
                            )
                            isGameOver = true
                        } else {
                            currentRound += 1
                            roundScores = MutableList(selectedPlayerNames.size) { 0 }
                            expandedPlayerIndex = null
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 12.dp)
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Icon(Icons.Default.CheckCircle, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Ronde $currentRound Voltooien", style = MaterialTheme.typography.titleMedium)
                }
            }
        }
    }

    if (showHistorySheet) {
        AlertDialog(
            onDismissRequest = { showHistorySheet = false },
            title = { Text("Geschiedenis Duizenden") },
            text = {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 350.dp)
                ) {
                    if (history.isEmpty()) {
                        item { Text("Nog geen rondes afgerond.") }
                    } else {
                        items(history.reversed()) { entry ->
                            AppCard(modifier = Modifier.padding(vertical = 4.dp)) {
                                Text(
                                    text = "Ronde ${entry.round}",
                                    fontWeight = FontWeight.Bold,
                                    style = MaterialTheme.typography.labelLarge
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                selectedPlayerNames.forEachIndexed { sIdx, pName ->
                                    val pts = entry.roundScores.getOrElse(sIdx) { 0 }
                                    val tot = entry.totals.getOrElse(sIdx) { 0 }
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween
                                    ) {
                                        Text(pName, style = MaterialTheme.typography.bodySmall)
                                        Text("${if (pts >= 0) "+" else ""}$pts pt (totaal: $tot)", style = MaterialTheme.typography.bodySmall, color = PrimaryBlue)
                                    }
                                }
                            }
                        }
                    }
                }
            },
            confirmButton = {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TextButton(onClick = {
                        showHistorySheet = false
                        showEditScoresDialog = true
                    }) {
                        Icon(Icons.Default.Edit, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Punten wijzigen")
                    }
                    TextButton(onClick = { showHistorySheet = false }) {
                        Text("Sluiten")
                    }
                }
            }
        )
    }

    if (showEditScoresDialog) {
        PuntenWijzigenDialog(
            playerNames = selectedPlayerNames,
            currentScores = totalScores,
            isLowestScoreWins = false,
            onDismiss = { showEditScoresDialog = false },
            onSave = { newScores ->
                totalScores = newScores.toMutableList()
            }
        )
    }

    if (showTafelschikkingDialog) {
        val playerObjects = selectedPlayerNames.map { name ->
            val prof = scoreManager.getPlayerProfile(name)
            Player(name = name, colorHex = prof.colorHex, avatarEmoji = prof.avatarEmoji)
        }
        TafelschikkingDialog(
            players = playerObjects,
            onDismiss = { showTafelschikkingDialog = false },
            onApplyOrder = { newOrdered ->
                selectedPlayerNames = newOrdered.map { it.name }.toMutableList()
            }
        )
    }

    if (showDisputeDialog) {
        WieHeeftGelijkDialog(
            initialGameFilter = "Duizenden",
            onDismiss = { showDisputeDialog = false }
        )
    }
}
