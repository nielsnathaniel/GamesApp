package nl.nnbp.gamesapp.ui.screens.games.risk

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import nl.nnbp.gamesapp.data.ActiveGameManager
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.model.GameType
import nl.nnbp.gamesapp.data.model.PlayerScore
import nl.nnbp.gamesapp.ui.components.*
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SuccessGreen
import nl.nnbp.gamesapp.ui.theme.WarningRed
import kotlin.math.max
import kotlin.math.min
import kotlin.random.Random

enum class RiskArmyColor(val displayName: String, val color: Color, val textColor: Color = Color.White) {
    RED("Rood", Color(0xFFE63946)),
    BLUE("Blauw", Color(0xFF1D3557)),
    YELLOW("Geel", Color(0xFFF4A261), Color.Black),
    GREEN("Groen", Color(0xFF2A9D8F)),
    BLACK("Zwart", Color(0xFF264653)),
    PURPLE("Paars", Color(0xFF7209B7))
}

data class RiskMission(
    val id: Int,
    val title: String,
    val description: String,
    val targetColor: RiskArmyColor? = null
)

data class RiskPlayer(
    val name: String,
    var armyColor: RiskArmyColor,
    var mission: RiskMission? = null
)

data class BattleComparison(
    val attackerDie: Int,
    val defenderDie: Int,
    val attackerWon: Boolean
)

data class RiskBattleResult(
    val attackerRolls: List<Int>,
    val defenderRolls: List<Int>,
    val attackerLosses: Int,
    val defenderLosses: Int,
    val comparisons: List<BattleComparison>
)

data class RiskBlitzResult(
    val attackerInitial: Int,
    val defenderInitial: Int,
    val attackerRemaining: Int,
    val defenderRemaining: Int,
    val attackerWon: Boolean,
    val totalRounds: Int
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RiskScreen(
    onNavigateBack: () -> Unit,
    autoResume: Boolean = false
) {
    val context = LocalContext.current
    val scoreManager = remember { ScoreManager.getInstance(context) }
    val activeGameManager = remember { ActiveGameManager.getInstance(context) }
    val savedPlayerNames by scoreManager.savedPlayerNames.collectAsState()

    val session = remember { activeGameManager.activeSession.value }
    val isResumeActive = autoResume && session != null && session.gameName == "Risk"

    var isGameStarted by remember { mutableStateOf(isResumeActive) }

    // Setup state
    var selectedPlayers by remember {
        mutableStateOf(
            if (isResumeActive && session != null) session.playerNames.toMutableList()
            else if (savedPlayerNames.size >= 2) savedPlayerNames.take(3).toMutableList()
            else mutableListOf("Speler 1", "Speler 2", "Speler 3")
        )
    }
    var playerColors by remember {
        mutableStateOf(
            listOf(
                RiskArmyColor.RED,
                RiskArmyColor.BLUE,
                RiskArmyColor.YELLOW,
                RiskArmyColor.GREEN,
                RiskArmyColor.BLACK,
                RiskArmyColor.PURPLE
            )
        )
    }
    var isSecretMissionsMode by remember { mutableStateOf(true) }
    var progressiveCards by remember { mutableStateOf(true) }
    var newPlayerNameInput by remember { mutableStateOf("") }

    // Game state
    var gamePlayers by remember { mutableStateOf(listOf<RiskPlayer>()) }
    var currentTab by remember { mutableStateOf(0) } // 0: Gevecht, 1: Versterkingen, 2: Missies

    // Gevecht State
    var attackerIndex by remember { mutableIntStateOf(0) }
    var defenderIndex by remember { mutableIntStateOf(1) }
    var attackerDiceCount by remember { mutableIntStateOf(3) }
    var defenderDiceCount by remember { mutableIntStateOf(2) }
    var lastBattleResult by remember { mutableStateOf<RiskBattleResult?>(null) }
    var isBlitzMode by remember { mutableStateOf(false) }
    var blitzAttackerArmies by remember { mutableIntStateOf(15) }
    var blitzDefenderArmies by remember { mutableIntStateOf(8) }
    var lastBlitzResult by remember { mutableStateOf<RiskBlitzResult?>(null) }

    // Versterkingen State
    var ownedTerritories by remember { mutableIntStateOf(12) }
    var northAmerica by remember { mutableStateOf(false) } // +5
    var southAmerica by remember { mutableStateOf(false) } // +2
    var europe by remember { mutableStateOf(false) }       // +5
    var africa by remember { mutableStateOf(false) }       // +3
    var asia by remember { mutableStateOf(false) }         // +7
    var australia by remember { mutableStateOf(false) }    // +2
    var cardSetIndex by remember { mutableIntStateOf(0) }

    // Missies State
    var revealedMissionPlayerIndex by remember { mutableStateOf<Int?>(null) }

    // Finish State
    var showFinishDialog by remember { mutableStateOf(false) }
    var winningPlayerIndex by remember { mutableIntStateOf(0) }
    var showWinnerScreen by remember { mutableStateOf(false) }

    fun saveDraft() {
        if (selectedPlayers.isEmpty() || !isGameStarted) return
        val modeStr = if (isSecretMissionsMode) "Geheime Missies" else "Wereldheerschappij"
        val summary = "${selectedPlayers.size} spelers • $modeStr"
        val state = mutableMapOf<String, String>()
        state["isSecretMissionsMode"] = if (isSecretMissionsMode) "1" else "0"
        state["progressiveCards"] = if (progressiveCards) "1" else "0"

        activeGameManager.saveActiveGame(
            gameName = "Risk",
            playerNames = selectedPlayers,
            currentRound = 1,
            summary = summary,
            state = state
        )
    }

    LaunchedEffect(isResumeActive) {
        if (isResumeActive && session != null) {
            session.stateData["isSecretMissionsMode"]?.let { isSecretMissionsMode = it == "1" }
            session.stateData["progressiveCards"]?.let { progressiveCards = it == "1" }
            val missions = if (isSecretMissionsMode) generateMissions().shuffled() else emptyList()
            gamePlayers = selectedPlayers.mapIndexed { idx, name ->
                RiskPlayer(
                    name = name,
                    armyColor = playerColors[idx % playerColors.size],
                    mission = missions.getOrNull(idx)
                )
            }
        }
    }

    if (showWinnerScreen) {
        val winnerName = gamePlayers.getOrNull(winningPlayerIndex)?.name ?: "Speler"
        val scores = gamePlayers.map { p ->
            PlayerScore(
                playerName = p.name,
                score = if (p.name == winnerName) 100 else 0,
                isWinner = (p.name == winnerName)
            )
        }
        WinnaarScreen(
            gameName = "Risk",
            winnerName = winnerName,
            scores = scores,
            onFinish = {
                activeGameManager.clearActiveGame()
                showWinnerScreen = false
                isGameStarted = false
                onNavigateBack()
            }
        )
        return
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (isGameStarted) "Risk Assistent" else "Risk Setup") },
                navigationIcon = {
                    IconButton(onClick = {
                        if (isGameStarted) isGameStarted = false
                        else onNavigateBack()
                    }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Terug")
                    }
                },
                actions = {
                    if (isGameStarted) {
                        Button(
                            onClick = { showFinishDialog = true },
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFFD166)),
                            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Icon(Icons.Default.EmojiEvents, contentDescription = null, tint = Color.Black, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Winnaar", color = Color.Black, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        if (!isGameStarted) {
            // MARK: - SETUP SCHERM
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Header Banner
                item {
                    AppCard {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(54.dp)
                                    .clip(CircleShape)
                                    .background(Brush.linearGradient(listOf(Color(0xFFE63946), Color(0xFFF4A261)))),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Default.Security, contentDescription = null, tint = Color.White, modifier = Modifier.size(28.dp))
                            }
                            Spacer(modifier = Modifier.width(16.dp))
                            Column {
                                Text("Risk Assistent", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
                                Text(
                                    "Stel legers en missies in voor gevechtsdobbelstenen, blitz en versterkingen.",
                                    fontSize = 12.sp,
                                    color = Color.Gray
                                )
                            }
                        }
                    }
                }

                // Spelers en Legerkleuren
                item {
                    SectionTitle(title = "Spelers & Legerkleuren (${selectedPlayers.size}/6)")
                    AppCard {
                        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            selectedPlayers.forEachIndexed { idx, name ->
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
                                        .padding(horizontal = 10.dp, vertical = 8.dp)
                                ) {
                                    Text("${idx + 1}.", fontWeight = FontWeight.Bold, fontSize = 12.sp, color = Color.Gray)
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(name, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))

                                    // Kleurenkiezer chip
                                    var showColorMenu by remember { mutableStateOf(false) }
                                    val currentColor = playerColors[idx % playerColors.size]
                                    Box {
                                        Surface(
                                            onClick = { showColorMenu = true },
                                            shape = RoundedCornerShape(12.dp),
                                            color = currentColor.color.copy(alpha = 0.2f),
                                            border = androidx.compose.foundation.BorderStroke(1.dp, currentColor.color)
                                        ) {
                                            Row(
                                                verticalAlignment = Alignment.CenterVertically,
                                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                            ) {
                                                Box(
                                                    modifier = Modifier
                                                        .size(10.dp)
                                                        .clip(CircleShape)
                                                        .background(currentColor.color)
                                                )
                                                Spacer(modifier = Modifier.width(4.dp))
                                                Text(currentColor.displayName, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                            }
                                        }

                                        DropdownMenu(expanded = showColorMenu, onDismissRequest = { showColorMenu = false }) {
                                            RiskArmyColor.entries.forEach { col ->
                                                DropdownMenuItem(
                                                    text = {
                                                        Row(verticalAlignment = Alignment.CenterVertically) {
                                                            Box(modifier = Modifier.size(12.dp).clip(CircleShape).background(col.color))
                                                            Spacer(modifier = Modifier.width(8.dp))
                                                            Text(col.displayName)
                                                        }
                                                    },
                                                    onClick = {
                                                        val updated = playerColors.toMutableList()
                                                        updated[idx] = col
                                                        playerColors = updated
                                                        showColorMenu = false
                                                    }
                                                )
                                            }
                                        }
                                    }

                                    if (selectedPlayers.size > 2) {
                                        Spacer(modifier = Modifier.width(8.dp))
                                        IconButton(
                                            onClick = {
                                                val updated = selectedPlayers.toMutableList()
                                                updated.removeAt(idx)
                                                selectedPlayers = updated
                                            },
                                            modifier = Modifier.size(24.dp)
                                        ) {
                                            Icon(Icons.Default.Close, contentDescription = "Verwijder", tint = Color.Gray)
                                        }
                                    }
                                }
                            }

                            // Nieuwe speler toevoegen
                            if (selectedPlayers.size < 6) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    OutlinedTextField(
                                        value = newPlayerNameInput,
                                        onValueChange = { newPlayerNameInput = it },
                                        placeholder = { Text("Nieuwe speler toevoegen...", fontSize = 12.sp) },
                                        modifier = Modifier.weight(1f),
                                        singleLine = true
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    IconButton(
                                        onClick = {
                                            val trimmed = newPlayerNameInput.trim()
                                            if (trimmed.isNotBlank() && selectedPlayers.none { it.equals(trimmed, ignoreCase = true) }) {
                                                selectedPlayers = (selectedPlayers + trimmed).toMutableList()
                                                newPlayerNameInput = ""
                                            }
                                        },
                                        enabled = newPlayerNameInput.isNotBlank()
                                    ) {
                                        Icon(Icons.Default.AddCircle, contentDescription = "Toevoegen", tint = PrimaryBlue)
                                    }
                                }
                            }
                        }
                    }
                }

                // Spelregels & Modus
                item {
                    SectionTitle(title = "Spelregels & Kaarten")
                    AppCard {
                        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text("Geheime Missies", fontWeight = FontWeight.Bold)
                                    Text(
                                        if (isSecretMissionsMode) "Iedere speler krijgt een geheime opdracht."
                                        else "Wereldheerschappij: verover alle 42 gebieden.",
                                        fontSize = 12.sp,
                                        color = Color.Gray
                                    )
                                }
                                Switch(
                                    checked = isSecretMissionsMode,
                                    onCheckedChange = { isSecretMissionsMode = it }
                                )
                            }

                            HorizontalDivider()

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text("Oplopende Kaartensets", fontWeight = FontWeight.Bold)
                                    Text(
                                        if (progressiveCards) "4, 6, 8, 10, 12, 15, 20... legers"
                                        else "Vaste legers (4, 6, 8, 10)",
                                        fontSize = 12.sp,
                                        color = Color.Gray
                                    )
                                }
                                Switch(
                                    checked = progressiveCards,
                                    onCheckedChange = { progressiveCards = it }
                                )
                            }
                        }
                    }
                }

                // Start Knop
                item {
                    Button(
                        onClick = {
                            val missions = if (isSecretMissionsMode) generateMissions().shuffled() else emptyList()
                            gamePlayers = selectedPlayers.mapIndexed { idx, name ->
                                RiskPlayer(
                                    name = name,
                                    armyColor = playerColors[idx % playerColors.size],
                                    mission = missions.getOrNull(idx)
                                )
                            }
                            isGameStarted = true
                            saveDraft()
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp),
                        shape = RoundedCornerShape(14.dp),
                        enabled = selectedPlayers.size >= 2,
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE63946))
                    ) {
                        Icon(Icons.Default.PlayArrow, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Start Risk Assistent", fontWeight = FontWeight.Bold, fontSize = 16.sp)
                    }
                }
            }
        } else {
            // MARK: - ACTIEVE ASSISTENT
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
            ) {
                // Tab Navigation
                TabRow(selectedTabIndex = currentTab) {
                    Tab(
                        selected = currentTab == 0,
                        onClick = { currentTab = 0 },
                        text = { Text("⚔️ Gevecht") }
                    )
                    Tab(
                        selected = currentTab == 1,
                        onClick = { currentTab = 1 },
                        text = { Text("🛡️ Legers") }
                    )
                    Tab(
                        selected = currentTab == 2,
                        onClick = { currentTab = 2 },
                        text = { Text("📜 Missies") }
                    )
                }

                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    when (currentTab) {
                        0 -> {
                            // MARK: TAB 0 - GEVECHT
                            item {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    OutlinedButton(
                                        onClick = { isBlitzMode = false },
                                        modifier = Modifier.weight(1f),
                                        colors = if (!isBlitzMode) ButtonDefaults.outlinedButtonColors(containerColor = Color(0xFFE63946).copy(alpha = 0.15f)) else ButtonDefaults.outlinedButtonColors()
                                    ) {
                                        Text("🎲 Dobbelen")
                                    }
                                    OutlinedButton(
                                        onClick = { isBlitzMode = true },
                                        modifier = Modifier.weight(1f),
                                        colors = if (isBlitzMode) ButtonDefaults.outlinedButtonColors(containerColor = Color(0xFFE63946).copy(alpha = 0.15f)) else ButtonDefaults.outlinedButtonColors()
                                    ) {
                                        Text("⚡ Blitz")
                                    }
                                }
                            }

                            if (!isBlitzMode) {
                                // Handmatig Dobbelen
                                item {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                                    ) {
                                        // Aanvaller
                                        AppCard(modifier = Modifier.weight(1f)) {
                                            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                                Text("AANVALLER", color = Color(0xFFE63946), fontWeight = FontWeight.Bold, fontSize = 11.sp)
                                                Text(gamePlayers[attackerIndex].name, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                                                Row(
                                                    modifier = Modifier.fillMaxWidth(),
                                                    horizontalArrangement = Arrangement.SpaceBetween,
                                                    verticalAlignment = Alignment.CenterVertically
                                                ) {
                                                    Text("Stenen:", fontSize = 11.sp, color = Color.Gray)
                                                    Row {
                                                        (1..3).forEach { dice ->
                                                            FilterChip(
                                                                selected = attackerDiceCount == dice,
                                                                onClick = { attackerDiceCount = dice },
                                                                label = { Text("$dice", fontSize = 11.sp) },
                                                                modifier = Modifier.padding(horizontal = 2.dp)
                                                            )
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // Verdediger
                                        AppCard(modifier = Modifier.weight(1f)) {
                                            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                                Text("VERDEDIGER", color = Color(0xFF1D3557), fontWeight = FontWeight.Bold, fontSize = 11.sp)
                                                Text(gamePlayers[defenderIndex].name, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                                                Row(
                                                    modifier = Modifier.fillMaxWidth(),
                                                    horizontalArrangement = Arrangement.SpaceBetween,
                                                    verticalAlignment = Alignment.CenterVertically
                                                ) {
                                                    Text("Stenen:", fontSize = 11.sp, color = Color.Gray)
                                                    Row {
                                                        (1..2).forEach { dice ->
                                                            FilterChip(
                                                                selected = defenderDiceCount == dice,
                                                                onClick = { defenderDiceCount = dice },
                                                                label = { Text("$dice", fontSize = 11.sp) },
                                                                modifier = Modifier.padding(horizontal = 2.dp)
                                                            )
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                item {
                                    Button(
                                        onClick = {
                                            val attRolls = (1..attackerDiceCount).map { Random.nextInt(1, 7) }.sortedDescending()
                                            val defRolls = (1..defenderDiceCount).map { Random.nextInt(1, 7) }.sortedDescending()
                                            var attLoss = 0
                                            var defLoss = 0
                                            val comps = mutableListOf<BattleComparison>()
                                            val count = min(attRolls.size, defRolls.size)
                                            for (i in 0 until count) {
                                                if (attRolls[i] > defRolls[i]) {
                                                    defLoss++
                                                    comps.add(BattleComparison(attRolls[i], defRolls[i], true))
                                                } else {
                                                    attLoss++
                                                    comps.add(BattleComparison(attRolls[i], defRolls[i], false))
                                                }
                                            }
                                            lastBattleResult = RiskBattleResult(attRolls, defRolls, attLoss, defLoss, comps)
                                        },
                                        modifier = Modifier.fillMaxWidth().height(48.dp),
                                        shape = RoundedCornerShape(12.dp),
                                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE63946))
                                    ) {
                                        Icon(Icons.Default.Casino, contentDescription = null)
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Text("Gooi Dobbelstenen!", fontWeight = FontWeight.Bold)
                                    }
                                }

                                lastBattleResult?.let { res ->
                                    item {
                                        AppCard {
                                            Column(
                                                modifier = Modifier.fillMaxWidth(),
                                                horizontalAlignment = Alignment.CenterHorizontally,
                                                verticalArrangement = Arrangement.spacedBy(10.dp)
                                            ) {
                                                Text("Uitslag Gevecht", fontWeight = FontWeight.Bold)
                                                Row(
                                                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                                                    verticalAlignment = Alignment.CenterVertically
                                                ) {
                                                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                                        res.attackerRolls.forEach { die ->
                                                            AndroidDie(value = die, isAttacker = true)
                                                        }
                                                    }
                                                    Text("VS", fontWeight = FontWeight.Black, color = Color.Gray)
                                                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                                        res.defenderRolls.forEach { die ->
                                                            AndroidDie(value = die, isAttacker = false)
                                                        }
                                                    }
                                                }

                                                HorizontalDivider()

                                                res.comparisons.forEachIndexed { i, comp ->
                                                    Row(
                                                        modifier = Modifier.fillMaxWidth(),
                                                        horizontalArrangement = Arrangement.SpaceBetween
                                                    ) {
                                                        Text("Vergelijking #${i + 1}: ${comp.attackerDie} vs ${comp.defenderDie}", fontSize = 12.sp)
                                                        Text(
                                                            if (comp.attackerWon) "🛡️ Verdediger -1" else "💀 Aanvaller -1",
                                                            fontSize = 12.sp,
                                                            fontWeight = FontWeight.Bold,
                                                            color = if (comp.attackerWon) SuccessGreen else WarningRed
                                                        )
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                // Blitz Gevecht
                                item {
                                    AppCard {
                                        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                                            Text("⚡ Blitz Simulator (Vecht tot het einde)", fontWeight = FontWeight.Bold)
                                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                                Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                                                    Text("Aanvallers", color = Color(0xFFE63946), fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                                    Text("$blitzAttackerArmies", fontSize = 28.sp, fontWeight = FontWeight.Black, color = Color(0xFFE63946))
                                                    Row {
                                                        IconButton(onClick = { if (blitzAttackerArmies > 2) blitzAttackerArmies-- }) {
                                                            Icon(Icons.Default.RemoveCircle, contentDescription = "-1")
                                                        }
                                                        IconButton(onClick = { blitzAttackerArmies++ }) {
                                                            Icon(Icons.Default.AddCircle, contentDescription = "+1")
                                                        }
                                                    }
                                                }

                                                Column(modifier = Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                                                    Text("Verdedigers", color = Color(0xFF1D3557), fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                                    Text("$blitzDefenderArmies", fontSize = 28.sp, fontWeight = FontWeight.Black, color = Color(0xFF1D3557))
                                                    Row {
                                                        IconButton(onClick = { if (blitzDefenderArmies > 1) blitzDefenderArmies-- }) {
                                                            Icon(Icons.Default.RemoveCircle, contentDescription = "-1")
                                                        }
                                                        IconButton(onClick = { blitzDefenderArmies++ }) {
                                                            Icon(Icons.Default.AddCircle, contentDescription = "+1")
                                                        }
                                                    }
                                                }
                                            }

                                            Button(
                                                onClick = {
                                                    var att = blitzAttackerArmies
                                                    var def = blitzDefenderArmies
                                                    var rounds = 0
                                                    while (att > 1 && def > 0) {
                                                        rounds++
                                                        val aDice = min(3, att - 1)
                                                        val dDice = min(2, def)
                                                        val aRolls = (1..aDice).map { Random.nextInt(1, 7) }.sortedDescending()
                                                        val dRolls = (1..dDice).map { Random.nextInt(1, 7) }.sortedDescending()
                                                        val c = min(aRolls.size, dRolls.size)
                                                        for (i in 0 until c) {
                                                            if (aRolls[i] > dRolls[i]) def--
                                                            else att--
                                                        }
                                                    }
                                                    lastBlitzResult = RiskBlitzResult(
                                                        blitzAttackerArmies,
                                                        blitzDefenderArmies,
                                                        att,
                                                        def,
                                                        def == 0,
                                                        rounds
                                                    )
                                                },
                                                modifier = Modifier.fillMaxWidth().height(48.dp),
                                                shape = RoundedCornerShape(12.dp),
                                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFF4A261))
                                            ) {
                                                Icon(Icons.Default.FlashOn, contentDescription = null, tint = Color.Black)
                                                Spacer(modifier = Modifier.width(6.dp))
                                                Text("Start Blitz!", color = Color.Black, fontWeight = FontWeight.Bold)
                                            }

                                            lastBlitzResult?.let { b ->
                                                HorizontalDivider()
                                                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                                                    Text(
                                                        if (b.attackerWon) "🏆 Aanvaller Heeft Gewonnen!" else "🛡️ Verdediger Houdt Stand!",
                                                        fontWeight = FontWeight.Bold,
                                                        color = if (b.attackerWon) SuccessGreen else Color(0xFF1D3557)
                                                    )
                                                    Text("In ${b.totalRounds} rondes. Aanvaller hield ${b.attackerRemaining} over, verdediger ${b.defenderRemaining}.", fontSize = 12.sp, color = Color.Gray)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        1 -> {
                            // MARK: TAB 1 - VERSTERKINGEN
                            item {
                                val base = max(3, ownedTerritories / 3)
                                var cont = 0
                                if (northAmerica) cont += 5
                                if (southAmerica) cont += 2
                                if (europe) cont += 5
                                if (africa) cont += 3
                                if (asia) cont += 7
                                if (australia) cont += 2
                                val cardBonus = when (cardSetIndex) {
                                    1 -> 4
                                    2 -> 6
                                    3 -> 8
                                    4 -> 10
                                    5 -> 12
                                    6 -> 15
                                    7 -> 20
                                    else -> 0
                                }
                                val total = base + cont + cardBonus

                                AppCard {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Column {
                                            Text("Te plaatsen legers:", fontSize = 12.sp, color = Color.Gray)
                                            Text("$total Legers", fontSize = 32.sp, fontWeight = FontWeight.Black, color = SuccessGreen)
                                        }
                                        Icon(Icons.Default.Shield, contentDescription = null, tint = SuccessGreen, modifier = Modifier.size(44.dp))
                                    }
                                }
                            }

                            item {
                                AppCard {
                                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                        Text("1. Bezette Gebieden ($ownedTerritories)", fontWeight = FontWeight.Bold)
                                        Slider(
                                            value = ownedTerritories.toFloat(),
                                            onValueChange = { ownedTerritories = it.toInt() },
                                            valueRange = 3f..42f,
                                            steps = 38
                                        )
                                        Text("Basis versterking: ${max(3, ownedTerritories / 3)} legers (gebieden ÷ 3, min. 3)", fontSize = 12.sp, color = Color.Gray)
                                    }
                                }
                            }

                            item {
                                AppCard {
                                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                        Text("2. Continent Bonussen", fontWeight = FontWeight.Bold)
                                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                            FilterChip(selected = northAmerica, onClick = { northAmerica = !northAmerica }, label = { Text("Noord-Amerika (+5)", fontSize = 11.sp) }, modifier = Modifier.weight(1f))
                                            FilterChip(selected = southAmerica, onClick = { southAmerica = !southAmerica }, label = { Text("Zuid-Amerika (+2)", fontSize = 11.sp) }, modifier = Modifier.weight(1f))
                                        }
                                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                            FilterChip(selected = europe, onClick = { europe = !europe }, label = { Text("Europa (+5)", fontSize = 11.sp) }, modifier = Modifier.weight(1f))
                                            FilterChip(selected = africa, onClick = { africa = !africa }, label = { Text("Afrika (+3)", fontSize = 11.sp) }, modifier = Modifier.weight(1f))
                                        }
                                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                            FilterChip(selected = asia, onClick = { asia = !asia }, label = { Text("Azië (+7)", fontSize = 11.sp) }, modifier = Modifier.weight(1f))
                                            FilterChip(selected = australia, onClick = { australia = !australia }, label = { Text("Australië (+2)", fontSize = 11.sp) }, modifier = Modifier.weight(1f))
                                        }
                                    }
                                }
                            }

                            item {
                                AppCard {
                                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                        Text("3. Kaartenset Inleveren", fontWeight = FontWeight.Bold)
                                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                            (0..4).forEach { setIdx ->
                                                val label = if (setIdx == 0) "Geen" else "Set $setIdx"
                                                FilterChip(
                                                    selected = cardSetIndex == setIdx,
                                                    onClick = { cardSetIndex = setIdx },
                                                    label = { Text(label, fontSize = 11.sp) }
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        2 -> {
                            // MARK: TAB 2 - MISSIES
                            item {
                                AppCard {
                                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                        Text("🔒 Geheime Missies (Privacy)", fontWeight = FontWeight.Bold)
                                        Text("Houd je vinger op een kaart ingedrukt om jouw geheime doel te bekijken.", fontSize = 12.sp, color = Color.Gray)
                                    }
                                }
                            }

                            itemsIndexed(gamePlayers) { idx, player ->
                                val isRevealed = (revealedMissionPlayerIndex == idx)
                                AppCard(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .pointerInput(Unit) {
                                            detectTapGestures(
                                                onPress = {
                                                    revealedMissionPlayerIndex = idx
                                                    tryAwaitRelease()
                                                    revealedMissionPlayerIndex = null
                                                }
                                            )
                                        }
                                ) {
                                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                        Row(
                                            verticalAlignment = Alignment.CenterVertically,
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Box(modifier = Modifier.size(14.dp).clip(CircleShape).background(player.armyColor.color))
                                            Spacer(modifier = Modifier.width(8.dp))
                                            Text(player.name, fontWeight = FontWeight.Bold)
                                            Spacer(modifier = Modifier.weight(1f))
                                            Text(
                                                if (isRevealed) "ZICHTBAAR" else "VERBORGEN",
                                                fontSize = 11.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = if (isRevealed) Color(0xFFF4A261) else Color.Gray
                                            )
                                        }

                                        if (isRevealed && player.mission != null) {
                                            Column(
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .clip(RoundedCornerShape(8.dp))
                                                    .background(Color(0xFFFFD166).copy(alpha = 0.2f))
                                                    .padding(10.dp)
                                            ) {
                                                Text(player.mission!!.title, fontWeight = FontWeight.Bold, color = Color(0xFFE63946))
                                                Text(player.mission!!.description, fontSize = 12.sp)
                                            }
                                        } else {
                                            Surface(
                                                modifier = Modifier.fillMaxWidth(),
                                                color = MaterialTheme.colorScheme.surfaceVariant,
                                                shape = RoundedCornerShape(8.dp)
                                            ) {
                                                Row(
                                                    modifier = Modifier.padding(12.dp),
                                                    horizontalArrangement = Arrangement.Center,
                                                    verticalAlignment = Alignment.CenterVertically
                                                ) {
                                                    Icon(Icons.Default.TouchApp, contentDescription = null, tint = PrimaryBlue, modifier = Modifier.size(16.dp))
                                                    Spacer(modifier = Modifier.width(6.dp))
                                                    Text("Houd ingedrukt om missie te bekijken", fontSize = 12.sp, color = PrimaryBlue, fontWeight = FontWeight.Bold)
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
        }
    }

    // Winnaar Dialoog
    if (showFinishDialog) {
        AlertDialog(
            onDismissRequest = { showFinishDialog = false },
            title = { Text("Kies de Winnaar") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Selecteer de speler die de geheime missie heeft volbracht of de wereld heeft veroverd:", fontSize = 12.sp)
                    gamePlayers.forEachIndexed { i, p ->
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(8.dp))
                                .clickable { winningPlayerIndex = i }
                                .background(if (winningPlayerIndex == i) SuccessGreen.copy(alpha = 0.2f) else Color.Transparent)
                                .padding(8.dp)
                        ) {
                            Box(modifier = Modifier.size(14.dp).clip(CircleShape).background(p.armyColor.color))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(p.name, fontWeight = FontWeight.Bold)
                            Spacer(modifier = Modifier.weight(1f))
                            if (winningPlayerIndex == i) {
                                Icon(Icons.Default.Check, contentDescription = null, tint = SuccessGreen)
                            }
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val winner = gamePlayers[winningPlayerIndex].name
                        val scores = gamePlayers.map { p ->
                            PlayerScore(
                                playerName = p.name,
                                score = if (p.name == winner) 100 else 0,
                                isWinner = (p.name == winner)
                            )
                        }
                        scoreManager.saveGame(
                            gameName = "Risk",
                            winner = winner,
                            playerScores = scores
                        )
                        showFinishDialog = false
                        showWinnerScreen = true
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = SuccessGreen)
                ) {
                    Text("Opslaan & Vieren!")
                }
            },
            dismissButton = {
                TextButton(onClick = { showFinishDialog = false }) {
                    Text("Annuleren")
                }
            }
        )
    }
}

@Composable
fun AndroidDie(value: Int, isAttacker: Boolean) {
    Surface(
        modifier = Modifier.size(42.dp),
        shape = RoundedCornerShape(8.dp),
        color = if (isAttacker) Color(0xFFE63946) else Color.White,
        border = androidx.compose.foundation.BorderStroke(1.dp, if (isAttacker) Color.Transparent else Color.LightGray),
        shadowElevation = 3.dp
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(
                text = "$value",
                fontWeight = FontWeight.Black,
                fontSize = 20.sp,
                color = if (isAttacker) Color.White else Color.Black
            )
        }
    }
}

fun generateMissions(): List<RiskMission> {
    return listOf(
        RiskMission(1, "Europa & Australië", "Verover geheel Europa en Australië, plus een 3e continent naar keuze."),
        RiskMission(2, "Europa & Zuid-Amerika", "Verover geheel Europa en Zuid-Amerika, plus een 3e continent naar keuze."),
        RiskMission(3, "Noord-Amerika & Afrika", "Verover geheel Noord-Amerika en geheel Afrika."),
        RiskMission(4, "Noord-Amerika & Australië", "Verover geheel Noord-Amerika en geheel Australië."),
        RiskMission(5, "Azië & Zuid-Amerika", "Verover geheel Azië en geheel Zuid-Amerika."),
        RiskMission(6, "Azië & Afrika", "Verover geheel Azië en geheel Afrika."),
        RiskMission(7, "24 Gebieden", "Verover 24 gebieden naar keuze met minimaal 1 leger per gebied."),
        RiskMission(8, "18 Gebieden (Bezetting)", "Verover 18 gebieden met minimaal 2 legers per gebied."),
        RiskMission(9, "Vernietig Rood", "Vernietig alle legers van het Rode leger. (Als je zelf Rood bent of Rood niet meedoet: verover 24 gebieden).", RiskArmyColor.RED),
        RiskMission(10, "Vernietig Blauw", "Vernietig alle legers van het Blauwe leger. (Als je zelf Blauw bent of Blauw niet meedoet: verover 24 gebieden).", RiskArmyColor.BLUE),
        RiskMission(11, "Vernietig Geel", "Vernietig alle legers van het Gele leger. (Als je zelf Geel bent of Geel niet meedoet: verover 24 gebieden).", RiskArmyColor.YELLOW),
        RiskMission(12, "Vernietig Groen", "Vernietig alle legers van het Groene leger. (Als je zelf Groen bent of Groen niet meedoet: verover 24 gebieden).", RiskArmyColor.GREEN),
        RiskMission(13, "Vernietig Zwart", "Vernietig alle legers van het Zwarte leger. (Als je zelf Zwart bent of Zwart niet meedoet: verover 24 gebieden).", RiskArmyColor.BLACK),
        RiskMission(14, "Vernietig Paars", "Vernietig alle legers van het Paarse leger. (Als je zelf Paars bent of Paars niet meedoet: verover 24 gebieden).", RiskArmyColor.PURPLE)
    )
}
