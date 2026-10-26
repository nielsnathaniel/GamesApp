package nl.nnbp.gamesapp.ui.screens.games.beverbende

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
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
import androidx.compose.ui.draw.clip
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
import nl.nnbp.gamesapp.ui.components.SavedPlayersQuickChips
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.components.TafelschikkingDialog
import nl.nnbp.gamesapp.ui.components.WieHeeftGelijkDialog
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SuccessGreen

data class BeverbendeRoundEntry(
    val round: Int,
    val starter: String,
    val roundScores: List<Int>,
    val totals: List<Int>
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BeverbendeScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }

    var isGameStarted by remember { mutableStateOf(false) }
    var selectedPlayerNames by remember { mutableStateOf(mutableListOf<String>()) }
    var targetRounds by remember { mutableIntStateOf(5) }

    // In-game states
    var currentRound by remember { mutableIntStateOf(1) }
    var startPlayerIndex by remember { mutableIntStateOf(0) }
    // 4 kaarten per speler (waardes 0-9)
    var playerCards by remember { mutableStateOf(mutableListOf<MutableList<Int>>()) }
    var totalScores by remember { mutableStateOf(mutableListOf<Int>()) }
    var expandedPlayerIndex by remember { mutableStateOf<Int?>(0) }
    var history by remember { mutableStateOf(mutableListOf<BeverbendeRoundEntry>()) }
    var showHistorySheet by remember { mutableStateOf(false) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }
    var showTafelschikkingDialog by remember { mutableStateOf(false) }
    var showDisputeDialog by remember { mutableStateOf(false) }

    val currentStarterIndex = remember(startPlayerIndex, currentRound, selectedPlayerNames) {
        if (selectedPlayerNames.isEmpty()) 0 else (startPlayerIndex + (currentRound - 1)) % selectedPlayerNames.size
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
            gameName = "Beverbende",
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
                title = { Text("Beverbende", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Terug")
                    }
                },
                actions = {
                    if (isGameStarted) {
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
                                text = "Spelregels Beverbende 🦫",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Tactisch kaartspel waarbij spelers 4 kaarten voor zich hebben. De speler met de minste strafpunten na alle rondes wint!",
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
                                Text("Aantal rondes:", fontWeight = FontWeight.SemiBold)
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    FilledTonalButton(
                                        onClick = { if (targetRounds > 1) targetRounds-- },
                                        contentPadding = PaddingValues(0.dp),
                                        modifier = Modifier.size(36.dp),
                                        shape = CircleShape
                                    ) {
                                        Text("-", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                                    }
                                    Text(
                                        text = "$targetRounds",
                                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                                    )
                                    FilledTonalButton(
                                        onClick = { if (targetRounds < 15) targetRounds++ },
                                        contentPadding = PaddingValues(0.dp),
                                        modifier = Modifier.size(36.dp),
                                        shape = CircleShape
                                    ) {
                                        Text("+", fontSize = 16.sp, fontWeight = FontWeight.Bold)
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
                        playerCards = MutableList(selectedPlayerNames.size) { mutableListOf(0, 0, 0, 0) }
                        totalScores = MutableList(selectedPlayerNames.size) { 0 }
                        startPlayerIndex = if (selectedPlayerNames.isNotEmpty()) (0 until selectedPlayerNames.size).random() else 0
                        isGameStarted = true
                    },
                    enabled = selectedPlayerNames.size >= 2,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text("Start Spel ($targetRounds rondes)", style = MaterialTheme.typography.titleMedium)
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
                            lowestWins = true
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
                                    .padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Default.Casino, contentDescription = null, tint = PrimaryBlue)
                                    Spacer(modifier = Modifier.width(10.dp))
                                    Column {
                                        Text("Begint deze ronde:", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                        Text(
                                            text = selectedPlayerNames.getOrElse(currentStarterIndex) { "" },
                                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                                        )
                                    }
                                }
                                Text(
                                    text = "Ronde $currentRound van $targetRounds",
                                    style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                                    color = PrimaryBlue
                                )
                            }
                        }
                    }

                    itemsIndexed(selectedPlayerNames) { index, playerName ->
                        val isStarter = index == currentStarterIndex
                        val isExpanded = expandedPlayerIndex == index
                        val cards = playerCards.getOrElse(index) { mutableListOf(0, 0, 0, 0) }
                        val roundSum = cards.sum()
                        val currentTotal = totalScores.getOrElse(index) { 0 }

                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    expandedPlayerIndex = if (isExpanded) null else index
                                },
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = if (isStarter) PrimaryBlue.copy(alpha = 0.08f) else MaterialTheme.colorScheme.surfaceVariant
                            )
                        ) {
                            Column(modifier = Modifier.padding(14.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column {
                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                            Text(playerName, style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
                                            if (isStarter) {
                                                Spacer(modifier = Modifier.width(6.dp))
                                                Surface(
                                                    shape = RoundedCornerShape(6.dp),
                                                    color = SuccessGreen
                                                ) {
                                                    Text(
                                                        text = "Begint",
                                                        style = MaterialTheme.typography.labelSmall.copy(color = Color.White),
                                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                                    )
                                                }
                                            }
                                        }
                                        Text(
                                            text = "Totale score: $currentTotal",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = Color.Gray
                                        )
                                    }

                                    Column(horizontalAlignment = Alignment.End) {
                                        Text(
                                            text = "+$roundSum",
                                            style = MaterialTheme.typography.headlineSmall.copy(
                                                fontWeight = FontWeight.Bold,
                                                color = PrimaryBlue
                                            )
                                        )
                                        Text("deze ronde", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                    }
                                }

                                AnimatedVisibility(visible = isExpanded) {
                                    Column(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(top = 12.dp)
                                    ) {
                                        Text(
                                            text = "4 handkaarten (0 t/m 9):",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = Color.Gray
                                        )
                                        Spacer(modifier = Modifier.height(8.dp))

                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.SpaceEvenly
                                        ) {
                                            cards.forEachIndexed { cardIdx, cardVal ->
                                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                                    IconButton(
                                                        onClick = {
                                                            val newCards = playerCards.toMutableList()
                                                            val playerList = newCards[index].toMutableList()
                                                            playerList[cardIdx] = (playerList[cardIdx] + 1) % 10
                                                            newCards[index] = playerList
                                                            playerCards = newCards
                                                        },
                                                        modifier = Modifier.size(36.dp)
                                                    ) {
                                                        Icon(Icons.Default.KeyboardArrowUp, contentDescription = "+1", tint = PrimaryBlue)
                                                    }

                                                    Box(
                                                        modifier = Modifier
                                                            .size(46.dp)
                                                            .clip(RoundedCornerShape(8.dp))
                                                            .background(MaterialTheme.colorScheme.background),
                                                        contentAlignment = Alignment.Center
                                                    ) {
                                                        Text(
                                                            text = "$cardVal",
                                                            style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold)
                                                        )
                                                    }

                                                    IconButton(
                                                        onClick = {
                                                            val newCards = playerCards.toMutableList()
                                                            val playerList = newCards[index].toMutableList()
                                                            playerList[cardIdx] = (playerList[cardIdx] - 1 + 10) % 10
                                                            newCards[index] = playerList
                                                            playerCards = newCards
                                                        },
                                                        modifier = Modifier.size(36.dp)
                                                    ) {
                                                        Icon(Icons.Default.KeyboardArrowDown, contentDescription = "-1", tint = AccentOrange)
                                                    }
                                                }
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
                        val roundSums = playerCards.map { it.sum() }
                        val newTotals = totalScores.toMutableList()
                        selectedPlayerNames.indices.forEach { i ->
                            newTotals[i] += roundSums.getOrElse(i) { 0 }
                        }
                        totalScores = newTotals

                        val starter = selectedPlayerNames.getOrElse(currentStarterIndex) { "Speler 1" }
                        val record = BeverbendeRoundEntry(
                            round = currentRound,
                            starter = starter,
                            roundScores = roundSums,
                            totals = newTotals.toList()
                        )
                        val newHistory = history.toMutableList()
                        newHistory.add(record)
                        history = newHistory

                        if (currentRound >= targetRounds) {
                            // Laagste score wint!
                            val minScore = newTotals.minOrNull() ?: 0
                            val winnerIdx = newTotals.indexOf(minScore)
                            val winner = selectedPlayerNames.getOrElse(winnerIdx) { "" }
                            winnerPlayer = winner

                            val detailed = selectedPlayerNames.indices.map { idx ->
                                PlayerScoreDetail(
                                    name = selectedPlayerNames[idx],
                                    score = newTotals[idx]
                                )
                            }
                            scoreManager.saveGame(
                                gameName = "Beverbende",
                                playerDetailedScores = detailed,
                                winnerName = winner
                            )
                            isGameOver = true
                        } else {
                            currentRound += 1
                            playerCards = MutableList(selectedPlayerNames.size) { mutableListOf(0, 0, 0, 0) }
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
                    Text(
                        text = if (currentRound >= targetRounds) "Spel Voltooien" else "Ronde $currentRound Beëindigen",
                        style = MaterialTheme.typography.titleMedium
                    )
                }
            }
        }
    }

    if (showHistorySheet) {
        AlertDialog(
            onDismissRequest = { showHistorySheet = false },
            title = { Text("Geschiedenis Beverbende") },
            text = {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 350.dp)
                ) {
                    if (history.isEmpty()) {
                        item { Text("Nog geen rondes voltooid.") }
                    } else {
                        items(history.reversed()) { entry ->
                            AppCard(modifier = Modifier.padding(vertical = 4.dp)) {
                                Text(
                                    text = "Ronde ${entry.round} van $targetRounds • Begonnen door ${entry.starter}",
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
                                        Text("+$pts pt (totaal: $tot)", style = MaterialTheme.typography.bodySmall, color = PrimaryBlue)
                                    }
                                }
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showHistorySheet = false }) {
                    Text("Sluiten")
                }
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
            initialGameFilter = "Beverbende",
            onDismiss = { showDisputeDialog = false }
        )
    }
}
