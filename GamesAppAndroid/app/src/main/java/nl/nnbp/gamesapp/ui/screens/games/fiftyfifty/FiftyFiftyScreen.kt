package nl.nnbp.gamesapp.ui.screens.games.fiftyfifty

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
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
import nl.nnbp.gamesapp.ui.components.NumericScoreStepper
import nl.nnbp.gamesapp.ui.components.SavedPlayersQuickChips
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.WarningRed

data class FiftyFiftyRoundRecord(
    val round: Int,
    val penaltyCards: List<Int>,
    val hasFox: List<Boolean>,
    val totals: List<Int>
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FiftyFiftyScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }

    var isGameStarted by remember { mutableStateOf(false) }
    var selectedPlayerNames by remember { mutableStateOf(mutableListOf<String>()) }
    var targetRounds by remember { mutableIntStateOf(3) }

    var currentRound by remember { mutableIntStateOf(1) }
    var roundPenalties by remember { mutableStateOf(mutableListOf<Int>()) }
    var hasFoxInHand by remember { mutableStateOf(mutableListOf<Boolean>()) }
    var totalPenalties by remember { mutableStateOf(mutableListOf<Int>()) }
    var expandedPlayerIndex by remember { mutableStateOf<Int?>(0) }
    var history by remember { mutableStateOf(mutableListOf<FiftyFiftyRoundRecord>()) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }

    if (isGameOver && winnerPlayer != null) {
        val allScores = selectedPlayerNames.indices.map { i ->
            PlayerScore(
                playerName = selectedPlayerNames[i],
                score = totalPenalties.getOrElse(i) { 0 },
                isWinner = selectedPlayerNames[i] == winnerPlayer
            )
        }
        WinnaarScreen(
            gameName = "Fifty Fifty",
            winnerName = winnerPlayer!!,
            scores = allScores,
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
                title = { Text("Fifty Fifty", fontWeight = FontWeight.Bold) },
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
                                text = "Spelregels Fifty Fifty 🦊",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Kaartspel van White Goblin Games. Ontwijk strafkaarten en zorg dat je aan het einde van het spel NOOIT de vos op hand hebt (automatisch verloren!). De speler met de minste strafkaarten (zonder vos) wint!",
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
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    listOf(3, 5, 7).forEach { r ->
                                        FilterChip(
                                            selected = targetRounds == r,
                                            onClick = { targetRounds = r },
                                            label = { Text("$r rondes") },
                                            shape = RoundedCornerShape(10.dp)
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
                            Text("Selecteer minimaal 2 spelers.", color = Color.Gray, style = MaterialTheme.typography.bodyMedium)
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
                        roundPenalties = MutableList(selectedPlayerNames.size) { 0 }
                        hasFoxInHand = MutableList(selectedPlayerNames.size) { false }
                        totalPenalties = MutableList(selectedPlayerNames.size) { 0 }
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
                                    Text("Ronde $currentRound van $targetRounds", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
                                    Text("Laagste score (zonder vos) wint", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                                }
                                val validPlayers = selectedPlayerNames.indices.filter { !hasFoxInHand.getOrElse(it) { false } }
                                val leader = validPlayers.minByOrNull { totalPenalties.getOrElse(it) { 0 } }
                                if (leader != null) {
                                    Text(
                                        text = "Leider: ${selectedPlayerNames[leader]} (${totalPenalties[leader]} pt)",
                                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold, color = PrimaryBlue)
                                    )
                                }
                            }
                        }
                    }

                    itemsIndexed(selectedPlayerNames) { index, playerName ->
                        val isExpanded = expandedPlayerIndex == index
                        val roundPts = roundPenalties.getOrElse(index) { 0 }
                        val totalPts = totalPenalties.getOrElse(index) { 0 }
                        val fox = hasFoxInHand.getOrElse(index) { false }

                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    expandedPlayerIndex = if (isExpanded) null else index
                                },
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = if (fox) WarningRed.copy(alpha = 0.1f) else MaterialTheme.colorScheme.surfaceVariant
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
                                            if (fox) {
                                                Spacer(modifier = Modifier.width(6.dp))
                                                Text("🦊 VOS OP HAND", style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold, color = WarningRed))
                                            }
                                        }
                                        Text(
                                            text = "Totaal strafkaarten: $totalPts",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = Color.Gray
                                        )
                                    }

                                    Column(horizontalAlignment = Alignment.End) {
                                        Text(
                                            text = "+$roundPts",
                                            style = MaterialTheme.typography.headlineSmall.copy(
                                                fontWeight = FontWeight.Bold,
                                                color = if (roundPts > 0) WarningRed else PrimaryBlue
                                            )
                                        )
                                        Text("deze ronde", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                    }
                                }

                                AnimatedVisibility(visible = isExpanded) {
                                    Column(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(top = 10.dp),
                                        horizontalAlignment = Alignment.CenterHorizontally
                                    ) {
                                        HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))
                                        Spacer(modifier = Modifier.height(8.dp))

                                        // Vos op hand toggle
                                        FilterChip(
                                            selected = fox,
                                            onClick = {
                                                val list = hasFoxInHand.toMutableList()
                                                list[index] = !fox
                                                hasFoxInHand = list
                                            },
                                            label = { Text(if (fox) "🦊 Vos op hand (Actief)" else "Geen vos op hand") },
                                            colors = FilterChipDefaults.filterChipColors(
                                                selectedContainerColor = WarningRed,
                                                selectedLabelColor = Color.White
                                            ),
                                            shape = RoundedCornerShape(8.dp)
                                        )

                                        Spacer(modifier = Modifier.height(8.dp))
                                        Text("Strafkaarten deze ronde:", style = MaterialTheme.typography.labelSmall, color = Color.Gray)

                                        NumericScoreStepper(
                                            score = roundPts,
                                            onScoreChange = { newVal ->
                                                val list = roundPenalties.toMutableList()
                                                list[index] = maxOf(0, newVal)
                                                roundPenalties = list
                                            },
                                            enableLargeStep = true
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                Button(
                    onClick = {
                        val newTotals = totalPenalties.toMutableList()
                        selectedPlayerNames.indices.forEach { i ->
                            newTotals[i] += roundPenalties.getOrElse(i) { 0 }
                        }
                        totalPenalties = newTotals

                        val record = FiftyFiftyRoundRecord(
                            round = currentRound,
                            penaltyCards = roundPenalties.toList(),
                            hasFox = hasFoxInHand.toList(),
                            totals = newTotals.toList()
                        )
                        val newHist = history.toMutableList()
                        newHist.add(record)
                        history = newHist

                        if (currentRound >= targetRounds) {
                            // Bepaal winnaar: minste strafkaarten onder spelers ZONDER vos
                            val validIndices = selectedPlayerNames.indices.filter { !hasFoxInHand.getOrElse(it) { false } }
                            val bestIdx = if (validIndices.isNotEmpty()) {
                                validIndices.minByOrNull { newTotals[it] } ?: 0
                            } else {
                                newTotals.indices.minByOrNull { newTotals[it] } ?: 0
                            }
                            val winner = selectedPlayerNames.getOrElse(bestIdx) { "" }
                            winnerPlayer = winner

                            val detailed = selectedPlayerNames.indices.map { idx ->
                                PlayerScoreDetail(name = selectedPlayerNames[idx], score = newTotals[idx])
                            }
                            scoreManager.saveGame(
                                gameName = "Fifty Fifty",
                                playerDetailedScores = detailed,
                                winnerName = winner
                            )
                            isGameOver = true
                        } else {
                            currentRound += 1
                            roundPenalties = MutableList(selectedPlayerNames.size) { 0 }
                            hasFoxInHand = MutableList(selectedPlayerNames.size) { false }
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
                    Text(
                        text = if (currentRound >= targetRounds) "Spel Voltooien" else "Ronde $currentRound Beëindigen",
                        style = MaterialTheme.typography.titleMedium
                    )
                }
            }
        }
    }
}
