package nl.nnbp.gamesapp.ui.screens.games.quickstop

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.clickable
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
import nl.nnbp.gamesapp.ui.components.NumericScoreStepper
import nl.nnbp.gamesapp.ui.components.PuntenWijzigenDialog
import nl.nnbp.gamesapp.ui.components.SavedPlayersQuickChips
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.screens.games.SnelleEindscoreScreen
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SuccessGreen
import nl.nnbp.gamesapp.ui.theme.WarningRed

val quickstopThemes = listOf(
    "Iets wat in de koelkast staat",
    "Een dier met 4 poten",
    "Iets wat geel is",
    "Een land of bekende stad",
    "Iets wat je op vakantie meeneemt",
    "Een beroep of baan",
    "Iets wat veel lawaai maakt",
    "Een voorwerp in de badkamer",
    "Iets wat kleiner is dan een appel",
    "Een bekende film of serie",
    "Iets wat stinkt",
    "Een sport of hobby",
    "Iets wat zacht is",
    "Een merk of winkel",
    "Iets wat je op school of werk gebruikt",
    "Een groente of fruitsoort",
    "Iets wat van hout is gemaakt",
    "Een kledingstuk of accessoire",
    "Iets wat warm is",
    "Een bekend persoon of personage",
    "Iets wat je in de supermarkt koopt",
    "Een muziekinstrument",
    "Iets wat kan vliegen",
    "Iets wat rond is",
    "Een vervoermiddel"
)

data class QuickstopRoundLog(
    val round: Int,
    val starter: String,
    val scores: List<Int>,
    val totals: List<Int>
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuickstopScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }

    var isGameStarted by remember { mutableStateOf(false) }
    var selectedPlayerNames by remember { mutableStateOf(mutableListOf<String>()) }
    var penaltyLimit by remember { mutableIntStateOf(40) }

    var currentRound by remember { mutableIntStateOf(1) }
    var startPlayerIndex by remember { mutableIntStateOf(0) }
    var roundScores by remember { mutableStateOf(mutableListOf<Int>()) }
    var totalScores by remember { mutableStateOf(mutableListOf<Int>()) }
    var expandedPlayerIndex by remember { mutableStateOf<Int?>(null) }
    var history by remember { mutableStateOf(mutableListOf<QuickstopRoundLog>()) }
    var showHistoryDialog by remember { mutableStateOf(false) }

    // Thema generator
    var currentTheme by remember { mutableStateOf(quickstopThemes.random()) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }
    var showEditScoresDialog by remember { mutableStateOf(false) }
    var isQuickScoreMode by remember { mutableStateOf(false) }
    var startQuickScoreGame by remember { mutableStateOf(false) }

    if (startQuickScoreGame) {
        SnelleEindscoreScreen(
            gameName = "Quickstop",
            playerNames = selectedPlayerNames,
            isLowestScoreWins = true,
            scoreUnit = "⚡️",
            onNavigateBack = { startQuickScoreGame = false }
        )
        return
    }

    val currentStarterIndex = remember(startPlayerIndex, currentRound, selectedPlayerNames) {
        if (selectedPlayerNames.isEmpty()) 0 else (startPlayerIndex + (currentRound - 1)) % selectedPlayerNames.size
    }

    if (isGameOver && winnerPlayer != null) {
        val allScores = selectedPlayerNames.indices.map { i ->
            PlayerScore(
                playerName = selectedPlayerNames[i],
                score = totalScores.getOrElse(i) { 0 },
                isWinner = selectedPlayerNames[i] == winnerPlayer
            )
        }
        WinnaarScreen(
            gameName = "Quickstop",
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
                title = { Text("Quickstop", fontWeight = FontWeight.Bold) },
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
                        TextButton(onClick = { showHistoryDialog = true }) {
                            Icon(Icons.Default.History, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Historie (${history.size})")
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
                                text = "Spelregels Quickstop ⚡️",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Roep zo snel mogelijk woorden die passen bij het thema en beginnen met letters uit je hand. Rondewinnaar (als eerste kaarten weg) krijgt 0 strafpunten. Overige spelers tellen de bliksems op hun overgebleven kaarten.",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Einde bij $penaltyLimit strafpunten • Laagste score wint!",
                                style = MaterialTheme.typography.labelSmall,
                                color = AccentOrange
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
                                    Text("Limiet strafpunten:", fontWeight = FontWeight.SemiBold)
                                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                        listOf(30, 40, 50).forEach { limit ->
                                            FilterChip(
                                                selected = penaltyLimit == limit,
                                                onClick = { penaltyLimit = limit },
                                                label = { Text("$limit pt") },
                                                shape = RoundedCornerShape(10.dp)
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
                        if (isQuickScoreMode) {
                            startQuickScoreGame = true
                        } else {
                            roundScores = MutableList(selectedPlayerNames.size) { 0 }
                            totalScores = MutableList(selectedPlayerNames.size) { 0 }
                            startPlayerIndex = if (selectedPlayerNames.isNotEmpty()) (0 until selectedPlayerNames.size).random() else 0
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
                        if (isQuickScoreMode) "Start Snelle Eindscore" else "Start Spel (Limiet: $penaltyLimit pt)",
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
                    // Thema Generator Kaart
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = AccentOrange.copy(alpha = 0.12f))
                        ) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("Thema Ronde $currentRound", style = MaterialTheme.typography.labelSmall, color = AccentOrange, fontWeight = FontWeight.Bold)
                                    TextButton(onClick = { currentTheme = quickstopThemes.random() }) {
                                        Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(14.dp))
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text("Ander thema", style = MaterialTheme.typography.labelSmall)
                                    }
                                }
                                Text(
                                    text = "💡 \"$currentTheme\"",
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold, color = AccentOrange)
                                )
                            }
                        }
                    }

                    // Voorlezer / Begint banner
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
                                    Text("Leest thema voor deze ronde:", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                    Text(selectedPlayerNames.getOrElse(currentStarterIndex) { "" }, style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
                                }
                                Text("Limiet: $penaltyLimit pt", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                            }
                        }
                    }

                    itemsIndexed(selectedPlayerNames) { index, playerName ->
                        val isStarter = index == currentStarterIndex
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
                                                    color = PrimaryBlue
                                                ) {
                                                    Text(
                                                        text = "Leest voor",
                                                        style = MaterialTheme.typography.labelSmall.copy(color = Color.White),
                                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                                    )
                                                }
                                            }
                                        }
                                        Text(
                                            text = "Strafpunten: $currentTotal / $penaltyLimit ⚡️",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = if (currentTotal >= penaltyLimit - 10) WarningRed else Color.Gray
                                        )
                                    }

                                    Column(horizontalAlignment = Alignment.End) {
                                        Text(
                                            text = "+$currentRoundScore",
                                            style = MaterialTheme.typography.headlineSmall.copy(
                                                fontWeight = FontWeight.Bold,
                                                color = if (currentRoundScore == 0) SuccessGreen else WarningRed
                                            )
                                        )
                                        Text("bliksems", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
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

                                        // Snelle knop: 0 strafpunten (Rondewinnaar)
                                        Button(
                                            onClick = {
                                                val list = roundScores.toMutableList()
                                                list[index] = 0
                                                roundScores = list
                                            },
                                            colors = ButtonDefaults.buttonColors(containerColor = SuccessGreen),
                                            shape = RoundedCornerShape(8.dp),
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Text("🏆 Kaarten weggespeeld! (0 strafpunten)", fontWeight = FontWeight.Bold)
                                        }

                                        Spacer(modifier = Modifier.height(8.dp))

                                        Text("Resterende bliksems op kaarten:", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                        Spacer(modifier = Modifier.height(4.dp))

                                        NumericScoreStepper(
                                            score = currentRoundScore,
                                            onScoreChange = { newVal ->
                                                val list = roundScores.toMutableList()
                                                list[index] = maxOf(0, newVal)
                                                roundScores = list
                                            },
                                            enableLargeStep = false
                                        )
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

                        val starter = selectedPlayerNames.getOrElse(currentStarterIndex) { "Speler 1" }
                        val record = QuickstopRoundLog(
                            round = currentRound,
                            starter = starter,
                            scores = roundScores.toList(),
                            totals = newTotals.toList()
                        )
                        val newHist = history.toMutableList()
                        newHist.add(record)
                        history = newHist

                        // Check of iemand de limiet bereikt heeft
                        if (newTotals.any { it >= penaltyLimit }) {
                            val minScore = newTotals.minOrNull() ?: 0
                            val winnerIdx = newTotals.indexOf(minScore)
                            val winner = selectedPlayerNames.getOrElse(winnerIdx) { "" }
                            winnerPlayer = winner

                            val detailed = selectedPlayerNames.indices.map { idx ->
                                PlayerScoreDetail(name = selectedPlayerNames[idx], score = newTotals[idx])
                            }
                            scoreManager.saveGame(
                                gameName = "Quickstop",
                                playerDetailedScores = detailed,
                                winnerName = winner
                            )
                            isGameOver = true
                        } else {
                            currentRound += 1
                            roundScores = MutableList(selectedPlayerNames.size) { 0 }
                            currentTheme = quickstopThemes.random()
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
                    Text("Ronde $currentRound Beëindigen", style = MaterialTheme.typography.titleMedium)
                }
            }
        }
    }

    if (showHistoryDialog) {
        AlertDialog(
            onDismissRequest = { showHistoryDialog = false },
            title = { Text("Historie Quickstop") },
            text = {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 300.dp)
                ) {
                    if (history.isEmpty()) {
                        item { Text("Nog geen rondes afgerond.") }
                    } else {
                        items(history.reversed()) { log ->
                            AppCard(modifier = Modifier.padding(vertical = 4.dp)) {
                                Text("Ronde ${log.round} • Voorlezer: ${log.starter}", fontWeight = FontWeight.Bold)
                                Spacer(modifier = Modifier.height(4.dp))
                                selectedPlayerNames.forEachIndexed { sIdx, pName ->
                                    val pts = log.scores.getOrElse(sIdx) { 0 }
                                    val tot = log.totals.getOrElse(sIdx) { 0 }
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween
                                    ) {
                                        Text(pName, style = MaterialTheme.typography.bodySmall)
                                        Text("+$pts (totaal: $tot ⚡️)", style = MaterialTheme.typography.bodySmall, color = WarningRed)
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
                        showHistoryDialog = false
                        showEditScoresDialog = true
                    }) {
                        Icon(Icons.Default.Edit, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Punten wijzigen")
                    }
                    TextButton(onClick = { showHistoryDialog = false }) {
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
            isLowestScoreWins = true,
            onDismiss = { showEditScoresDialog = false },
            onSave = { newScores ->
                totalScores = newScores.toMutableList()
            }
        )
    }
}
