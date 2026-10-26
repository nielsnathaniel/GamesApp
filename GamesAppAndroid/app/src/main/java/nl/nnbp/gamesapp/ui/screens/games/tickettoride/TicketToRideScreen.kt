package nl.nnbp.gamesapp.ui.screens.games.tickettoride

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Train
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
import nl.nnbp.gamesapp.ui.components.NumericScoreStepper
import nl.nnbp.gamesapp.ui.components.PuntenWijzigenDialog
import nl.nnbp.gamesapp.ui.components.SavedPlayersQuickChips
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.components.TafelschikkingDialog
import nl.nnbp.gamesapp.ui.components.WieHeeftGelijkDialog
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.*

data class TTRScore(
    var routePoints: Int = 0,
    var completedTickets: Int = 0,
    var failedTickets: Int = 0,
    var hasLongestRoute: Boolean = false,
    var hasGlobetrotter: Boolean = false,
    var unusedStations: Int = 0, // 4 pt elk
    var directScore: Int = 0
) {
    fun calculatedTotal(isDirectMode: Boolean): Int {
        if (isDirectMode) return directScore
        val longest = if (hasLongestRoute) 10 else 0
        val globe = if (hasGlobetrotter) 10 else 0
        val stations = unusedStations * 4
        return routePoints + completedTickets - failedTickets + longest + globe + stations
    }
}

val defaultTrainColors = listOf(
    Pair("Rood", TrainRed),
    Pair("Blauw", TrainBlue),
    Pair("Groen", TrainGreen),
    Pair("Geel", TrainYellow),
    Pair("Zwart", TrainBlack),
    Pair("Paars", TrainPurple)
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TicketToRideScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }

    var isGameStarted by remember { mutableStateOf(false) }
    var selectedPlayerNames by remember { mutableStateOf(mutableListOf<String>()) }
    var isDirectMode by remember { mutableStateOf(false) }

    var playerScores by remember { mutableStateOf(mutableListOf<TTRScore>()) }
    var expandedPlayerIndex by remember { mutableStateOf<Int?>(0) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }
    var showTafelschikkingDialog by remember { mutableStateOf(false) }
    var showDisputeDialog by remember { mutableStateOf(false) }
    var showEditScoresDialog by remember { mutableStateOf(false) }

    val calculatedTotals = remember(playerScores, isDirectMode) {
        playerScores.map { it.calculatedTotal(isDirectMode) }
    }

    if (isGameOver && winnerPlayer != null) {
        val allPlayerScores = selectedPlayerNames.indices.map { i ->
            PlayerScore(
                playerName = selectedPlayerNames[i],
                score = calculatedTotals.getOrElse(i) { 0 },
                isWinner = selectedPlayerNames[i] == winnerPlayer
            )
        }
        WinnaarScreen(
            gameName = "Ticket to Ride",
            winnerName = winnerPlayer!!,
            scores = allPlayerScores,
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
                title = { Text("Ticket to Ride", fontWeight = FontWeight.Bold) },
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
                                text = "Spelregels Ticket to Ride 🚂",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Bouw routes tussen steden en voltooi bestemmingskaarten. Voer per speler routepunten in, voltooide tickets, mislukte tickets en bonussen (Langste route +10 pt, Globetrotter +10 pt, Stations 4 pt).",
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
                                Text("Telmethode:", fontWeight = FontWeight.SemiBold)
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    FilterChip(
                                        selected = !isDirectMode,
                                        onClick = { isDirectMode = false },
                                        label = { Text("Eindtelling (Bonussen)") },
                                        shape = RoundedCornerShape(10.dp)
                                    )
                                    FilterChip(
                                        selected = isDirectMode,
                                        onClick = { isDirectMode = true },
                                        label = { Text("Direct Totaal") },
                                        shape = RoundedCornerShape(10.dp)
                                    )
                                }
                            }
                        }
                    }

                    item {
                        SavedPlayersQuickChips(
                            selectedPlayers = selectedPlayerNames,
                            onTogglePlayer = { name ->
                                val list = selectedPlayerNames.toMutableList()
                                if (list.contains(name)) list.remove(name) else if (list.size < 5) list.add(name)
                                selectedPlayerNames = list
                            }
                        )
                    }

                    item {
                        SectionTitle(title = "Spelers & Treinkleuren (${selectedPlayerNames.size}/5)")
                        if (selectedPlayerNames.isEmpty()) {
                            Text("Selecteer 2 tot 5 spelers.", color = Color.Gray, style = MaterialTheme.typography.bodyMedium)
                        } else {
                            AppCard {
                                selectedPlayerNames.forEachIndexed { idx, name ->
                                    val colorPair = defaultTrainColors.getOrElse(idx) { defaultTrainColors.first() }
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(vertical = 4.dp),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                            Box(
                                                modifier = Modifier
                                                    .size(20.dp)
                                                    .clip(CircleShape)
                                                    .background(colorPair.second)
                                            )
                                            Spacer(modifier = Modifier.width(8.dp))
                                            Text("${idx + 1}. $name (${colorPair.first})", fontWeight = FontWeight.SemiBold)
                                        }
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
                        playerScores = MutableList(selectedPlayerNames.size) { TTRScore() }
                        isGameStarted = true
                    },
                    enabled = selectedPlayerNames.size in 2..5,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text("Start Puntentelling", style = MaterialTheme.typography.titleMedium)
                }
            }
        } else {
            // SCORING
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
                            scores = calculatedTotals,
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
                                Text("Ticket to Ride Uitslag", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
                                val leader = selectedPlayerNames.indices.maxByOrNull { calculatedTotals.getOrElse(it) { 0 } }
                                if (leader != null) {
                                    Text(
                                        text = "Leider: ${selectedPlayerNames[leader]} (${calculatedTotals[leader]} pt)",
                                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold, color = PrimaryBlue)
                                    )
                                }
                            }
                        }
                    }

                    itemsIndexed(selectedPlayerNames) { index, playerName ->
                        val isExpanded = expandedPlayerIndex == index
                        val colorPair = defaultTrainColors.getOrElse(index) { defaultTrainColors.first() }
                        val score = playerScores.getOrElse(index) { TTRScore() }
                        val total = calculatedTotals.getOrElse(index) { 0 }

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
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Box(
                                            modifier = Modifier
                                                .size(16.dp)
                                                .clip(CircleShape)
                                                .background(colorPair.second)
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Text(playerName, style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
                                    }

                                    Text(
                                        text = "$total pt",
                                        style = MaterialTheme.typography.headlineSmall.copy(
                                            fontWeight = FontWeight.Bold,
                                            color = colorPair.second
                                        )
                                    )
                                }

                                AnimatedVisibility(visible = isExpanded) {
                                    Column(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(top = 10.dp),
                                        verticalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))

                                        if (!isDirectMode) {
                                            // Routepunten presets (wagonlengtes: 1=1, 2=2, 3=4, 4=7, 5=10, 6=15, 7=18, 8=21)
                                            Text("Routepunten toevoegen via wagonlengte:", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                                listOf(
                                                    Pair(1, 1),
                                                    Pair(2, 2),
                                                    Pair(3, 4),
                                                    Pair(4, 7),
                                                    Pair(5, 10),
                                                    Pair(6, 15)
                                                ).forEach { (wagons, pts) ->
                                                    FilledTonalButton(
                                                        onClick = {
                                                            val list = playerScores.toMutableList()
                                                            list[index] = list[index].copy(routePoints = list[index].routePoints + pts)
                                                            playerScores = list
                                                        },
                                                        modifier = Modifier.weight(1f),
                                                        contentPadding = PaddingValues(0.dp)
                                                    ) {
                                                        Text("${wagons}w (+$pts)", fontSize = 10.sp)
                                                    }
                                                }
                                            }

                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                horizontalArrangement = Arrangement.SpaceBetween,
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Text("Totale routepunten:", fontWeight = FontWeight.SemiBold)
                                                NumericScoreStepper(
                                                    score = score.routePoints,
                                                    onScoreChange = {
                                                        val list = playerScores.toMutableList()
                                                        list[index] = list[index].copy(routePoints = maxOf(0, it))
                                                        playerScores = list
                                                    }
                                                )
                                            }

                                            // Voltooide bestemmingskaarten
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                horizontalArrangement = Arrangement.SpaceBetween,
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Text("Voltooide tickets (+):", fontWeight = FontWeight.SemiBold)
                                                NumericScoreStepper(
                                                    score = score.completedTickets,
                                                    onScoreChange = {
                                                        val list = playerScores.toMutableList()
                                                        list[index] = list[index].copy(completedTickets = maxOf(0, it))
                                                        playerScores = list
                                                    }
                                                )
                                            }

                                            // Mislukte tickets (aftrek)
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                horizontalArrangement = Arrangement.SpaceBetween,
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Text("Mislukte tickets (-):", fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.error)
                                                NumericScoreStepper(
                                                    score = score.failedTickets,
                                                    onScoreChange = {
                                                        val list = playerScores.toMutableList()
                                                        list[index] = list[index].copy(failedTickets = maxOf(0, it))
                                                        playerScores = list
                                                    }
                                                )
                                            }

                                            // Bonussen: Langste route, Globetrotter
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                                            ) {
                                                FilterChip(
                                                    selected = score.hasLongestRoute,
                                                    onClick = {
                                                        val list = playerScores.toMutableList()
                                                        list[index] = list[index].copy(hasLongestRoute = !score.hasLongestRoute)
                                                        playerScores = list
                                                    },
                                                    label = { Text("Langste Route (+10)") },
                                                    shape = RoundedCornerShape(10.dp),
                                                    modifier = Modifier.weight(1f)
                                                )

                                                FilterChip(
                                                    selected = score.hasGlobetrotter,
                                                    onClick = {
                                                        val list = playerScores.toMutableList()
                                                        list[index] = list[index].copy(hasGlobetrotter = !score.hasGlobetrotter)
                                                        playerScores = list
                                                    },
                                                    label = { Text("Globetrotter (+10)") },
                                                    shape = RoundedCornerShape(10.dp),
                                                    modifier = Modifier.weight(1f)
                                                )
                                            }
                                        } else {
                                            NumericScoreStepper(
                                                score = score.directScore,
                                                onScoreChange = {
                                                    val list = playerScores.toMutableList()
                                                    list[index] = list[index].copy(directScore = it)
                                                    playerScores = list
                                                },
                                                enableLargeStep = true
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Button(
                    onClick = {
                        val maxScore = calculatedTotals.maxOrNull() ?: 0
                        val winnerIdx = calculatedTotals.indexOf(maxScore)
                        val winner = selectedPlayerNames.getOrElse(winnerIdx) { "" }
                        winnerPlayer = winner

                        val detailed = selectedPlayerNames.indices.map { idx ->
                            PlayerScoreDetail(name = selectedPlayerNames[idx], score = calculatedTotals[idx])
                        }
                        scoreManager.saveGame(
                            gameName = "Ticket to Ride",
                            playerDetailedScores = detailed,
                            winnerName = winner
                        )
                        isGameOver = true
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 12.dp)
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Icon(Icons.Default.CheckCircle, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Uitslag Opslaan", style = MaterialTheme.typography.titleMedium)
                }
            }
        }
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
            initialGameFilter = "Ticket to Ride",
            onDismiss = { showDisputeDialog = false }
        )
    }

    if (showEditScoresDialog) {
        PuntenWijzigenDialog(
            playerNames = selectedPlayerNames,
            currentScores = calculatedTotals,
            isLowestScoreWins = false,
            onDismiss = { showEditScoresDialog = false },
            onSave = { newScores ->
                playerScores = playerScores.indices.map { i ->
                    val item = playerScores[i]
                    val target = newScores.getOrElse(i) { 0 }
                    if (isDirectMode) {
                        item.copy(directScore = target)
                    } else {
                        val other = item.calculatedTotal(false) - item.routePoints
                        item.copy(routePoints = target - other)
                    }
                }.toMutableList()
            }
        )
    }
}
