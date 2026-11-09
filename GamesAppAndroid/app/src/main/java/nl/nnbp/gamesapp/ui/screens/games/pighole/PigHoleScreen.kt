package nl.nnbp.gamesapp.ui.screens.games.pighole

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
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import nl.nnbp.gamesapp.data.ActiveGameManager
import nl.nnbp.gamesapp.data.PlayerScoreDetail
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.model.GameType
import nl.nnbp.gamesapp.data.model.PlayerScore
import nl.nnbp.gamesapp.ui.components.*
import nl.nnbp.gamesapp.ui.screens.games.SnelleEindscoreScreen
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SuccessGreen
import nl.nnbp.gamesapp.ui.theme.WarningRed

data class PigHoleTurnSnapshot(
    val round: Int,
    val turnIndex: Int,
    val rollsInTurn: Int,
    val pigs: List<Int>,
    val board: Map<Int, Int>,
    val pigholeCount: Int,
    val message: String?
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PigHoleScreen(
    onNavigateBack: () -> Unit,
    autoResume: Boolean = false
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }
    val haptic = LocalHapticFeedback.current

    val session = remember { activeGameManager.activeSession.value }
    val isResumeActive = autoResume && session != null && session.gameName == "Pig Hole"

    var isGameStarted by remember { mutableStateOf(isResumeActive) }
    var selectedPlayerNames by remember {
        mutableStateOf(
            if (isResumeActive && session != null) session.playerNames.toMutableList()
            else mutableListOf<String>()
        )
    }
    var penaltyRuleByBoard by remember { mutableStateOf(false) } // false = alleen dit vakje (+1), true = hele bord

    var currentRound by remember { mutableIntStateOf(1) }
    var turnIndex by remember { mutableIntStateOf(0) }
    var rollsInCurrentTurn by remember { mutableIntStateOf(0) }
    var pigsPerPlayer by remember { mutableStateOf(mutableListOf<Int>()) }
    var boardHoles by remember { mutableStateOf(mutableMapOf(1 to 0, 2 to 0, 3 to 0, 4 to 0, 5 to 0)) }
    var pigholeCount by remember { mutableIntStateOf(0) }
    var lastRollMessage by remember { mutableStateOf<String?>(null) }
    var turnHistory by remember { mutableStateOf(mutableListOf<PigHoleTurnSnapshot>()) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }
    var showFinishConfirmDialog by remember { mutableStateOf(false) }
    var showEditScoresDialog by remember { mutableStateOf(false) }
    var isQuickScoreMode by remember { mutableStateOf(false) }
    var startQuickScoreGame by remember { mutableStateOf(false) }

    fun saveDraft() {
        if (selectedPlayerNames.isEmpty() || !isGameStarted) return
        val scoreSummary = selectedPlayerNames.indices.joinToString(", ") { "${selectedPlayerNames[it]}:${pigsPerPlayer.getOrElse(it) { 0 }}" }
        val activeName = selectedPlayerNames.getOrElse(turnIndex) { "" }
        val summary = "Ronde $currentRound • $activeName • Stand: $scoreSummary"
        val state = mutableMapOf<String, String>()
        state["currentRound"] = currentRound.toString()
        state["turnIndex"] = turnIndex.toString()
        state["rollsInCurrentTurn"] = rollsInCurrentTurn.toString()
        state["pigholeCount"] = pigholeCount.toString()
        state["penaltyRuleByBoard"] = if (penaltyRuleByBoard) "1" else "0"
        state["pigs"] = pigsPerPlayer.joinToString(",")
        state["board"] = boardHoles.entries.joinToString(",") { "${it.key}:${it.value}" }
        lastRollMessage?.let { state["lastRollMessage"] = it }

        activeGameManager.saveActiveGame(
            gameName = "Pig Hole",
            playerNames = selectedPlayerNames,
            currentRound = currentRound,
            summary = summary,
            state = state
        )
    }

    LaunchedEffect(isResumeActive) {
        if (isResumeActive && session != null) {
            session.stateData["currentRound"]?.toIntOrNull()?.let { currentRound = it }
            session.stateData["turnIndex"]?.toIntOrNull()?.let { turnIndex = it }
            session.stateData["rollsInCurrentTurn"]?.toIntOrNull()?.let { rollsInCurrentTurn = it }
            session.stateData["pigholeCount"]?.toIntOrNull()?.let { pigholeCount = it }
            session.stateData["penaltyRuleByBoard"]?.let { penaltyRuleByBoard = it == "1" }
            session.stateData["pigs"]?.let { pStr ->
                val list = pStr.split(",").mapNotNull { it.toIntOrNull() }
                if (list.size == selectedPlayerNames.size) {
                    pigsPerPlayer = list.toMutableList()
                }
            }
            session.stateData["board"]?.let { bStr ->
                val map = boardHoles.toMutableMap()
                bStr.split(",").forEach { pair ->
                    val parts = pair.split(":")
                    if (parts.size == 2) {
                        val k = parts[0].toIntOrNull()
                        val v = parts[1].toIntOrNull()
                        if (k != null && v != null) map[k] = v
                    }
                }
                boardHoles = map
            }
            session.stateData["lastRollMessage"]?.let { lastRollMessage = it }
        }
    }

    if (startQuickScoreGame) {
        SnelleEindscoreScreen(
            gameName = "Pig Hole",
            playerNames = selectedPlayerNames,
            isLowestScoreWins = true,
            scoreUnit = "varkentjes",
            onNavigateBack = { startQuickScoreGame = false }
        )
        return
    }

    // Start pigs auto-calculated (60 pigs divided by player count)
    val defaultPigsPerPlayer = remember(selectedPlayerNames.size) {
        if (selectedPlayerNames.isEmpty()) 15 else 60 / selectedPlayerNames.size
    }

    val roundRuleText = remember(currentRound) {
        when (currentRound) {
            1 -> "Ronde 1 • Maximaal 1x gooien per speler"
            2 -> "Ronde 2 • Maximaal 2x gooien per speler"
            else -> "Ronde $currentRound • Gooi zovaak door als je durft!"
        }
    }

    val canVoluntarilyStop = remember(currentRound, rollsInCurrentTurn) {
        if (currentRound == 1) false
        else if (currentRound == 2) rollsInCurrentTurn >= 1
        else rollsInCurrentTurn >= 1
    }

    fun advanceToNextPlayer() {
        rollsInCurrentTurn = 0
        val nextIdx = (turnIndex + 1) % selectedPlayerNames.size
        if (nextIdx == 0) {
            currentRound += 1
        }
        turnIndex = nextIdx
        saveDraft()
    }

    fun rollDice(number: Int) {
        if (turnIndex !in selectedPlayerNames.indices) return
        val playerName = selectedPlayerNames[turnIndex]

        // Snapshot bewaren voor Undo
        turnHistory.add(
            PigHoleTurnSnapshot(
                round = currentRound,
                turnIndex = turnIndex,
                rollsInTurn = rollsInCurrentTurn,
                pigs = pigsPerPlayer.toList(),
                board = boardHoles.toMap(),
                pigholeCount = pigholeCount,
                message = lastRollMessage
            )
        )

        if (number == 6) {
            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
            val list = pigsPerPlayer.toMutableList()
            list[turnIndex] = maxOf(0, list[turnIndex] - 1)
            pigsPerPlayer = list
            pigholeCount += 1
            rollsInCurrentTurn += 1

            val remaining = list[turnIndex]
            lastRollMessage = "$playerName gooit 6! 🎯 Varkentje verdwijnt in het Pig Hole ($remaining over)!"

            if (remaining == 0) {
                winnerPlayer = playerName
                val detailed = selectedPlayerNames.indices.map { idx ->
                    PlayerScoreDetail(name = selectedPlayerNames[idx], score = list[idx])
                }
                scoreManager.saveGame(
                    gameName = "Pig Hole",
                    playerDetailedScores = detailed,
                    winnerName = playerName
                )
                isGameOver = true
                return
            }

            if ((currentRound == 1 && rollsInCurrentTurn >= 1) || (currentRound == 2 && rollsInCurrentTurn >= 2)) {
                advanceToNextPlayer()
            }
        } else if (number in 1..5) {
            val isOccupied = (boardHoles[number] ?: 0) > 0
            if (!isOccupied) {
                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                val list = pigsPerPlayer.toMutableList()
                list[turnIndex] = maxOf(0, list[turnIndex] - 1)
                pigsPerPlayer = list

                val newBoard = boardHoles.toMutableMap()
                newBoard[number] = 1
                boardHoles = newBoard
                rollsInCurrentTurn += 1

                val remaining = list[turnIndex]
                lastRollMessage = "$playerName gooit $number. Vakje was vrij: varkentje geplaatst ($remaining over)!"

                if (remaining == 0) {
                    winnerPlayer = playerName
                    val detailed = selectedPlayerNames.indices.map { idx ->
                        PlayerScoreDetail(name = selectedPlayerNames[idx], score = list[idx])
                    }
                    scoreManager.saveGame(
                        gameName = "Pig Hole",
                        playerDetailedScores = detailed,
                        winnerName = playerName
                    )
                    isGameOver = true
                    return
                }

                if ((currentRound == 1 && rollsInCurrentTurn >= 1) || (currentRound == 2 && rollsInCurrentTurn >= 2)) {
                    advanceToNextPlayer()
                }
            } else {
                // BEZET -> PECH!
                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                val newBoard = boardHoles.toMutableMap()
                val pigsToTake: Int
                if (penaltyRuleByBoard) {
                    pigsToTake = maxOf(1, newBoard.values.sum())
                    for (k in 1..5) {
                        newBoard[k] = 0
                    }
                } else {
                    pigsToTake = newBoard[number] ?: 1
                    newBoard[number] = 0
                }
                boardHoles = newBoard

                val list = pigsPerPlayer.toMutableList()
                list[turnIndex] += pigsToTake
                pigsPerPlayer = list

                val remaining = list[turnIndex]
                lastRollMessage = "⚠️ Pech! Vakje $number was bezet. $playerName pakt $pigsToTake varken(s) ($remaining totaal)! Beurt voorbij."

                advanceToNextPlayer()
            }
        }
        saveDraft()
    }

    fun undoLastRoll() {
        val last = turnHistory.removeLastOrNull() ?: return
        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
        currentRound = last.round
        turnIndex = last.turnIndex
        rollsInCurrentTurn = last.rollsInTurn
        pigsPerPlayer = last.pigs.toMutableList()
        boardHoles = last.board.toMutableMap()
        pigholeCount = last.pigholeCount
        lastRollMessage = "Worp ongedaan gemaakt."
        saveDraft()
    }

    if (isGameOver && winnerPlayer != null) {
        val playerScores = selectedPlayerNames.indices.map { i ->
            PlayerScore(
                playerName = selectedPlayerNames[i],
                score = pigsPerPlayer.getOrElse(i) { 0 },
                isWinner = selectedPlayerNames[i] == winnerPlayer
            )
        }
        WinnaarScreen(
            gameName = "Pig Hole",
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
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        GameLogoImage(gameType = GameType.PIG_HOLE, size = 30.dp, cornerRadius = 8.dp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Pig Hole", fontWeight = FontWeight.Bold, fontSize = 18.sp)
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Terug")
                    }
                },
                actions = {
                    if (isGameStarted) {
                        IconButton(onClick = { showEditScoresDialog = true }) {
                            Icon(Icons.Default.Edit, contentDescription = "Varkens wijzigen", tint = AccentOrange)
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
                        GameSetupHeader(
                            gameType = GameType.PIG_HOLE,
                            subtitle = "Het varkensgat • Raak als eerste al je varkentjes kwijt! 🐷",
                            themeColor = AccentOrange
                        )
                    }

                    item {
                        GameModeSegmentedPicker(
                            options = listOf(
                                GameModeItem(
                                    id = "live",
                                    title = "Ronde voor ronde",
                                    icon = Icons.Default.Casino,
                                    description = "🎮 Begeleid elke ronde met dobbelsteen-invoer (1 t/m 6) en bordstatus."
                                ),
                                GameModeItem(
                                    id = "snel",
                                    title = "Snelle eindscore",
                                    icon = Icons.Default.Bolt,
                                    description = "⚡️ Vul direct het aantal overgebleven varkentjes per speler in."
                                )
                            ),
                            selectedId = if (isQuickScoreMode) "snel" else "live",
                            onSelect = { isQuickScoreMode = (it == "snel") },
                            themeColor = AccentOrange
                        )
                    }

                    if (!isQuickScoreMode) {
                        item {
                            SectionTitle(title = "Regel bij bezet vakje")
                            Card(
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(12.dp),
                                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                            ) {
                                Column(modifier = Modifier.padding(12.dp)) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        Button(
                                            onClick = { penaltyRuleByBoard = false },
                                            colors = ButtonDefaults.buttonColors(
                                                containerColor = if (!penaltyRuleByBoard) AccentOrange else MaterialTheme.colorScheme.surface
                                            ),
                                            modifier = Modifier.weight(1f),
                                            shape = RoundedCornerShape(8.dp)
                                        ) {
                                            Text(
                                                "Dit vakje (+1)",
                                                fontWeight = FontWeight.Bold,
                                                color = if (!penaltyRuleByBoard) Color.White else MaterialTheme.colorScheme.onSurface
                                            )
                                        }

                                        Button(
                                            onClick = { penaltyRuleByBoard = true },
                                            colors = ButtonDefaults.buttonColors(
                                                containerColor = if (penaltyRuleByBoard) AccentOrange else MaterialTheme.colorScheme.surface
                                            ),
                                            modifier = Modifier.weight(1f),
                                            shape = RoundedCornerShape(8.dp)
                                        ) {
                                            Text(
                                                "Hele bord",
                                                fontWeight = FontWeight.Bold,
                                                color = if (penaltyRuleByBoard) Color.White else MaterialTheme.colorScheme.onSurface
                                            )
                                        }
                                    }
                                    Spacer(modifier = Modifier.height(6.dp))
                                    Text(
                                        text = if (!penaltyRuleByBoard) "Standaard: pak alleen het varkentje van het gegooide vakje op (+1)." else "Variant: pak alle varkentjes van het hele bord op!",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color.Gray
                                    )
                                }
                            }
                        }
                    }

                    item {
                        PlayerCountPicker(
                            minPlayers = 2,
                            maxPlayers = 6,
                            selectedCount = selectedPlayerNames.size.coerceIn(2, 6),
                            onSelect = { /* matches list */ },
                            themeColor = AccentOrange
                        )
                    }

                    item {
                        SavedPlayersQuickChips(
                            selectedPlayers = selectedPlayerNames,
                            onTogglePlayer = { name ->
                                val list = selectedPlayerNames.toMutableList()
                                if (list.contains(name)) list.remove(name) else list.add(name)
                                selectedPlayerNames = list
                            },
                            onApplyTafelschikking = { seated ->
                                selectedPlayerNames = seated.take(7).toMutableList()
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
                                        Text("${idx + 1}. $name ($defaultPigsPerPlayer varkentjes)", fontWeight = FontWeight.SemiBold)
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
                            pigsPerPlayer = MutableList(selectedPlayerNames.size) { defaultPigsPerPlayer }
                            isGameStarted = true
                            saveDraft()
                        }
                    },
                    enabled = selectedPlayerNames.size >= 2,
                    colors = ButtonDefaults.buttonColors(containerColor = AccentOrange),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text(
                        if (isQuickScoreMode) "⚡️ Snelle Eindscore Starten" else "Start Spel ($defaultPigsPerPlayer varkentjes elk)",
                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
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
                        val pairs = selectedPlayerNames.indices.map { i ->
                            Pair(selectedPlayerNames[i], pigsPerPlayer.getOrElse(i) { 0 })
                        }
                        LiveGameLeadCard(
                            playerScores = pairs,
                            isLowestScoreWins = true,
                            themeColor = AccentOrange
                        )
                    }

                    item {
                        // Regel banner
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = AccentOrange.copy(alpha = 0.12f))
                        ) {
                            Text(
                                text = roundRuleText,
                                style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold, color = AccentOrange),
                                modifier = Modifier.padding(12.dp)
                            )
                        }
                    }

                    // SPEELBORD STATUS KAART (Vakjes 1 t/m 5 + Gat 6)
                    item {
                        val totalOnBoard = boardHoles.values.sum()
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("Speelbord Status", fontWeight = FontWeight.Bold, fontSize = 14.sp, color = AccentOrange)
                                    Text("$totalOnBoard 🐷 op tafel • $pigholeCount 🕳️ in gat", fontSize = 11.sp, color = Color.Gray)
                                }
                                Spacer(modifier = Modifier.height(8.dp))

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    (1..3).forEach { num ->
                                        val isOccupied = (boardHoles[num] ?: 0) > 0
                                        Box(
                                            modifier = Modifier
                                                .weight(1f)
                                                .clip(RoundedCornerShape(10.dp))
                                                .background(if (isOccupied) AccentOrange.copy(alpha = 0.18f) else MaterialTheme.colorScheme.surface)
                                                .border(1.dp, if (isOccupied) AccentOrange else Color.Gray.copy(alpha = 0.25f), RoundedCornerShape(10.dp))
                                                .clickable {
                                                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                                    val nb = boardHoles.toMutableMap()
                                                    nb[num] = if (isOccupied) 0 else 1
                                                    boardHoles = nb
                                                }
                                                .padding(vertical = 8.dp),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                                Text(getDiceGlyph(num) + " Vak $num", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                                                Text(if (isOccupied) "🐷 Bezet" else "⚪️ Vrij", fontSize = 10.sp, color = if (isOccupied) AccentOrange else Color.Gray)
                                            }
                                        }
                                    }
                                }

                                Spacer(modifier = Modifier.height(6.dp))

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    (4..5).forEach { num ->
                                        val isOccupied = (boardHoles[num] ?: 0) > 0
                                        Box(
                                            modifier = Modifier
                                                .weight(1f)
                                                .clip(RoundedCornerShape(10.dp))
                                                .background(if (isOccupied) AccentOrange.copy(alpha = 0.18f) else MaterialTheme.colorScheme.surface)
                                                .border(1.dp, if (isOccupied) AccentOrange else Color.Gray.copy(alpha = 0.25f), RoundedCornerShape(10.dp))
                                                .clickable {
                                                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                                    val nb = boardHoles.toMutableMap()
                                                    nb[num] = if (isOccupied) 0 else 1
                                                    boardHoles = nb
                                                }
                                                .padding(vertical = 8.dp),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                                Text(getDiceGlyph(num) + " Vak $num", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                                                Text(if (isOccupied) "🐷 Bezet" else "⚪️ Vrij", fontSize = 10.sp, color = if (isOccupied) AccentOrange else Color.Gray)
                                            }
                                        }
                                    }

                                    // Hole 6: The Pig Hole
                                    Box(
                                        modifier = Modifier
                                            .weight(1f)
                                            .clip(RoundedCornerShape(10.dp))
                                            .background(Color(0xFF9C27B0).copy(alpha = 0.15f))
                                            .border(1.dp, Color(0xFF9C27B0), RoundedCornerShape(10.dp))
                                            .padding(vertical = 8.dp),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                            Text("⚅ Gat 6", fontWeight = FontWeight.Bold, fontSize = 12.sp, color = Color(0xFF9C27B0))
                                            Text("🕳️ $pigholeCount kwijt", fontSize = 10.sp, color = Color(0xFF9C27B0), fontWeight = FontWeight.Bold)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // DOBBELSTEEN INVOER KAART (Cijfers 1 t/m 6)
                    item {
                        val turnPlayer = selectedPlayerNames.getOrElse(turnIndex) { "" }
                        val remainingPigs = pigsPerPlayer.getOrElse(turnIndex) { 0 }
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                            border = androidx.compose.foundation.BorderStroke(1.5.dp, AccentOrange.copy(alpha = 0.4f))
                        ) {
                            Column(modifier = Modifier.padding(14.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column {
                                        Text("Aan de beurt: $turnPlayer ($remainingPigs 🐷)", fontWeight = FontWeight.Black, fontSize = 15.sp)
                                        val limitDesc = when (currentRound) {
                                            1 -> "Worp ${rollsInCurrentTurn + 1} (max 1 worp)"
                                            2 -> "Worp ${rollsInCurrentTurn + 1} (max 2 worpen)"
                                            else -> "Worp ${rollsInCurrentTurn + 1} (onbeperkt)"
                                        }
                                        Text(limitDesc, fontSize = 11.sp, color = AccentOrange, fontWeight = FontWeight.SemiBold)
                                    }

                                    if (canVoluntarilyStop) {
                                        Button(
                                            onClick = {
                                                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                                lastRollMessage = "$turnPlayer stopt de beurt veilig."
                                                advanceToNextPlayer()
                                            },
                                            colors = ButtonDefaults.buttonColors(containerColor = SuccessGreen),
                                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp)
                                        ) {
                                            Text("Stoppen 🛑", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                        }
                                    } else {
                                        OutlinedButton(
                                            onClick = {
                                                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                                advanceToNextPlayer()
                                            },
                                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                                        ) {
                                            Text("Doorgeven ➡️", fontSize = 11.sp)
                                        }
                                    }
                                }

                                Spacer(modifier = Modifier.height(10.dp))
                                Text("Wat heeft $turnPlayer gegooid?", fontSize = 12.sp, color = Color.Gray, fontWeight = FontWeight.SemiBold)
                                Spacer(modifier = Modifier.height(6.dp))

                                // Dobbelstenen 1 t/m 3
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    (1..3).forEach { num ->
                                        DiceRollButton(
                                            number = num,
                                            isOccupied = (boardHoles[num] ?: 0) > 0,
                                            penaltyByBoard = penaltyRuleByBoard,
                                            onClick = { rollDice(num) },
                                            modifier = Modifier.weight(1f)
                                        )
                                    }
                                }

                                Spacer(modifier = Modifier.height(6.dp))

                                // Dobbelstenen 4 t/m 6
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    (4..6).forEach { num ->
                                        DiceRollButton(
                                            number = num,
                                            isOccupied = if (num == 6) false else ((boardHoles[num] ?: 0) > 0),
                                            penaltyByBoard = penaltyRuleByBoard,
                                            onClick = { rollDice(num) },
                                            modifier = Modifier.weight(1f)
                                        )
                                    }
                                }

                                // Melding van laatste worp + Undo
                                if (lastRollMessage != null) {
                                    Spacer(modifier = Modifier.height(10.dp))
                                    Card(
                                        modifier = Modifier.fillMaxWidth(),
                                        shape = RoundedCornerShape(8.dp),
                                        colors = CardDefaults.cardColors(
                                            containerColor = if (lastRollMessage!!.contains("Pech")) WarningRed.copy(alpha = 0.12f) else AccentOrange.copy(alpha = 0.1f)
                                        )
                                    ) {
                                        Row(
                                            modifier = Modifier.fillMaxWidth().padding(8.dp),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Text(
                                                text = lastRollMessage!!,
                                                fontSize = 11.sp,
                                                fontWeight = FontWeight.Medium,
                                                modifier = Modifier.weight(1f)
                                            )
                                            if (turnHistory.isNotEmpty()) {
                                                TextButton(
                                                    onClick = { undoLastRoll() },
                                                    contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp)
                                                ) {
                                                    Text("↩️ Herstel", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = AccentOrange)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // SPELERS OVERZICHT
                    itemsIndexed(selectedPlayerNames) { index, playerName ->
                        val isTurn = index == turnIndex
                        val count = pigsPerPlayer.getOrElse(index) { 0 }

                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = if (isTurn) PrimaryBlue.copy(alpha = 0.08f) else MaterialTheme.colorScheme.surfaceVariant
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
                                            if (isTurn) {
                                                Spacer(modifier = Modifier.width(6.dp))
                                                Text(
                                                    "Aan de beurt",
                                                    fontSize = 10.sp,
                                                    fontWeight = FontWeight.Bold,
                                                    color = Color.White,
                                                    modifier = Modifier
                                                        .clip(RoundedCornerShape(4.dp))
                                                        .background(AccentOrange)
                                                        .padding(horizontal = 6.dp, vertical = 2.dp)
                                                )
                                            }
                                        }
                                        Text(
                                            text = "$count varkentjes over",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = if (count <= 3) SuccessGreen else Color.Gray
                                        )
                                    }

                                    Text(
                                        text = "$count 🐷",
                                        style = MaterialTheme.typography.headlineSmall.copy(
                                            fontWeight = FontWeight.Bold,
                                            color = if (count == 0) SuccessGreen else PrimaryBlue
                                        )
                                    )
                                }

                                Spacer(modifier = Modifier.height(10.dp))

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    // Handmatige -1
                                    Button(
                                        onClick = {
                                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                            val list = pigsPerPlayer.toMutableList()
                                            list[index] = maxOf(0, list[index] - 1)
                                            pigsPerPlayer = list
                                            if (list[index] == 0) {
                                                winnerPlayer = playerName
                                                val detailed = selectedPlayerNames.indices.map { idx ->
                                                    PlayerScoreDetail(name = selectedPlayerNames[idx], score = list[idx])
                                                }
                                                scoreManager.saveGame(
                                                    gameName = "Pig Hole",
                                                    playerDetailedScores = detailed,
                                                    winnerName = playerName
                                                )
                                                isGameOver = true
                                            }
                                        },
                                        modifier = Modifier.weight(1f),
                                        colors = ButtonDefaults.buttonColors(containerColor = SuccessGreen),
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text("-1 Kwijt", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                                    }

                                    // Handmatige +1
                                    FilledTonalButton(
                                        onClick = {
                                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                            val list = pigsPerPlayer.toMutableList()
                                            list[index] += 1
                                            pigsPerPlayer = list
                                        },
                                        modifier = Modifier.weight(1f),
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text("+1 Bezet", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                                    }
                                }
                            }
                        }
                    }
                }

                Button(
                    onClick = { showFinishConfirmDialog = true },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 12.dp)
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Icon(Icons.Default.CheckCircle, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Spel Afronden", style = MaterialTheme.typography.titleMedium)
                }
            }
        }
    }

    if (showFinishConfirmDialog) {
        AlertDialog(
            onDismissRequest = { showFinishConfirmDialog = false },
            title = { Text("Spel afronden?") },
            text = { Text("De speler met de minste overgebleven varkentjes wint het spel!") },
            confirmButton = {
                Button(
                    onClick = {
                        val minCount = pigsPerPlayer.minOrNull() ?: 0
                        val winIdx = pigsPerPlayer.indexOf(minCount)
                        val winner = selectedPlayerNames.getOrElse(winIdx) { "" }
                        winnerPlayer = winner

                        val detailed = selectedPlayerNames.indices.map { idx ->
                            PlayerScoreDetail(name = selectedPlayerNames[idx], score = pigsPerPlayer[idx])
                        }
                        scoreManager.saveGame(
                            gameName = "Pig Hole",
                            playerDetailedScores = detailed,
                            winnerName = winner
                        )
                        showFinishConfirmDialog = false
                        isGameOver = true
                    }
                ) {
                    Text("Uitslag Bekijken")
                }
            },
            dismissButton = {
                TextButton(onClick = { showFinishConfirmDialog = false }) {
                    Text("Annuleren")
                }
            }
        )
    }

    if (showEditScoresDialog) {
        PuntenWijzigenDialog(
            playerNames = selectedPlayerNames,
            currentScores = pigsPerPlayer,
            isLowestScoreWins = true,
            title = "Varkens Wijzigen",
            subtitle = "Pas het aantal resterende varkens per speler direct aan.",
            onDismiss = { showEditScoresDialog = false },
            onSave = { newScores ->
                pigsPerPlayer = newScores.toMutableList()
            }
        )
    }
}

@Composable
fun DiceRollButton(
    number: Int,
    isOccupied: Boolean,
    penaltyByBoard: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isSix = number == 6
    val borderCol = if (isSix) Color(0xFF9C27B0) else if (isOccupied) WarningRed else AccentOrange
    val bgCol = if (isSix) Color(0xFF9C27B0).copy(alpha = 0.12f) else if (isOccupied) WarningRed.copy(alpha = 0.15f) else MaterialTheme.colorScheme.surface

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(10.dp))
            .background(bgCol)
            .border(1.dp, borderCol, RoundedCornerShape(10.dp))
            .clickable(onClick = onClick)
            .padding(vertical = 10.dp, horizontal = 4.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = "${getDiceGlyph(number)} $number",
                fontWeight = FontWeight.Black,
                fontSize = 15.sp,
                color = if (isSix) Color(0xFF9C27B0) else if (isOccupied) WarningRed else AccentOrange
            )
            Text(
                text = if (isSix) "Gat (-1)" else if (isOccupied) (if (penaltyByBoard) "Pak bord!" else "Pakken (+1)") else "Leg neer (-1)",
                fontSize = 9.sp,
                fontWeight = FontWeight.Bold,
                color = if (isSix) Color(0xFF9C27B0) else if (isOccupied) WarningRed else Color.Gray
            )
        }
    }
}

fun getDiceGlyph(number: Int): String = when (number) {
    1 -> "⚀"
    2 -> "⚁"
    3 -> "⚂"
    4 -> "⚃"
    5 -> "⚄"
    else -> "⚅"
}
