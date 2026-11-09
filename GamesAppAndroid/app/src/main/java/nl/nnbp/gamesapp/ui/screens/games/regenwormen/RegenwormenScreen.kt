package nl.nnbp.gamesapp.ui.screens.games.regenwormen

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
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
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
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

val playerPalette = listOf(
    Color(0xFF29B6F6), // Sky Blue
    Color(0xFFFF7043), // Coral Orange
    Color(0xFFAB47BC), // Purple
    Color(0xFF66BB6A), // Green
    Color(0xFFEC407A), // Pink
    Color(0xFF26C6DA), // Cyan
    Color(0xFFFFCA28)  // Amber
)

fun getStoneWorms(stone: Int): Int = when (stone) {
    in 21..24 -> 1
    in 25..28 -> 2
    in 29..32 -> 3
    in 33..36 -> 4
    else -> 0
}

data class RegenwormenTurnRecord(
    val turn: Int,
    val player: String,
    val description: String,
    val tableStones: List<Int>,
    val playerStacks: List<List<Int>>
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RegenwormenScreen(
    onNavigateBack: () -> Unit,
    autoResume: Boolean = false
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }
    val haptic = LocalHapticFeedback.current

    val session = remember { activeGameManager.activeSession.value }
    val isResumeActive = autoResume && session != null && session.gameName == "Regenwormen"

    var isGameStarted by remember { mutableStateOf(isResumeActive) }
    var selectedPlayerNames by remember {
        mutableStateOf(
            if (isResumeActive && session != null) session.playerNames.toMutableList()
            else mutableListOf<String>()
        )
    }
    var selectedPlayerCount by remember { mutableIntStateOf(3) }
    var gameMode by remember { mutableStateOf("beurt") } // "beurt", "stenen", "snel"
    var showTafelschikkingDialog by remember { mutableStateOf(false) }

    // Quick score screen navigation
    var startQuickScoreGame by remember { mutableStateOf(false) }
    if (startQuickScoreGame) {
        SnelleEindscoreScreen(
            gameName = "Regenwormen",
            playerNames = selectedPlayerNames,
            isLowestScoreWins = false,
            scoreUnit = "wormen",
            onNavigateBack = { startQuickScoreGame = false }
        )
        return
    }

    // In-game states (both for beurt and stenen modes)
    var activePlayerIndex by remember { mutableIntStateOf(0) }
    var turnNumber by remember { mutableIntStateOf(1) }
    var tableStones by remember { mutableStateOf((21..36).toMutableList()) }
    var flippedStones by remember { mutableStateOf(mutableSetOf<Int>()) }
    var playerStacks by remember { mutableStateOf(mutableListOf<MutableList<Int>>()) }
    var selectedAssignPlayerIndex by remember { mutableIntStateOf(0) }
    var turnHistory by remember { mutableStateOf(mutableListOf<RegenwormenTurnRecord>()) }
    var showHistoryDialog by remember { mutableStateOf(false) }
    var showMissedRollConfirm by remember { mutableStateOf(false) }
    var pendingTransfer by remember { mutableStateOf<Triple<Int, Int, Int>?>(null) } // stone, from, to
    var statusFeedback by remember { mutableStateOf<String?>(null) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }

    fun calculateWormsFor(index: Int): Int {
        val stack = playerStacks.getOrNull(index) ?: return 0
        return stack.sumOf { getStoneWorms(it) }
    }

    fun saveDraft() {
        if (selectedPlayerNames.isEmpty() || !isGameStarted) return
        val scoreSummary = selectedPlayerNames.indices.joinToString(", ") { "${selectedPlayerNames[it]}:${calculateWormsFor(it)}" }
        val summary = "${selectedPlayerNames.size} spelers • Stand: $scoreSummary"
        val state = mutableMapOf<String, String>()
        state["turnNumber"] = turnNumber.toString()
        state["activePlayerIndex"] = activePlayerIndex.toString()
        state["gameMode"] = gameMode
        state["tableStones"] = tableStones.joinToString(",")
        state["flippedStones"] = flippedStones.joinToString(",")
        for (i in selectedPlayerNames.indices) {
            state["stack_$i"] = (playerStacks.getOrNull(i) ?: emptyList()).joinToString(",")
        }

        activeGameManager.saveActiveGame(
            gameName = "Regenwormen",
            playerNames = selectedPlayerNames,
            currentRound = turnNumber,
            summary = summary,
            state = state
        )
    }

    LaunchedEffect(isResumeActive) {
        if (isResumeActive && session != null) {
            session.stateData["turnNumber"]?.toIntOrNull()?.let { turnNumber = it }
            session.stateData["activePlayerIndex"]?.toIntOrNull()?.let { activePlayerIndex = it }
            session.stateData["gameMode"]?.let { gameMode = it }
            session.stateData["tableStones"]?.let { t ->
                tableStones = t.split(",").mapNotNull { it.toIntOrNull() }.toMutableList()
            }
            session.stateData["flippedStones"]?.let { f ->
                flippedStones = f.split(",").mapNotNull { it.toIntOrNull() }.toMutableSet()
            }
            val restoredStacks = mutableListOf<MutableList<Int>>()
            for (i in selectedPlayerNames.indices) {
                val st = session.stateData["stack_$i"] ?: ""
                val list = st.split(",").mapNotNull { it.toIntOrNull() }.toMutableList()
                restoredStacks.add(list)
            }
            if (restoredStacks.size == selectedPlayerNames.size) {
                playerStacks = restoredStacks
            }
        }
    }

    if (isGameOver && winnerPlayer != null) {
        val playerScores = selectedPlayerNames.indices.map { i ->
            PlayerScore(
                playerName = selectedPlayerNames[i],
                score = calculateWormsFor(i),
                isWinner = selectedPlayerNames[i] == winnerPlayer
            )
        }
        WinnaarScreen(
            gameName = "Regenwormen",
            winnerName = winnerPlayer!!,
            scores = playerScores,
            onFinish = {
                activeGameManager.clearActiveGame()
                onNavigateBack()
            }
        )
        return
    }

    val modeOptions = listOf(
        GameModeItem(
            id = "beurt",
            title = "Beurt voor beurt",
            icon = Icons.Default.Casino,
            description = "🎮 Houd tijdens het spelen elke beurt bij, pak stenen van de barbecue of steel de bovenste steen van een medespeler!"
        ),
        GameModeItem(
            id = "stenen",
            title = "Stenen kiezen",
            icon = Icons.Default.Apps,
            description = "🎲 Wijs aan het einde van het spel direct de stenen aan per speler. Elke steen kan maar 1x gekozen worden en kleurt mee."
        ),
        GameModeItem(
            id = "snel",
            title = "Alleen wormen",
            icon = Icons.Default.Bolt,
            description = "⚡️ Vul direct het uiteindelijke aantal wormen per speler in zonder stenen te selecteren."
        )
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        GameLogoImage(gameType = GameType.REGENWORMEN, size = 30.dp, cornerRadius = 8.dp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Regenwormen", fontWeight = FontWeight.Bold, fontSize = 18.sp)
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
                            gameType = GameType.REGENWORMEN,
                            subtitle = "Reiner Knizia • Meeste wormen wint! 🪱",
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

                    item {
                        PlayerCountPicker(
                            minPlayers = 2,
                            maxPlayers = 7,
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
                                selectedPlayerCount = seated.size.coerceIn(2, 7)
                                selectedPlayerNames = seated.take(selectedPlayerCount).toMutableList()
                            }
                        )
                    }

                    item {
                        SectionTitle(title = "Deelnemers (${selectedPlayerNames.size} / $selectedPlayerCount)")
                        if (selectedPlayerNames.isEmpty()) {
                            Text(
                                text = "Tik hierboven op spelers om ze aan het spel toe te voegen.",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                            )
                        } else {
                            AppCard {
                                selectedPlayerNames.forEachIndexed { idx, name ->
                                    val col = playerPalette[idx % playerPalette.size]
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
                                                    .size(24.dp)
                                                    .clip(CircleShape)
                                                    .background(col.copy(alpha = 0.2f)),
                                                contentAlignment = Alignment.Center
                                            ) {
                                                Text("${idx + 1}", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = col)
                                            }
                                            Spacer(modifier = Modifier.width(10.dp))
                                            Text(name, fontWeight = FontWeight.SemiBold)
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
                                tableStones = (21..36).toMutableList()
                                flippedStones = mutableSetOf()
                                playerStacks = selectedPlayerNames.indices.map { mutableListOf<Int>() }.toMutableList()
                                activePlayerIndex = (0 until selectedPlayerNames.size).random()
                                turnNumber = 1
                                turnHistory.clear()
                                isGameStarted = true
                                saveDraft()
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
                                "stenen" -> "🎲 Stenen Aanwijzen (${selectedPlayerNames.size} spelers)"
                                else -> "🎮 Start Beurtbegeleider (${selectedPlayerNames.size} spelers)"
                            },
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                        )
                    }
                }
            }
        } else {
            // IN-GAME FASE
            val scoresPairList = selectedPlayerNames.indices.map { i ->
                Pair(selectedPlayerNames[i], calculateWormsFor(i))
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
                    // Modus-switch tabs tijdens het spel
                    item {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(10.dp))
                                .background(MaterialTheme.colorScheme.surfaceVariant)
                                .padding(3.dp)
                        ) {
                            listOf("beurt" to "Beurt voor beurt", "stenen" to "Eindstand stenen").forEach { (id, label) ->
                                val isSel = gameMode == id
                                Box(
                                    modifier = Modifier
                                        .weight(1f)
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(if (isSel) AccentOrange else Color.Transparent)
                                        .clickable { gameMode = id }
                                        .padding(vertical = 8.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = label,
                                        fontWeight = if (isSel) FontWeight.Bold else FontWeight.Medium,
                                        color = if (isSel) Color.White else MaterialTheme.colorScheme.onSurface,
                                        fontSize = 13.sp
                                    )
                                }
                            }
                        }
                    }

                    // Live Lead Indicator
                    item {
                        LiveGameLeadCard(
                            playerScores = scoresPairList,
                            isLowestScoreWins = false,
                            themeColor = AccentOrange
                        )
                    }

                    if (statusFeedback != null) {
                        item {
                            Surface(
                                shape = RoundedCornerShape(10.dp),
                                color = SuccessGreen.copy(alpha = 0.12f),
                                border = androidx.compose.foundation.BorderStroke(1.dp, SuccessGreen.copy(alpha = 0.3f))
                            ) {
                                Row(
                                    modifier = Modifier.fillMaxWidth().padding(10.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(Icons.Default.CheckCircle, contentDescription = null, tint = SuccessGreen, modifier = Modifier.size(16.dp))
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(statusFeedback!!, fontSize = 12.sp, fontWeight = FontWeight.Medium, color = MaterialTheme.colorScheme.onSurface)
                                }
                            }
                        }
                    }

                    if (gameMode == "beurt") {
                        // BEURT VOOR BEURT
                        val activePlayerName = selectedPlayerNames.getOrElse(activePlayerIndex) { "" }
                        val activeColor = playerPalette[activePlayerIndex % playerPalette.size]

                        item {
                            Card(
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(14.dp),
                                colors = CardDefaults.cardColors(containerColor = activeColor.copy(alpha = 0.12f))
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .border(1.5.dp, activeColor.copy(alpha = 0.4f), RoundedCornerShape(14.dp))
                                        .padding(14.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Box(
                                            modifier = Modifier
                                                .size(40.dp)
                                                .clip(CircleShape)
                                                .background(activeColor),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Text(
                                                activePlayerName.take(2).uppercase(),
                                                color = Color.White,
                                                fontWeight = FontWeight.Bold
                                            )
                                        }
                                        Spacer(modifier = Modifier.width(12.dp))
                                        Column {
                                            Text("AAN DE BEURT • BEURT $turnNumber", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = activeColor)
                                            Text(activePlayerName, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                                        }
                                    }

                                    Surface(
                                        shape = RoundedCornerShape(8.dp),
                                        color = activeColor.copy(alpha = 0.2f)
                                    ) {
                                        val stoneCount = playerStacks.getOrNull(activePlayerIndex)?.size ?: 0
                                        Text(
                                            "$stoneCount stenen",
                                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                            fontSize = 12.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = activeColor
                                        )
                                    }
                                }
                            }
                        }

                        // BBQ Stenen
                        item {
                            SectionTitle(title = "Stenen op de Barbecue (${tableStones.size} open)")
                            if (tableStones.isEmpty()) {
                                Text("De barbecue is leeg! Tijd om het spel af te ronden.", color = AccentOrange, fontSize = 13.sp)
                            } else {
                                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                    val rows = tableStones.chunked(4)
                                    rows.forEach { rowStones ->
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                                        ) {
                                            rowStones.forEach { stone ->
                                                val worms = getStoneWorms(stone)
                                                Box(
                                                    modifier = Modifier
                                                        .weight(1f)
                                                        .clip(RoundedCornerShape(10.dp))
                                                        .background(MaterialTheme.colorScheme.surfaceVariant)
                                                        .border(1.dp, AccentOrange.copy(alpha = 0.4f), RoundedCornerShape(10.dp))
                                                        .clickable {
                                                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                                            // Pak steen van tafel
                                                            tableStones.remove(stone)
                                                            playerStacks[activePlayerIndex].add(stone)
                                                            turnHistory.add(
                                                                RegenwormenTurnRecord(
                                                                    turn = turnNumber,
                                                                    player = activePlayerName,
                                                                    description = "$activePlayerName pakt steen $stone ($worms 🪱)",
                                                                    tableStones = tableStones.toList(),
                                                                    playerStacks = playerStacks.map { it.toList() }
                                                                )
                                                            )
                                                            statusFeedback = "$activePlayerName pakt steen $stone!"
                                                            activePlayerIndex = (activePlayerIndex + 1) % selectedPlayerNames.size
                                                            turnNumber++
                                                            saveDraft()
                                                        }
                                                        .padding(vertical = 8.dp),
                                                    contentAlignment = Alignment.Center
                                                ) {
                                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                                        Text("$stone", fontWeight = FontWeight.Black, fontSize = 16.sp)
                                                        Text("🪱".repeat(worms), fontSize = 10.sp)
                                                    }
                                                }
                                            }
                                            // Padding fill
                                            if (rowStones.size < 4) {
                                                repeat(4 - rowStones.size) {
                                                    Spacer(modifier = Modifier.weight(1f))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Steen Stelen van Medespelers
                        item {
                            SectionTitle(title = "Steen Stelen (Bovenste steen)")
                            val otherPlayers = selectedPlayerNames.indices.filter { it != activePlayerIndex }
                            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                otherPlayers.forEach { otherIdx ->
                                    val otherName = selectedPlayerNames[otherIdx]
                                    val otherStack = playerStacks.getOrNull(otherIdx) ?: emptyList()
                                    val topStone = otherStack.lastOrNull()
                                    val otherColor = playerPalette[otherIdx % playerPalette.size]

                                    Card(
                                        modifier = Modifier.fillMaxWidth(),
                                        shape = RoundedCornerShape(12.dp),
                                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                                    ) {
                                        Row(
                                            modifier = Modifier.fillMaxWidth().padding(12.dp),
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.SpaceBetween
                                        ) {
                                            Row(verticalAlignment = Alignment.CenterVertically) {
                                                Box(
                                                    modifier = Modifier.size(10.dp).clip(CircleShape).background(otherColor)
                                                )
                                                Spacer(modifier = Modifier.width(8.dp))
                                                Column {
                                                    Text(otherName, fontWeight = FontWeight.SemiBold)
                                                    Text("${otherStack.size} stenen in stapel", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))
                                                }
                                            }

                                            if (topStone != null) {
                                                val worms = getStoneWorms(topStone)
                                                Button(
                                                    onClick = {
                                                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                                        playerStacks[otherIdx].removeAt(playerStacks[otherIdx].lastIndex)
                                                        playerStacks[activePlayerIndex].add(topStone)
                                                        turnHistory.add(
                                                            RegenwormenTurnRecord(
                                                                turn = turnNumber,
                                                                player = activePlayerName,
                                                                description = "$activePlayerName steelt steen $topStone ($worms 🪱) van $otherName",
                                                                tableStones = tableStones.toList(),
                                                                playerStacks = playerStacks.map { it.toList() }
                                                            )
                                                        )
                                                        statusFeedback = "$activePlayerName steelt steen $topStone van $otherName!"
                                                        activePlayerIndex = (activePlayerIndex + 1) % selectedPlayerNames.size
                                                        turnNumber++
                                                        saveDraft()
                                                    },
                                                    colors = ButtonDefaults.buttonColors(containerColor = AccentOrange.copy(alpha = 0.85f)),
                                                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp),
                                                    shape = RoundedCornerShape(8.dp)
                                                ) {
                                                    Text("Steel $topStone ($worms 🪱)", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                                }
                                            } else {
                                                Text("Geen stenen", fontSize = 11.sp, color = Color.Gray)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Mislukte Worp Knop
                        item {
                            OutlinedButton(
                                onClick = { showMissedRollConfirm = true },
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = WarningRed),
                                border = androidx.compose.foundation.BorderStroke(1.dp, WarningRed.copy(alpha = 0.4f)),
                                modifier = Modifier.fillMaxWidth().height(48.dp),
                                shape = RoundedCornerShape(12.dp)
                            ) {
                                Icon(Icons.Default.Close, contentDescription = null, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Mislukte Worp ($activePlayerName)")
                            }
                        }
                    } else {
                        // STENEN KIEZEN (Eindstand)
                        item {
                            Text("Kies een speler om stenen aan toe te wijzen:", fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                            Spacer(modifier = Modifier.height(6.dp))
                            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                itemsIndexed(selectedPlayerNames) { idx, name ->
                                    val isSel = selectedAssignPlayerIndex == idx
                                    val pColor = playerPalette[idx % playerPalette.size]
                                    val wormTotal = calculateWormsFor(idx)
                                    val stoneCount = playerStacks.getOrNull(idx)?.size ?: 0

                                    Surface(
                                        shape = RoundedCornerShape(10.dp),
                                        color = if (isSel) pColor else pColor.copy(alpha = 0.12f),
                                        border = androidx.compose.foundation.BorderStroke(1.5.dp, pColor),
                                        modifier = Modifier.clickable { selectedAssignPlayerIndex = idx }
                                    ) {
                                        Column(
                                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                                            horizontalAlignment = Alignment.CenterHorizontally
                                        ) {
                                            Text(name, fontWeight = FontWeight.Bold, color = if (isSel) Color.White else pColor, fontSize = 13.sp)
                                            Text("$wormTotal 🪱 ($stoneCount stenen)", fontSize = 11.sp, color = if (isSel) Color.White else Color.Gray)
                                        }
                                    }
                                }
                            }
                        }

                        item {
                            SectionTitle(title = "Alle Stenen (21 t/m 36)")
                            val allStones = 21..36
                            val rows = allStones.chunked(4)
                            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                rows.forEach { rowStones ->
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        rowStones.forEach { stone ->
                                            val ownerIndex = playerStacks.indexOfFirst { it.contains(stone) }
                                            val ownerName = if (ownerIndex >= 0) selectedPlayerNames[ownerIndex] else null
                                            val ownerColor = if (ownerIndex >= 0) playerPalette[ownerIndex % playerPalette.size] else Color.Gray
                                            val worms = getStoneWorms(stone)

                                            Box(
                                                modifier = Modifier
                                                    .weight(1f)
                                                    .clip(RoundedCornerShape(10.dp))
                                                    .background(if (ownerIndex >= 0) ownerColor.copy(alpha = 0.2f) else MaterialTheme.colorScheme.surfaceVariant)
                                                    .border(
                                                        width = if (ownerIndex >= 0) 2.dp else 1.dp,
                                                        color = if (ownerIndex >= 0) ownerColor else AccentOrange.copy(alpha = 0.3f),
                                                        shape = RoundedCornerShape(10.dp)
                                                    )
                                                    .clickable {
                                                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                                        if (ownerIndex == selectedAssignPlayerIndex) {
                                                            // Deselect
                                                            playerStacks[selectedAssignPlayerIndex].remove(stone)
                                                        } else if (ownerIndex >= 0) {
                                                            // Transfer
                                                            pendingTransfer = Triple(stone, ownerIndex, selectedAssignPlayerIndex)
                                                        } else {
                                                            // Assign
                                                            playerStacks[selectedAssignPlayerIndex].add(stone)
                                                        }
                                                    }
                                                    .padding(vertical = 8.dp),
                                                contentAlignment = Alignment.Center
                                            ) {
                                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                                    Text("$stone", fontWeight = FontWeight.Black, fontSize = 16.sp)
                                                    Text("🪱".repeat(worms), fontSize = 10.sp)
                                                    Text(
                                                        ownerName ?: "Vrij",
                                                        fontSize = 9.sp,
                                                        fontWeight = FontWeight.Bold,
                                                        color = if (ownerIndex >= 0) ownerColor else Color.Gray
                                                    )
                                                }
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
                        val maxWorms = selectedPlayerNames.indices.maxOfOrNull { calculateWormsFor(it) } ?: 0
                        val winner = selectedPlayerNames.indices.firstOrNull { calculateWormsFor(it) == maxWorms }
                        winnerPlayer = if (winner != null) selectedPlayerNames[winner] else selectedPlayerNames.firstOrNull()
                        isGameOver = true
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AccentOrange),
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text("Spel Afronden & Uitslag Bekijken 🏆", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                }
            }
        }
    }

    // Mislukte worp dialog
    if (showMissedRollConfirm) {
        val activeName = selectedPlayerNames.getOrElse(activePlayerIndex) { "" }
        AlertDialog(
            onDismissRequest = { showMissedRollConfirm = false },
            title = { Text("Mislukte Worp?") },
            text = {
                Text("De bovenste steen van $activeName gaat terug naar tafel en de hoogste open steen op tafel wordt omgedraaid.")
            },
            confirmButton = {
                Button(
                    onClick = {
                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        val activeStack = playerStacks.getOrNull(activePlayerIndex)
                        if (!activeStack.isNullOrEmpty()) {
                            val returnedStone = activeStack.removeAt(activeStack.lastIndex)
                            tableStones.add(returnedStone)
                            tableStones.sort()
                        }
                        // Draai hoogste open steen om
                        val highest = tableStones.maxOrNull()
                        if (highest != null) {
                            tableStones.remove(highest)
                            flippedStones.add(highest)
                        }
                        statusFeedback = "Mislukte beurt van $activeName afgehandeld."
                        activePlayerIndex = (activePlayerIndex + 1) % selectedPlayerNames.size
                        turnNumber++
                        saveDraft()
                        showMissedRollConfirm = false
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = WarningRed)
                ) {
                    Text("Bevestig Mislukking")
                }
            },
            dismissButton = {
                TextButton(onClick = { showMissedRollConfirm = false }) {
                    Text("Annuleren")
                }
            }
        )
    }

    // Transfer dialog
    if (pendingTransfer != null) {
        val (stone, fromIdx, toIdx) = pendingTransfer!!
        val fromName = selectedPlayerNames.getOrElse(fromIdx) { "" }
        val toName = selectedPlayerNames.getOrElse(toIdx) { "" }
        AlertDialog(
            onDismissRequest = { pendingTransfer = null },
            title = { Text("Steen overdragen?") },
            text = {
                Text("Steen $stone is momenteel van $fromName. Wil je deze toewijzen aan $toName?")
            },
            confirmButton = {
                Button(
                    onClick = {
                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        playerStacks[fromIdx].remove(stone)
                        playerStacks[toIdx].add(stone)
                        pendingTransfer = null
                    }
                ) {
                    Text("Overdragen aan $toName")
                }
            },
            dismissButton = {
                TextButton(onClick = { pendingTransfer = null }) {
                    Text("Annuleren")
                }
            }
        )
    }

    // Historie dialog
    if (showHistoryDialog) {
        AlertDialog(
            onDismissRequest = { showHistoryDialog = false },
            title = { Text("Beurtenhistorie (${turnHistory.size})") },
            text = {
                if (turnHistory.isEmpty()) {
                    Text("Nog geen geregistreerde beurten.")
                } else {
                    LazyColumn(modifier = Modifier.heightIn(max = 300.dp)) {
                        items(turnHistory.reversed()) { record ->
                            Column(modifier = Modifier.padding(vertical = 4.dp)) {
                                Text("Beurt ${record.turn}: ${record.description}", fontWeight = FontWeight.Medium, fontSize = 13.sp)
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
