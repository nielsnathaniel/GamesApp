package nl.nnbp.gamesapp.ui.screens.games.fiftyfifty

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.model.GameType
import nl.nnbp.gamesapp.data.model.Player
import nl.nnbp.gamesapp.data.model.PlayerScore
import nl.nnbp.gamesapp.ui.components.*
import nl.nnbp.gamesapp.ui.screens.games.SnelleEindscoreScreen
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SuccessGreen
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
    var selectedPlayerCount by remember { mutableIntStateOf(4) }
    var gameMode by remember { mutableStateOf("rondes") } // "rondes", "enkelePot", "snel"
    var targetRounds by remember { mutableIntStateOf(3) }
    var showTafelschikkingDialog by remember { mutableStateOf(false) }

    var currentRound by remember { mutableIntStateOf(1) }
    var roundPenalties by remember { mutableStateOf(mutableListOf<Int>()) }
    var hasFoxInHand by remember { mutableStateOf(mutableListOf<Boolean>()) }
    var totalFoxCount by remember { mutableStateOf(mutableListOf<Int>()) }
    var totalPenalties by remember { mutableStateOf(mutableListOf<Int>()) }
    var history by remember { mutableStateOf(mutableListOf<FiftyFiftyRoundRecord>()) }
    var showHistoryDialog by remember { mutableStateOf(false) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }
    var showEditScoresDialog by remember { mutableStateOf(false) }
    var startQuickScoreGame by remember { mutableStateOf(false) }

    if (startQuickScoreGame) {
        SnelleEindscoreScreen(
            gameName = "Fifty Fifty",
            playerNames = selectedPlayerNames,
            isLowestScoreWins = true,
            scoreUnit = "strafkaarten",
            onNavigateBack = { startQuickScoreGame = false }
        )
        return
    }

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

    val modeOptions = listOf(
        GameModeItem(
            id = "rondes",
            title = "Ronde per ronde",
            icon = Icons.Default.Casino,
            description = "🎮 Meerdere rondes spelen met cumulatieve strafkaarten. Pas op voor de vos!"
        ),
        GameModeItem(
            id = "enkelePot",
            title = "Enkele pot",
            icon = Icons.Default.LooksOne,
            description = "🃏 Eén enkele pot spelen en direct uitslag bepalen."
        ),
        GameModeItem(
            id = "snel",
            title = "Snelle eindscore",
            icon = Icons.Default.Bolt,
            description = "⚡️ Vul direct het totale aantal strafkaarten per speler in."
        )
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        GameLogoImage(gameType = GameType.FIFTY_FIFTY, size = 30.dp, cornerRadius = 8.dp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Fifty Fifty", fontWeight = FontWeight.Bold, fontSize = 18.sp)
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Terug")
                    }
                },
                actions = {
                    if (isGameStarted) {
                        IconButton(onClick = { showHistoryDialog = true }) {
                            Icon(Icons.Default.History, contentDescription = "Historie", tint = AccentOrange)
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
                            gameType = GameType.FIFTY_FIFTY,
                            subtitle = "White Goblin Games • Minste strafkaarten wint! 🦊🃏",
                            themeColor = AccentOrange
                        )
                    }

                    item {
                        GameModeSegmentedPicker(
                            options = modeOptions,
                            selectedId = gameMode,
                            onSelect = { gameMode = it },
                            themeColor = AccentOrange
                        )
                    }

                    if (gameMode == "rondes") {
                        item {
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
                                    Text("Doelaantal rondes:", fontWeight = FontWeight.SemiBold)
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        FilledTonalButton(
                                            onClick = { if (targetRounds > 1) targetRounds-- },
                                            contentPadding = PaddingValues(0.dp),
                                            modifier = Modifier.size(34.dp),
                                            shape = CircleShape
                                        ) {
                                            Text("-", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                                        }
                                        Text("$targetRounds", fontWeight = FontWeight.Bold, fontSize = 16.sp)
                                        FilledTonalButton(
                                            onClick = { if (targetRounds < 10) targetRounds++ },
                                            contentPadding = PaddingValues(0.dp),
                                            modifier = Modifier.size(34.dp),
                                            shape = CircleShape
                                        ) {
                                            Text("+", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    item {
                        PlayerCountPicker(
                            minPlayers = 2,
                            maxPlayers = 6,
                            selectedCount = selectedPlayerCount,
                            onSelect = { count ->
                                selectedPlayerCount = count
                                while (selectedPlayerNames.size > count) {
                                    selectedPlayerNames.removeAt(selectedPlayerNames.lastIndex)
                                }
                            },
                            themeColor = AccentOrange
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
                                selectedPlayerCount = seated.size.coerceIn(2, 6)
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
                                roundPenalties = MutableList(selectedPlayerNames.size) { 0 }
                                hasFoxInHand = MutableList(selectedPlayerNames.size) { false }
                                totalFoxCount = MutableList(selectedPlayerNames.size) { 0 }
                                totalPenalties = MutableList(selectedPlayerNames.size) { 0 }
                                currentRound = 1
                                history.clear()
                                isGameStarted = true
                            }
                        },
                        enabled = selectedPlayerNames.size >= 2,
                        colors = ButtonDefaults.buttonColors(containerColor = AccentOrange),
                        modifier = Modifier.fillMaxWidth().height(52.dp),
                        shape = RoundedCornerShape(14.dp)
                    ) {
                        Text(
                            when (gameMode) {
                                "snel" -> "⚡️ Snelle Eindscore Starten"
                                "enkelePot" -> "Start Enkele Pot (${selectedPlayerNames.size} spelers)"
                                else -> "Start Ronde 1 van $targetRounds (${selectedPlayerNames.size} spelers)"
                            },
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                        )
                    }
                }
            }
        } else {
            // IN-GAME FASE
            val scoresPairList = selectedPlayerNames.indices.map { i ->
                val total = totalPenalties.getOrElse(i) { 0 } + roundPenalties.getOrElse(i) { 0 }
                Pair(selectedPlayerNames[i], total)
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
                    // Header Status
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = AccentOrange.copy(alpha = 0.12f))
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .border(1.5.dp, AccentOrange.copy(alpha = 0.35f), RoundedCornerShape(14.dp))
                                    .padding(14.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Column {
                                    Text(
                                        if (gameMode == "enkelePot") "ENKELE POT" else "RONDE $currentRound VAN $targetRounds",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 11.sp,
                                        color = AccentOrange
                                    )
                                    Text("Minste strafkaarten wint", fontWeight = FontWeight.Bold, fontSize = 16.sp)
                                }
                                Surface(shape = RoundedCornerShape(8.dp), color = AccentOrange.copy(alpha = 0.2f)) {
                                    Text(
                                        "${selectedPlayerNames.size} spelers",
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = AccentOrange
                                    )
                                }
                            }
                        }
                    }

                    // Voskaart Regel Banner
                    item {
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = WarningRed.copy(alpha = 0.10f),
                            border = androidx.compose.foundation.BorderStroke(1.dp, WarningRed.copy(alpha = 0.3f))
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth().padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("🦊", fontSize = 22.sp)
                                Spacer(modifier = Modifier.width(10.dp))
                                Column {
                                    Text("Voskaart Regel", fontWeight = FontWeight.Bold, fontSize = 13.sp, color = WarningRed)
                                    Text(
                                        "De speler die aan het einde van het spel de vos op hand heeft verliest direct!",
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.75f)
                                    )
                                }
                            }
                        }
                    }

                    // Live Lead Indicator
                    item {
                        LiveGameLeadCard(
                            playerScores = scoresPairList,
                            isLowestScoreWins = true,
                            themeColor = SuccessGreen
                        )
                    }

                    // Spelerslijst met strafkaarten en vos-toggle
                    itemsIndexed(selectedPlayerNames) { idx, name ->
                        val roundVal = roundPenalties.getOrElse(idx) { 0 }
                        val totalVal = totalPenalties.getOrElse(idx) { 0 }
                        val effectiveTotal = totalVal + roundVal
                        val hasFox = hasFoxInHand.getOrElse(idx) { false }

                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = if (hasFox) WarningRed.copy(alpha = 0.08f) else MaterialTheme.colorScheme.surfaceVariant
                            )
                        ) {
                            Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text(name, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                                        if (hasFox) {
                                            Spacer(modifier = Modifier.width(6.dp))
                                            Surface(shape = RoundedCornerShape(4.dp), color = WarningRed) {
                                                Text("🦊 VOS (+10)", color = Color.White, fontSize = 9.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp))
                                            }
                                        } else if (totalFoxCount.getOrElse(idx) { 0 } > 0) {
                                            Spacer(modifier = Modifier.width(6.dp))
                                            Surface(shape = RoundedCornerShape(4.dp), color = WarningRed.copy(alpha = 0.2f)) {
                                                Text("🦊 ${totalFoxCount[idx]}x", color = WarningRed, fontSize = 9.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp))
                                            }
                                        }
                                    }
                                    Text(
                                        text = "$effectiveTotal strafkaarten",
                                        fontWeight = FontWeight.Black,
                                        fontSize = 15.sp,
                                        color = if (hasFox) WarningRed else AccentOrange
                                    )
                                }

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("Strafkaarten deze ronde: +$roundVal", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f))

                                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                                        FilledTonalButton(
                                            onClick = {
                                                if (roundVal > 0) {
                                                    val list = roundPenalties.toMutableList()
                                                    list[idx] = list[idx] - 1
                                                    roundPenalties = list
                                                }
                                            },
                                            contentPadding = PaddingValues(0.dp),
                                            modifier = Modifier.size(32.dp),
                                            shape = CircleShape
                                        ) {
                                            Text("-", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                                        }

                                        FilledTonalButton(
                                            onClick = {
                                                val list = roundPenalties.toMutableList()
                                                list[idx] = list[idx] + 1
                                                roundPenalties = list
                                            },
                                            contentPadding = PaddingValues(0.dp),
                                            modifier = Modifier.size(32.dp),
                                            shape = CircleShape
                                        ) {
                                            Text("+1", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                        }

                                        FilledTonalButton(
                                            onClick = {
                                                val list = roundPenalties.toMutableList()
                                                list[idx] = list[idx] + 5
                                                roundPenalties = list
                                            },
                                            contentPadding = PaddingValues(0.dp),
                                            modifier = Modifier.size(32.dp),
                                            shape = CircleShape
                                        ) {
                                            Text("+5", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                        }
                                    }
                                }

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("Vos op hand (+10 kaarten & verlies):", fontSize = 12.sp, color = if (hasFox) WarningRed else Color.Unspecified)
                                    Switch(
                                        checked = hasFox,
                                        onCheckedChange = { checked ->
                                            val list = hasFoxInHand.toMutableList()
                                            list[idx] = checked
                                            hasFoxInHand = list

                                            val penalties = roundPenalties.toMutableList()
                                            if (checked) {
                                                penalties[idx] = penalties[idx] + 10
                                            } else {
                                                penalties[idx] = (penalties[idx] - 10).coerceAtLeast(0)
                                            }
                                            roundPenalties = penalties
                                        }
                                    )
                                }
                            }
                        }
                    }
                }

                // Volgende Ronde of Afronden
                Button(
                    onClick = {
                        val isFinalRound = (gameMode == "enkelePot") || (currentRound >= targetRounds)
                        val newTotals = totalPenalties.indices.map { i ->
                            totalPenalties[i] + roundPenalties.getOrElse(i) { 0 }
                        }.toMutableList()
                        val newFoxCount = totalFoxCount.indices.map { i ->
                            totalFoxCount[i] + if (hasFoxInHand.getOrElse(i) { false }) 1 else 0
                        }.toMutableList()

                        totalPenalties = newTotals
                        totalFoxCount = newFoxCount

                        if (isFinalRound) {
                            // Bepaal winnaar: spelers met 0 vossen winnen ALTIJD van spelers met 1+ vossen
                            val sortedIndices = selectedPlayerNames.indices.sortedWith { i1, i2 ->
                                val v1 = newFoxCount.getOrElse(i1) { 0 }
                                val v2 = newFoxCount.getOrElse(i2) { 0 }
                                if (v1 != v2) {
                                    v1.compareTo(v2)
                                } else {
                                    newTotals[i1].compareTo(newTotals[i2])
                                }
                            }
                            val bestIdx = sortedIndices.first()
                            winnerPlayer = selectedPlayerNames[bestIdx]
                            isGameOver = true
                        } else {
                            // Volgende ronde
                            history.add(
                                FiftyFiftyRoundRecord(
                                    round = currentRound,
                                    penaltyCards = roundPenalties.toList(),
                                    hasFox = hasFoxInHand.toList(),
                                    totals = newTotals.toList()
                                )
                            )
                            roundPenalties = MutableList(selectedPlayerNames.size) { 0 }
                            hasFoxInHand = MutableList(selectedPlayerNames.size) { false }
                            currentRound++
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AccentOrange),
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    val isFinal = (gameMode == "enkelePot") || (currentRound >= targetRounds)
                    Text(
                        if (isFinal) "Spel Afronden & Uitslag Bekijken 🏆" else "Ronde $currentRound Afronden ➔",
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.titleMedium
                    )
                }
            }
        }
    }

    if (showHistoryDialog) {
        AlertDialog(
            onDismissRequest = { showHistoryDialog = false },
            title = { Text("Rondegeschiedenis (${history.size})") },
            text = {
                if (history.isEmpty()) {
                    Text("Nog geen afgeronde rondes.")
                } else {
                    LazyColumn(modifier = Modifier.heightIn(max = 280.dp)) {
                        items(history.size) { idx ->
                            val r = history[idx]
                            Column(modifier = Modifier.padding(vertical = 4.dp)) {
                                Text("Ronde ${r.round}:", fontWeight = FontWeight.Bold, fontSize = 13.sp)
                                selectedPlayerNames.forEachIndexed { pIdx, pName ->
                                    val pen = r.penaltyCards.getOrElse(pIdx) { 0 }
                                    val fox = r.hasFox.getOrElse(pIdx) { false }
                                    Text("• $pName: +$pen strafkaarten ${if (fox) "(🦊 Vos)" else ""}", fontSize = 12.sp)
                                }
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
