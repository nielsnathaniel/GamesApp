package nl.nnbp.gamesapp.ui.screens.games.balzakken

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
import nl.nnbp.gamesapp.data.model.RoundScoreDataPoint
import nl.nnbp.gamesapp.ui.audio.SoundManager
import nl.nnbp.gamesapp.ui.components.AppCard
import nl.nnbp.gamesapp.ui.components.InhaalslagBanner
import nl.nnbp.gamesapp.ui.components.SavedPlayersQuickChips
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.components.StartspelerKiezerDialog
import nl.nnbp.gamesapp.ui.components.TafelschikkingDialog
import nl.nnbp.gamesapp.ui.components.WieHeeftGelijkDialog
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SuccessGreen
import nl.nnbp.gamesapp.ui.theme.WarningRed

data class BalzakkenRoundRecord(
    val round: Int,
    val starter: String,
    val scoresThisRound: List<Int>,
    val totalsAfterRound: List<Int>,
    val specialEvents: List<String>
)

enum class BalzakStatus {
    GEEN,
    JUISTE_BALZAK,
    VALSE_BALZAK
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BalzakkenScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }
    val soundManager = remember { SoundManager.getInstance() }

    // Game states
    var isGameStarted by remember { mutableStateOf(false) }
    var selectedPlayerNames by remember { mutableStateOf(mutableListOf<String>()) }
    var showStartspelerDialog by remember { mutableStateOf(false) }
    var showTafelschikkingDialog by remember { mutableStateOf(false) }
    var showDisputeDialog by remember { mutableStateOf(false) }

    // Active in-game states
    var currentRound by remember { mutableStateOf(1) }
    var startPlayerIndex by remember { mutableStateOf(0) }
    var roundScores by remember { mutableStateOf(mutableListOf<Int>()) }
    var totalScores by remember { mutableStateOf(mutableListOf<Int>()) }
    var juisteBalzakken by remember { mutableStateOf(mutableListOf<Int>()) }
    var fouteBalzakken by remember { mutableStateOf(mutableListOf<Int>()) }
    var roundStatus by remember { mutableStateOf(mutableListOf<BalzakStatus>()) }
    var expandedPlayerIndex by remember { mutableStateOf<Int?>(null) }
    var history by remember { mutableStateOf(mutableListOf<BalzakkenRoundRecord>()) }
    var showHistorySheet by remember { mutableStateOf(false) }

    // Special rule alerts
    var specialRuleMessage by remember { mutableStateOf<String?>(null) }
    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }

    val currentStarterIndex = remember(startPlayerIndex, currentRound, selectedPlayerNames) {
        if (selectedPlayerNames.isEmpty()) 0 else (startPlayerIndex + (currentRound - 1)) % selectedPlayerNames.size
    }

    if (isGameOver && winnerPlayer != null) {
        val playerScores = selectedPlayerNames.indices.map { i ->
            PlayerScore(
                playerName = selectedPlayerNames[i],
                score = totalScores.getOrElse(i) { 0 },
                isWinner = selectedPlayerNames[i] == winnerPlayer,
                juisteBalzakken = juisteBalzakken.getOrElse(i) { 0 },
                fouteBalzakken = fouteBalzakken.getOrElse(i) { 0 }
            )
        }
        WinnaarScreen(
            gameName = "Balzakken",
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
                title = { Text("Balzakken", fontWeight = FontWeight.Bold) },
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
                        AppCard {
                            Text(
                                text = "Spelregels Balzakken 🎲",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Kaartspel waarbij de laagste score wint. Het spel stopt zodra iemand 100 strafpunten bereikt.",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "• BALZAK! = 0 strafpunten\n• Valse Balzak = +25 strafpunten\n• Exact 69 strafpunten = terugval naar 50 pt!\n• Exact 99 strafpunten = terugval naar 75 pt!",
                                style = MaterialTheme.typography.bodySmall,
                                color = AccentOrange
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
                        SectionTitle(title = "Deelnemers (${selectedPlayerNames.size})")
                        if (selectedPlayerNames.isEmpty()) {
                            Text(
                                text = "Tik hierboven op spelers om ze toe te voegen aan het potje.",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                            )
                        } else {
                            AppCard {
                                selectedPlayerNames.forEachIndexed { index, name ->
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(vertical = 4.dp),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text("${index + 1}. $name", fontWeight = FontWeight.SemiBold)
                                        IconButton(onClick = {
                                            val list = selectedPlayerNames.toMutableList()
                                            list.removeAt(index)
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
                        roundScores = MutableList(selectedPlayerNames.size) { 0 }
                        totalScores = MutableList(selectedPlayerNames.size) { 0 }
                        juisteBalzakken = MutableList(selectedPlayerNames.size) { 0 }
                        fouteBalzakken = MutableList(selectedPlayerNames.size) { 0 }
                        roundStatus = MutableList(selectedPlayerNames.size) { BalzakStatus.GEEN }
                        startPlayerIndex = if (selectedPlayerNames.isNotEmpty()) (0 until selectedPlayerNames.size).random() else 0
                        isGameStarted = true
                    },
                    enabled = selectedPlayerNames.size >= 2,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text("Start Potje (${selectedPlayerNames.size} spelers)", style = MaterialTheme.typography.titleMedium)
                }
            }
        } else {
            // SPELFASIS
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
                        // Startspeler banner
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
                                    Icon(Icons.Default.Casino, contentDescription = null, tint = AccentOrange)
                                    Spacer(modifier = Modifier.width(10.dp))
                                    Column {
                                        Text("Begint deze ronde:", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                        Text(
                                            text = selectedPlayerNames.getOrElse(currentStarterIndex) { "" },
                                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                                        )
                                    }
                                }
                                if (currentRound == 1) {
                                    TextButton(onClick = { showStartspelerDialog = true }) {
                                        Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(16.dp))
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text("Loten")
                                    }
                                } else {
                                    Text(
                                        text = "Ronde $currentRound",
                                        style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                                        color = PrimaryBlue
                                    )
                                }
                            }
                        }
                    }

                    item {
                        InhaalslagBanner(
                            playerNames = selectedPlayerNames,
                            scores = totalScores,
                            lowestWins = true
                        )
                    }

                    // Spelerskaarten
                    itemsIndexed(selectedPlayerNames) { index, playerName ->
                        val isStarter = index == currentStarterIndex
                        val isExpanded = expandedPlayerIndex == index
                        val currentTotal = totalScores.getOrElse(index) { 0 }
                        val currentRoundScore = roundScores.getOrElse(index) { 0 }
                        val status = roundStatus.getOrElse(index) { BalzakStatus.GEEN }

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
                                            text = "Strafpunten: $currentTotal / 100",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = if (currentTotal >= 80) WarningRed else Color.Gray
                                        )
                                        Row(
                                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                                            modifier = Modifier.padding(top = 2.dp)
                                        ) {
                                            Text("🎯 ${juisteBalzakken.getOrElse(index) { 0 }}", style = MaterialTheme.typography.labelSmall, color = SuccessGreen)
                                            Text("⚠️ ${fouteBalzakken.getOrElse(index) { 0 }}", style = MaterialTheme.typography.labelSmall, color = WarningRed)
                                            if (status == BalzakStatus.JUISTE_BALZAK) {
                                                Text("• 👑 BALZAK! (0)", style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold), color = AccentOrange)
                                            } else if (status == BalzakStatus.VALSE_BALZAK) {
                                                Text("• ⚠️ Valse (+25)", style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold), color = WarningRed)
                                            }
                                        }
                                    }

                                    Column(horizontalAlignment = Alignment.End) {
                                        Text(
                                            text = "+$currentRoundScore",
                                            style = MaterialTheme.typography.headlineSmall.copy(
                                                fontWeight = FontWeight.Bold,
                                                color = if (currentRoundScore > 0) WarningRed else if (status == BalzakStatus.JUISTE_BALZAK) SuccessGreen else MaterialTheme.colorScheme.onSurface
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
                                        HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))
                                        Spacer(modifier = Modifier.height(10.dp))

                                        // Knoppen voor BALZAK! en VALSE BALZAK
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                                        ) {
                                            Button(
                                                onClick = {
                                                    val newStatus = roundStatus.toMutableList()
                                                    val newScores = roundScores.toMutableList()
                                                    if (status == BalzakStatus.JUISTE_BALZAK) {
                                                        newStatus[index] = BalzakStatus.GEEN
                                                        newScores[index] = 0
                                                    } else {
                                                        newStatus[index] = BalzakStatus.JUISTE_BALZAK
                                                        newScores[index] = 0
                                                        soundManager.playBalzakSuccess()
                                                    }
                                                    roundStatus = newStatus
                                                    roundScores = newScores
                                                },
                                                modifier = Modifier.weight(1f),
                                                colors = ButtonDefaults.buttonColors(
                                                    containerColor = if (status == BalzakStatus.JUISTE_BALZAK) AccentOrange else AccentOrange.copy(alpha = 0.2f),
                                                    contentColor = if (status == BalzakStatus.JUISTE_BALZAK) Color.White else AccentOrange
                                                ),
                                                shape = RoundedCornerShape(8.dp)
                                            ) {
                                                Text("👑 BALZAK! (0)", fontWeight = FontWeight.Bold)
                                            }

                                            Button(
                                                onClick = {
                                                    val newStatus = roundStatus.toMutableList()
                                                    val newScores = roundScores.toMutableList()
                                                    if (status == BalzakStatus.VALSE_BALZAK) {
                                                        newStatus[index] = BalzakStatus.GEEN
                                                        newScores[index] = 0
                                                    } else {
                                                        newStatus[index] = BalzakStatus.VALSE_BALZAK
                                                        newScores[index] = 25
                                                        soundManager.playBalzakFail()
                                                    }
                                                    roundStatus = newStatus
                                                    roundScores = newScores
                                                },
                                                        newStatus[index] = BalzakStatus.GEEN
                                                        newScores[index] = 0
                                                    } else {
                                                        newStatus[index] = BalzakStatus.VALSE_BALZAK
                                                        newScores[index] = 25
                                                        soundManager.playBalzakFail()
                                                    }
                                                    roundStatus = newStatus
                                                    roundScores = newScores
                                                },
                                                modifier = Modifier.weight(1f),
                                                colors = ButtonDefaults.buttonColors(
                                                    containerColor = if (status == BalzakStatus.VALSE_BALZAK) WarningRed else WarningRed.copy(alpha = 0.2f),
                                                    contentColor = if (status == BalzakStatus.VALSE_BALZAK) Color.White else WarningRed
                                                ),
                                                shape = RoundedCornerShape(8.dp)
                                            ) {
                                                Text("⚠️ Valse (+25)", fontWeight = FontWeight.Bold)
                                            }
                                        }

                                        Spacer(modifier = Modifier.height(10.dp))

                                        // Handkaarten snelle knoppen: -1, +1, +5, +11
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                                        ) {
                                            FilledTonalButton(
                                                onClick = {
                                                    val list = roundScores.toMutableList()
                                                    list[index] = maxOf(0, list[index] - 1)
                                                    roundScores = list
                                                    val statList = roundStatus.toMutableList()
                                                    statList[index] = BalzakStatus.GEEN
                                                    roundStatus = statList
                                                },
                                                modifier = Modifier.weight(1f),
                                                shape = RoundedCornerShape(8.dp)
                                            ) {
                                                Text("-1", fontWeight = FontWeight.Bold)
                                            }

                                            FilledTonalButton(
                                                onClick = {
                                                    val list = roundScores.toMutableList()
                                                    list[index] += 1
                                                    roundScores = list
                                                    val statList = roundStatus.toMutableList()
                                                    statList[index] = BalzakStatus.GEEN
                                                    roundStatus = statList
                                                },
                                                modifier = Modifier.weight(1f),
                                                shape = RoundedCornerShape(8.dp)
                                            ) {
                                                Text("+1", fontWeight = FontWeight.Bold)
                                            }

                                            FilledTonalButton(
                                                onClick = {
                                                    val list = roundScores.toMutableList()
                                                    list[index] += 5
                                                    roundScores = list
                                                    val statList = roundStatus.toMutableList()
                                                    statList[index] = BalzakStatus.GEEN
                                                    roundStatus = statList
                                                },
                                                modifier = Modifier.weight(1f),
                                                shape = RoundedCornerShape(8.dp)
                                            ) {
                                                Text("+5", fontWeight = FontWeight.Bold)
                                            }

                                            FilledTonalButton(
                                                onClick = {
                                                    val list = roundScores.toMutableList()
                                                    list[index] += 11
                                                    roundScores = list
                                                    val statList = roundStatus.toMutableList()
                                                    statList[index] = BalzakStatus.GEEN
                                                    roundStatus = statList
                                                },
                                                modifier = Modifier.weight(1f),
                                                shape = RoundedCornerShape(8.dp)
                                            ) {
                                                Text("+11", fontWeight = FontWeight.Bold)
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
                        val events = mutableListOf<String>()
                        val newTotals = totalScores.toMutableList()
                        val newJuiste = juisteBalzakken.toMutableList()
                        val newFoute = fouteBalzakken.toMutableList()

                        selectedPlayerNames.indices.forEach { i ->
                            newTotals[i] += roundScores.getOrElse(i) { 0 }

                            if (roundStatus.getOrElse(i) { BalzakStatus.GEEN } == BalzakStatus.JUISTE_BALZAK) {
                                newJuiste[i] += 1
                                events.add("🎯 ${selectedPlayerNames[i]} had een Goeie Balzak! (0 pt)")
                            } else if (roundStatus.getOrElse(i) { BalzakStatus.GEEN } == BalzakStatus.VALSE_BALZAK) {
                                newFoute[i] += 1
                                events.add("⚠️ ${selectedPlayerNames[i]} had een Valse Balzak! (+25 pt)")
                            }

                            // 69 REGEL: Precies 69 -> drop naar 50 punten!
                            if (newTotals[i] == 69) {
                                newTotals[i] = 50
                                events.add("${selectedPlayerNames[i]} had exact 69 punten en gaat terug naar 50 punten! 🎉")
                            }
                            // 99 REGEL: Precies 99 -> drop naar 75 punten!
                            else if (newTotals[i] == 99) {
                                newTotals[i] = 75
                                events.add("${selectedPlayerNames[i]} had exact 99 punten en gaat terug naar 75 punten! 🎉")
                            }
                        }

                        totalScores = newTotals
                        juisteBalzakken = newJuiste
                        fouteBalzakken = newFoute

                        val starter = selectedPlayerNames.getOrElse(currentStarterIndex) { "Speler 1" }
                        val record = BalzakkenRoundRecord(
                            round = currentRound,
                            starter = starter,
                            scoresThisRound = roundScores.toList(),
                            totalsAfterRound = newTotals.toList(),
                            specialEvents = events
                        )
                        val newHistory = history.toMutableList()
                        newHistory.add(record)
                        history = newHistory

                        // Check of iemand 100 strafpunten heeft bereikt
                        val hasReachedEnd = newTotals.any { it >= 100 }
                        if (hasReachedEnd) {
                            // Winnaar is speler met minste strafpunten!
                            val minScore = newTotals.minOrNull() ?: 0
                            val winnerIdx = newTotals.indexOf(minScore)
                            val winner = selectedPlayerNames.getOrElse(winnerIdx) { "" }
                            winnerPlayer = winner

                            // Opslaan naar ScoreManager
                            val detailed = selectedPlayerNames.indices.map { idx ->
                                PlayerScoreDetail(
                                    name = selectedPlayerNames[idx],
                                    score = newTotals[idx],
                                    juisteBalzakken = newJuiste[idx],
                                    fouteBalzakken = newFoute[idx]
                                )
                            }
                            scoreManager.saveGame(
                                gameName = "Balzakken",
                                playerDetailedScores = detailed,
                                winnerName = winner
                            )
                            isGameOver = true
                        } else {
                            if (events.isNotEmpty()) {
                                specialRuleMessage = events.joinToString("\n")
                            }
                            currentRound += 1
                            roundScores = MutableList(selectedPlayerNames.size) { 0 }
                            roundStatus = MutableList(selectedPlayerNames.size) { BalzakStatus.GEEN }
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

    specialRuleMessage?.let { msg ->
        AlertDialog(
            onDismissRequest = { specialRuleMessage = null },
            title = { Text("Lekkere Tussenstand! 🎉") },
            text = { Text(msg) },
            confirmButton = {
                Button(onClick = { specialRuleMessage = null }) {
                    Text("Top!")
                }
            }
        )
    }

    if (showHistorySheet) {
        AlertDialog(
            onDismissRequest = { showHistorySheet = false },
            title = { Text("Rondehistorie Balzakken") },
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
                                    text = "Ronde ${entry.round} • Begonnen door ${entry.starter}",
                                    fontWeight = FontWeight.Bold,
                                    style = MaterialTheme.typography.labelLarge
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                selectedPlayerNames.forEachIndexed { sIdx, pName ->
                                    val pts = entry.scoresThisRound.getOrElse(sIdx) { 0 }
                                    val total = entry.totalsAfterRound.getOrElse(sIdx) { 0 }
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween
                                    ) {
                                        Text(pName, style = MaterialTheme.typography.bodySmall)
                                        Text("+$pts pt (totaal: $total)", style = MaterialTheme.typography.bodySmall, color = PrimaryBlue)
                                    }
                                }
                                if (entry.specialEvents.isNotEmpty()) {
                                    Spacer(modifier = Modifier.height(4.dp))
                                    entry.specialEvents.forEach { ev ->
                                        Text("✨ $ev", style = MaterialTheme.typography.labelSmall, color = AccentOrange)
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
            initialGameFilter = "Balzakken",
            onDismiss = { showDisputeDialog = false }
        )
    }
}
