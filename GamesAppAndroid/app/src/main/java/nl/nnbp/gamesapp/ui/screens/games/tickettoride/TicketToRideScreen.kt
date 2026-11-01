package nl.nnbp.gamesapp.ui.screens.games.tickettoride

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
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
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.model.GameType
import nl.nnbp.gamesapp.data.model.Player
import nl.nnbp.gamesapp.data.model.PlayerScore
import nl.nnbp.gamesapp.ui.components.*
import nl.nnbp.gamesapp.ui.screens.games.SnelleEindscoreScreen
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.*

val ttrTrainColors = listOf(
    Pair("Rood", TrainRed),
    Pair("Blauw", TrainBlue),
    Pair("Groen", TrainGreen),
    Pair("Geel", TrainYellow),
    Pair("Zwart", TrainBlack),
    Pair("Paars", TrainPurple)
)

data class TTRPlayerData(
    var routePoints: Int = 0,
    var completedTickets: Int = 0,
    var failedTickets: Int = 0,
    var hasLongestRoute: Boolean = false,
    var hasGlobetrotter: Boolean = false,
    var unusedStations: Int = 0 // 0..3 (4 pt elk)
) {
    fun calculatedTotal(): Int {
        val longest = if (hasLongestRoute) 10 else 0
        val globe = if (hasGlobetrotter) 10 else 0
        val stations = unusedStations * 4
        return routePoints + completedTickets - failedTickets + longest + globe + stations
    }
}

data class TTRLiveTurn(
    val player: String,
    val points: Int,
    val description: String
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
    var selectedPlayerCount by remember { mutableIntStateOf(4) }
    var gameMode by remember { mutableStateOf("categorieen") } // "categorieen", "live", "snel"
    var showTafelschikkingDialog by remember { mutableStateOf(false) }

    // Quick score screen navigation
    var startQuickScoreGame by remember { mutableStateOf(false) }
    if (startQuickScoreGame) {
        SnelleEindscoreScreen(
            gameName = "Ticket to Ride",
            playerNames = selectedPlayerNames,
            isLowestScoreWins = false,
            scoreUnit = "pt",
            onNavigateBack = { startQuickScoreGame = false }
        )
        return
    }

    // In-game states
    var playerScores by remember { mutableStateOf(mutableListOf<TTRPlayerData>()) }
    var selectedPlayerTab by remember { mutableIntStateOf(0) }
    var liveTurnHistory by remember { mutableStateOf(mutableListOf<TTRLiveTurn>()) }
    var showHistoryDialog by remember { mutableStateOf(false) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }

    val calculatedTotals = remember(playerScores) {
        playerScores.map { it.calculatedTotal() }
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

    val modeOptions = listOf(
        GameModeItem(
            id = "categorieen",
            title = "Categorieën",
            icon = Icons.Default.Train,
            description = "🚂 Eindtelling: routes op basis van treinlengtes, bestemmingskaarten, langste route en stations."
        ),
        GameModeItem(
            id = "live",
            title = "Ronde per Ronde",
            icon = Icons.Default.PlayCircle,
            description = "🎮 Registreer tijdens het spelen elke gelegde treinroute beurt voor beurt met live tussenstand."
        ),
        GameModeItem(
            id = "snel",
            title = "Direct Totaal",
            icon = Icons.Default.Bolt,
            description = "⚡️ Vul direct het totale puntenaantal per speler in."
        )
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        GameLogoImage(gameType = GameType.TICKET_TO_RIDE, size = 30.dp, cornerRadius = 8.dp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Ticket to Ride", fontWeight = FontWeight.Bold, fontSize = 18.sp)
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Terug")
                    }
                },
                actions = {
                    if (isGameStarted && gameMode == "live") {
                        IconButton(onClick = { showHistoryDialog = true }) {
                            Icon(Icons.Default.History, contentDescription = "Historie", tint = TrainBlue)
                        }
                    }
                }
            )
        }
    ) { padding ->
        if (!isGameStarted) {
            // SETUP FASE
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
                        GameSetupHeader(
                            gameType = GameType.TICKET_TO_RIDE,
                            subtitle = "Treinavontuur • Europa & USA 🚂",
                            themeColor = TrainBlue
                        )
                    }

                    item {
                        GameModeSegmentedPicker(
                            options = modeOptions,
                            selectedId = gameMode,
                            onSelect = { gameMode = it },
                            themeColor = TrainBlue
                        )
                    }

                    item {
                        PlayerCountPicker(
                            minPlayers = 2,
                            maxPlayers = 5,
                            selectedCount = selectedPlayerCount,
                            onSelect = { count ->
                                selectedPlayerCount = count
                                while (selectedPlayerNames.size > count) {
                                    selectedPlayerNames.removeAt(selectedPlayerNames.lastIndex)
                                }
                            },
                            themeColor = TrainBlue
                        )
                    }

                    item {
                        SavedPlayersQuickChips(
                            selectedPlayers = selectedPlayerNames,
                            onTogglePlayer = { name ->
                                val list = selectedPlayerNames.toMutableList()
                                if (list.contains(name)) {
                                    list.remove(name)
                                } else if (list.size < selectedPlayerCount) {
                                    list.add(name)
                                }
                                selectedPlayerNames = list
                            },
                            onApplyTafelschikking = { seated ->
                                selectedPlayerCount = seated.size.coerceIn(2, 5)
                                selectedPlayerNames = seated.take(selectedPlayerCount).toMutableList()
                            }
                        )
                    }

                    item {
                        SectionTitle(title = "Deelnemers (${selectedPlayerNames.size} / $selectedPlayerCount)")
                        if (selectedPlayerNames.isEmpty()) {
                            Text(
                                text = "Selecteer minimaal 2 spelers.",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                            )
                        } else {
                            AppCard {
                                selectedPlayerNames.forEachIndexed { idx, name ->
                                    val (colorName, trainColor) = ttrTrainColors[idx % ttrTrainColors.size]
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
                                                    .size(16.dp)
                                                    .clip(CircleShape)
                                                    .background(trainColor)
                                            )
                                            Spacer(modifier = Modifier.width(8.dp))
                                            Text(name, fontWeight = FontWeight.SemiBold)
                                            Spacer(modifier = Modifier.width(6.dp))
                                            Text("($colorName)", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))
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

                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (selectedPlayerNames.size >= 2) {
                        OutlinedButton(
                            onClick = { showTafelschikkingDialog = true },
                            modifier = Modifier.fillMaxWidth().height(48.dp),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Tafelschikking (Wie zit waar?)")
                        }
                    }

                    Button(
                        onClick = {
                            if (gameMode == "snel") {
                                startQuickScoreGame = true
                            } else {
                                playerScores = MutableList(selectedPlayerNames.size) { TTRPlayerData() }
                                selectedPlayerTab = 0
                                liveTurnHistory.clear()
                                isGameStarted = true
                            }
                        },
                        enabled = selectedPlayerNames.size >= 2,
                        colors = ButtonDefaults.buttonColors(containerColor = TrainBlue),
                        modifier = Modifier.fillMaxWidth().height(52.dp),
                        shape = RoundedCornerShape(14.dp)
                    ) {
                        Text(
                            when (gameMode) {
                                "snel" -> "⚡️ Snelle Eindscore Starten"
                                "live" -> "🎮 Start Live Rondetracking (${selectedPlayerNames.size} spelers)"
                                else -> "Start Categorieëntelling (${selectedPlayerNames.size} spelers)"
                            },
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                        )
                    }
                }
            }
        } else {
            // IN-GAME FASE
            val scoresPairList = selectedPlayerNames.indices.map { i ->
                Pair(selectedPlayerNames[i], calculatedTotals.getOrElse(i) { 0 })
            }

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(16.dp),
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    // Live Lead Indicator
                    item {
                        LiveGameLeadCard(
                            playerScores = scoresPairList,
                            isLowestScoreWins = false,
                            themeColor = TrainBlue
                        )
                    }

                    // Speler Selector Tabs met treinkleuren
                    item {
                        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            itemsIndexed(selectedPlayerNames) { idx, name ->
                                val isSel = selectedPlayerTab == idx
                                val (_, trainCol) = ttrTrainColors[idx % ttrTrainColors.size]
                                val total = calculatedTotals.getOrElse(idx) { 0 }

                                Surface(
                                    shape = RoundedCornerShape(12.dp),
                                    color = if (isSel) trainCol else trainCol.copy(alpha = 0.12f),
                                    border = androidx.compose.foundation.BorderStroke(
                                        width = if (isSel) 2.5.dp else 1.dp,
                                        color = trainCol
                                    ),
                                    modifier = Modifier.clickable { selectedPlayerTab = idx }
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                                    ) {
                                        Box(
                                            modifier = Modifier
                                                .size(8.dp)
                                                .clip(CircleShape)
                                                .background(if (isSel) Color.White else trainCol)
                                        )
                                        Column {
                                            Text(
                                                text = name,
                                                fontWeight = if (isSel) FontWeight.Bold else FontWeight.Medium,
                                                color = if (isSel) Color.White else MaterialTheme.colorScheme.onSurface,
                                                fontSize = 13.sp
                                            )
                                            Text(
                                                text = "$total pt",
                                                fontWeight = FontWeight.Black,
                                                color = if (isSel) Color.White else trainCol,
                                                fontSize = 11.sp
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    val activePlayerName = selectedPlayerNames.getOrElse(selectedPlayerTab) { "" }
                    val activeScore = playerScores.getOrElse(selectedPlayerTab) { TTRPlayerData() }
                    val (_, activeTrainColor) = ttrTrainColors[selectedPlayerTab % ttrTrainColors.size]

                    // Header kaart van actieve speler
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = activeTrainColor.copy(alpha = 0.14f))
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .border(1.5.dp, activeTrainColor.copy(alpha = 0.4f), RoundedCornerShape(14.dp))
                                    .padding(14.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Default.Train, contentDescription = null, tint = activeTrainColor, modifier = Modifier.size(28.dp))
                                    Spacer(modifier = Modifier.width(10.dp))
                                    Column {
                                        Text("PUNTEN VOOR:", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = activeTrainColor)
                                        Text(activePlayerName, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                                    }
                                }
                                Text(
                                    text = "${activeScore.calculatedTotal()} pt",
                                    fontSize = 24.sp,
                                    fontWeight = FontWeight.Black,
                                    color = activeTrainColor
                                )
                            }
                        }
                    }

                    // 1. Routepunten (Treintrajecten) met presets
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("1. Routepunten (Treintrajecten)", fontWeight = FontWeight.Bold, color = activeTrainColor)
                                    Text("${activeScore.routePoints} pt", fontWeight = FontWeight.Black, fontSize = 16.sp, color = activeTrainColor)
                                }

                                Text("Snelle treinlengte presets:", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))

                                val presets = listOf(
                                    1 to 1,
                                    2 to 2,
                                    3 to 4,
                                    4 to 7,
                                    5 to 10,
                                    6 to 15,
                                    8 to 21
                                )

                                LazyRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                    items(presets.size) { i ->
                                        val (length, pts) = presets[i]
                                        FilledTonalButton(
                                            onClick = {
                                                val list = playerScores.toMutableList()
                                                list[selectedPlayerTab] = list[selectedPlayerTab].copy(
                                                    routePoints = list[selectedPlayerTab].routePoints + pts
                                                )
                                                playerScores = list
                                                if (gameMode == "live") {
                                                    liveTurnHistory.add(
                                                        TTRLiveTurn(
                                                            player = activePlayerName,
                                                            points = pts,
                                                            description = "Legt route van $length wagons (+$pts pt)"
                                                        )
                                                    )
                                                }
                                            },
                                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp),
                                            shape = RoundedCornerShape(8.dp)
                                        ) {
                                            Text("${length}w (+$pts)", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                        }
                                    }
                                }

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.End
                                ) {
                                    TextButton(onClick = {
                                        val list = playerScores.toMutableList()
                                        list[selectedPlayerTab] = list[selectedPlayerTab].copy(routePoints = 0)
                                        playerScores = list
                                    }) {
                                        Text("Routes wissen (0)", fontSize = 11.sp, color = WarningRed)
                                    }
                                }
                            }
                        }
                    }

                    // 2. Bestemmingskaarten (Tickets)
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                Text("2. Bestemmingskaarten (Tickets)", fontWeight = FontWeight.Bold, color = activeTrainColor)

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column {
                                        Text("Behaalde tickets (+)", fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                                        Text("+${activeScore.completedTickets} pt", fontSize = 12.sp, color = SuccessGreen, fontWeight = FontWeight.Bold)
                                    }
                                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                        listOf(5, 10, 20).forEach { add ->
                                            FilledTonalButton(
                                                onClick = {
                                                    val list = playerScores.toMutableList()
                                                    list[selectedPlayerTab] = list[selectedPlayerTab].copy(
                                                        completedTickets = list[selectedPlayerTab].completedTickets + add
                                                    )
                                                    playerScores = list
                                                },
                                                contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp),
                                                shape = RoundedCornerShape(6.dp)
                                            ) {
                                                Text("+$add", fontSize = 11.sp)
                                            }
                                        }
                                    }
                                }

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column {
                                        Text("Mislukte tickets (-)", fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                                        Text("-${activeScore.failedTickets} pt", fontSize = 12.sp, color = WarningRed, fontWeight = FontWeight.Bold)
                                    }
                                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                        listOf(5, 10, 20).forEach { add ->
                                            FilledTonalButton(
                                                onClick = {
                                                    val list = playerScores.toMutableList()
                                                    list[selectedPlayerTab] = list[selectedPlayerTab].copy(
                                                        failedTickets = list[selectedPlayerTab].failedTickets + add
                                                    )
                                                    playerScores = list
                                                },
                                                contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp),
                                                shape = RoundedCornerShape(6.dp)
                                            ) {
                                                Text("-$add", fontSize = 11.sp)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 3. Bonussen & Stations
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                Text("3. Bonussen & Stations", fontWeight = FontWeight.Bold, color = activeTrainColor)

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("Langste Route (+10 pt)", fontSize = 13.sp)
                                    Switch(
                                        checked = activeScore.hasLongestRoute,
                                        onCheckedChange = { checked ->
                                            val list = playerScores.toMutableList()
                                            list[selectedPlayerTab] = list[selectedPlayerTab].copy(hasLongestRoute = checked)
                                            playerScores = list
                                        }
                                    )
                                }

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("Globetrotter (+10 pt)", fontSize = 13.sp)
                                    Switch(
                                        checked = activeScore.hasGlobetrotter,
                                        onCheckedChange = { checked ->
                                            val list = playerScores.toMutableList()
                                            list[selectedPlayerTab] = list[selectedPlayerTab].copy(hasGlobetrotter = checked)
                                            playerScores = list
                                        }
                                    )
                                }

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column {
                                        Text("Overgebleven stations (4 pt elk)", fontSize = 13.sp)
                                        Text("${activeScore.unusedStations} stations = ${activeScore.unusedStations * 4} pt", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))
                                    }
                                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                        (0..3).forEach { st ->
                                            val isSelected = activeScore.unusedStations == st
                                            Box(
                                                modifier = Modifier
                                                    .size(28.dp)
                                                    .clip(RoundedCornerShape(6.dp))
                                                    .background(if (isSelected) TrainBlue else Color.Transparent)
                                                    .border(1.dp, TrainBlue, RoundedCornerShape(6.dp))
                                                    .clickable {
                                                        val list = playerScores.toMutableList()
                                                        list[selectedPlayerTab] = list[selectedPlayerTab].copy(unusedStations = st)
                                                        playerScores = list
                                                    },
                                                contentAlignment = Alignment.Center
                                            ) {
                                                Text(
                                                    "$st",
                                                    fontSize = 11.sp,
                                                    fontWeight = FontWeight.Bold,
                                                    color = if (isSelected) Color.White else TrainBlue
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Afrondknop
                Button(
                    onClick = {
                        val maxScore = calculatedTotals.maxOrNull() ?: 0
                        val winnerIdx = calculatedTotals.indexOfFirst { it == maxScore }
                        winnerPlayer = selectedPlayerNames.getOrElse(winnerIdx) { selectedPlayerNames.first() }
                        isGameOver = true
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = TrainBlue),
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text("Spel Afronden & Uitslag Bekijken 🏆", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                }
            }
        }
    }

    if (showHistoryDialog) {
        AlertDialog(
            onDismissRequest = { showHistoryDialog = false },
            title = { Text("Gelegde Routes Historie (${liveTurnHistory.size})") },
            text = {
                if (liveTurnHistory.isEmpty()) {
                    Text("Nog geen geregistreerde routes.")
                } else {
                    LazyColumn(modifier = Modifier.heightIn(max = 280.dp)) {
                        items(liveTurnHistory.reversed().size) { idx ->
                            val item = liveTurnHistory.reversed()[idx]
                            Column(modifier = Modifier.padding(vertical = 4.dp)) {
                                Text("${item.player}: ${item.description}", fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                                HorizontalDivider(modifier = Modifier.padding(top = 4.dp))
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
}
