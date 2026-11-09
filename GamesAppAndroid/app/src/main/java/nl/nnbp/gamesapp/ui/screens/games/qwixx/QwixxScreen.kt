package nl.nnbp.gamesapp.ui.screens.games.qwixx

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
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SuccessGreen
import nl.nnbp.gamesapp.ui.theme.WarningRed

data class QwixxPlayerSheet(
    var redCrosses: Int = 0,
    var yellowCrosses: Int = 0,
    var greenCrosses: Int = 0,
    var blueCrosses: Int = 0,
    var misworpen: Int = 0
) {
    fun colorPoints(crosses: Int): Int = if (crosses > 0) (crosses * (crosses + 1)) / 2 else 0

    fun total(): Int {
        val r = colorPoints(redCrosses)
        val y = colorPoints(yellowCrosses)
        val g = colorPoints(greenCrosses)
        val b = colorPoints(blueCrosses)
        return r + y + g + b - (misworpen * 5)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QwixxScreen(
    onNavigateBack: () -> Unit,
    autoResume: Boolean = false
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }

    val session = remember { activeGameManager.activeSession.value }
    val isResumeActive = autoResume && session != null && session.gameName == "Qwixx"

    var isGameStarted by remember { mutableStateOf(isResumeActive) }
    var selectedPlayerNames by remember {
        mutableStateOf(
            if (isResumeActive && session != null) session.playerNames.toMutableList()
            else mutableListOf<String>()
        )
    }
    var selectedPlayerCount by remember { mutableIntStateOf(3) }
    var gameMode by remember { mutableStateOf("formulier") } // "formulier", "snel"
    var showTafelschikkingDialog by remember { mutableStateOf(false) }

    // Quick score screen navigation
    var startQuickScoreGame by remember { mutableStateOf(false) }
    if (startQuickScoreGame) {
        SnelleEindscoreScreen(
            gameName = "Qwixx",
            playerNames = selectedPlayerNames,
            isLowestScoreWins = false,
            scoreUnit = "pt",
            onNavigateBack = { startQuickScoreGame = false }
        )
        return
    }

    // In-game states
    var sheets by remember { mutableStateOf(mutableListOf<QwixxPlayerSheet>()) }
    var selectedPlayerTab by remember { mutableIntStateOf(0) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }

    val calculatedTotals = remember(sheets) {
        sheets.map { it.total() }
    }

    fun saveDraft() {
        if (selectedPlayerNames.isEmpty() || !isGameStarted) return
        val scoreSummary = selectedPlayerNames.indices.joinToString(", ") { "${selectedPlayerNames[it]}:${calculatedTotals.getOrElse(it) { 0 }}" }
        val summary = "${selectedPlayerNames.size} spelers • Stand: $scoreSummary"
        val state = mutableMapOf<String, String>()
        state["gameMode"] = gameMode
        for (i in selectedPlayerNames.indices) {
            val s = sheets.getOrNull(i) ?: QwixxPlayerSheet()
            state["s_${i}_red"] = s.redCrosses.toString()
            state["s_${i}_yellow"] = s.yellowCrosses.toString()
            state["s_${i}_green"] = s.greenCrosses.toString()
            state["s_${i}_blue"] = s.blueCrosses.toString()
            state["s_${i}_misworpen"] = s.misworpen.toString()
        }

        activeGameManager.saveActiveGame(
            gameName = "Qwixx",
            playerNames = selectedPlayerNames,
            currentRound = 1,
            summary = summary,
            state = state
        )
    }

    LaunchedEffect(isResumeActive) {
        if (isResumeActive && session != null) {
            session.stateData["gameMode"]?.let { gameMode = it }
            val list = mutableListOf<QwixxPlayerSheet>()
            for (i in selectedPlayerNames.indices) {
                val data = QwixxPlayerSheet(
                    redCrosses = session.stateData["s_${i}_red"]?.toIntOrNull() ?: 0,
                    yellowCrosses = session.stateData["s_${i}_yellow"]?.toIntOrNull() ?: 0,
                    greenCrosses = session.stateData["s_${i}_green"]?.toIntOrNull() ?: 0,
                    blueCrosses = session.stateData["s_${i}_blue"]?.toIntOrNull() ?: 0,
                    misworpen = session.stateData["s_${i}_misworpen"]?.toIntOrNull() ?: 0
                )
                list.add(data)
            }
            if (list.size == selectedPlayerNames.size) {
                sheets = list
            }
        }
    }

    LaunchedEffect(sheets) {
        if (isGameStarted && sheets.isNotEmpty()) {
            saveDraft()
        }
    }

    if (isGameOver && winnerPlayer != null) {
        val playerScores = selectedPlayerNames.indices.map { i ->
            PlayerScore(
                playerName = selectedPlayerNames[i],
                score = calculatedTotals.getOrElse(i) { 0 },
                isWinner = selectedPlayerNames[i] == winnerPlayer
            )
        }
        WinnaarScreen(
            gameName = "Qwixx",
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
            id = "formulier",
            title = "Digitaal Formulier",
            icon = Icons.Default.Casino,
            description = "📝 Speel met het officiële digitale scoreblad. Vul kruisjes in per kleurrij en bereken automatisch de score."
        ),
        GameModeItem(
            id = "snel",
            title = "Direct Totaal",
            icon = Icons.Default.Bolt,
            description = "⚡️ Vul direct het totale puntenaantal per speler in zonder rijen bij te houden."
        )
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        GameLogoImage(gameType = GameType.QWIXX, size = 30.dp, cornerRadius = 8.dp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Qwixx", fontWeight = FontWeight.Bold, fontSize = 18.sp)
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Terug")
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
                            gameType = GameType.QWIXX,
                            subtitle = "Klassiek dobbelspel • Rood, Geel, Groen & Blauw 🎲",
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
                            maxPlayers = 5,
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
                                sheets = MutableList(selectedPlayerNames.size) { QwixxPlayerSheet() }
                                selectedPlayerTab = 0
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
                            if (gameMode == "snel") "⚡️ Snelle Eindscore Starten" else "Start Digitaal Scoreblad (${selectedPlayerNames.size} spelers)",
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                        )
                    }
                }
            }
        } else {
            // IN-GAME SCOREBLAD
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
                            themeColor = AccentOrange
                        )
                    }

                    // Speler Selector Tabs
                    item {
                        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            itemsIndexed(selectedPlayerNames) { idx, name ->
                                val isSel = selectedPlayerTab == idx
                                val total = calculatedTotals.getOrElse(idx) { 0 }

                                Surface(
                                    shape = RoundedCornerShape(12.dp),
                                    color = if (isSel) AccentOrange else MaterialTheme.colorScheme.surfaceVariant,
                                    border = androidx.compose.foundation.BorderStroke(
                                        width = if (isSel) 2.dp else 1.dp,
                                        color = if (isSel) AccentOrange else Color.Gray.copy(alpha = 0.3f)
                                    ),
                                    modifier = Modifier.clickable { selectedPlayerTab = idx }
                                ) {
                                    Column(
                                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                                        horizontalAlignment = Alignment.CenterHorizontally
                                    ) {
                                        Text(
                                            text = name,
                                            fontWeight = if (isSel) FontWeight.Bold else FontWeight.Medium,
                                            color = if (isSel) Color.White else MaterialTheme.colorScheme.onSurface,
                                            fontSize = 14.sp
                                        )
                                        Text(
                                            text = "$total pt",
                                            fontWeight = FontWeight.Black,
                                            color = if (isSel) Color.White else AccentOrange,
                                            fontSize = 12.sp
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Scoreblad van geselecteerde speler
                    val activePlayerName = selectedPlayerNames.getOrElse(selectedPlayerTab) { "" }
                    val activeSheet = sheets.getOrElse(selectedPlayerTab) { QwixxPlayerSheet() }

                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column {
                                        Text("Scoreblad van $activePlayerName", fontWeight = FontWeight.Bold, fontSize = 16.sp)
                                        Text("1x=1pt, 2x=3pt, 3x=6pt, ..., 12x=78pt", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))
                                    }
                                    Text(
                                        text = "${activeSheet.total()} pt",
                                        fontWeight = FontWeight.Black,
                                        fontSize = 22.sp,
                                        color = AccentOrange
                                    )
                                }

                                HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f))

                                // Rood (2 -> 12)
                                QwixxColorRow(
                                    title = "🔴 Rood (2 ➔ 12)",
                                    count = activeSheet.redCrosses,
                                    color = Color(0xFFE53935),
                                    onCountChange = {
                                        val list = sheets.toMutableList()
                                        list[selectedPlayerTab] = list[selectedPlayerTab].copy(redCrosses = it)
                                        sheets = list
                                    }
                                )

                                // Geel (2 -> 12)
                                QwixxColorRow(
                                    title = "🟡 Geel (2 ➔ 12)",
                                    count = activeSheet.yellowCrosses,
                                    color = Color(0xFFFDD835),
                                    onCountChange = {
                                        val list = sheets.toMutableList()
                                        list[selectedPlayerTab] = list[selectedPlayerTab].copy(yellowCrosses = it)
                                        sheets = list
                                    }
                                )

                                // Groen (12 -> 2)
                                QwixxColorRow(
                                    title = "🟢 Groen (12 ➔ 2)",
                                    count = activeSheet.greenCrosses,
                                    color = Color(0xFF43A047),
                                    onCountChange = {
                                        val list = sheets.toMutableList()
                                        list[selectedPlayerTab] = list[selectedPlayerTab].copy(greenCrosses = it)
                                        sheets = list
                                    }
                                )

                                // Blauw (12 -> 2)
                                QwixxColorRow(
                                    title = "🔵 Blauw (12 ➔ 2)",
                                    count = activeSheet.blueCrosses,
                                    color = Color(0xFF1E88E5),
                                    onCountChange = {
                                        val list = sheets.toMutableList()
                                        list[selectedPlayerTab] = list[selectedPlayerTab].copy(blueCrosses = it)
                                        sheets = list
                                    }
                                )

                                // Misworpen (-5 pt elk)
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(10.dp))
                                        .background(WarningRed.copy(alpha = 0.12f))
                                        .border(1.dp, WarningRed.copy(alpha = 0.3f), RoundedCornerShape(10.dp))
                                        .padding(horizontal = 12.dp, vertical = 8.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column {
                                        Text("⚠️ Misworpen (-5 pt elk)", fontWeight = FontWeight.Bold, fontSize = 13.sp, color = WarningRed)
                                        Text("Aantal: ${activeSheet.misworpen} (-${activeSheet.misworpen * 5} pt)", fontSize = 11.sp, color = WarningRed.copy(alpha = 0.8f))
                                    }

                                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                        for (i in 0..4) {
                                            val isChecked = i <= activeSheet.misworpen && i > 0
                                            Box(
                                                modifier = Modifier
                                                    .size(28.dp)
                                                    .clip(RoundedCornerShape(6.dp))
                                                    .background(if (isChecked) WarningRed else Color.Transparent)
                                                    .border(1.dp, WarningRed, RoundedCornerShape(6.dp))
                                                    .clickable {
                                                        val list = sheets.toMutableList()
                                                        val newCount = if (activeSheet.misworpen == i) i - 1 else i
                                                        list[selectedPlayerTab] = list[selectedPlayerTab].copy(misworpen = newCount.coerceIn(0, 4))
                                                        sheets = list
                                                    },
                                                contentAlignment = Alignment.Center
                                            ) {
                                                Text(
                                                    if (i == 0) "0" else "$i",
                                                    fontSize = 11.sp,
                                                    fontWeight = FontWeight.Bold,
                                                    color = if (isChecked) Color.White else WarningRed
                                                )
                                            }
                                        }
                                    }
                                }

                                // Score breakdown banner
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(10.dp))
                                        .background(MaterialTheme.colorScheme.surface)
                                        .padding(horizontal = 10.dp, vertical = 8.dp),
                                    horizontalArrangement = Arrangement.SpaceAround
                                ) {
                                    val rPts = activeSheet.colorPoints(activeSheet.redCrosses)
                                    val yPts = activeSheet.colorPoints(activeSheet.yellowCrosses)
                                    val gPts = activeSheet.colorPoints(activeSheet.greenCrosses)
                                    val bPts = activeSheet.colorPoints(activeSheet.blueCrosses)
                                    val misPts = activeSheet.misworpen * 5

                                    Text("🔴 $rPts", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                    Text("+", fontSize = 11.sp)
                                    Text("🟡 $yPts", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                    Text("+", fontSize = 11.sp)
                                    Text("🟢 $gPts", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                    Text("+", fontSize = 11.sp)
                                    Text("🔵 $bPts", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                    Text("-", fontSize = 11.sp)
                                    Text("⚠️ $misPts", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = WarningRed)
                                    Text("=", fontSize = 11.sp)
                                    Text("${activeSheet.total()} pt", fontSize = 12.sp, fontWeight = FontWeight.Black, color = AccentOrange)
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
                    colors = ButtonDefaults.buttonColors(containerColor = AccentOrange),
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text("Spel Afronden & Uitslag Bekijken 🏆", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
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
}

@Composable
fun QwixxColorRow(
    title: String,
    count: Int,
    color: Color,
    onCountChange: (Int) -> Unit
) {
    val pts = if (count > 0) (count * (count + 1)) / 2 else 0

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .background(color.copy(alpha = 0.12f))
            .border(1.dp, color.copy(alpha = 0.35f), RoundedCornerShape(10.dp))
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            Text(title, fontWeight = FontWeight.Bold, fontSize = 13.sp, color = color)
            Text("$count kruisjes = $pts pt", fontSize = 11.sp, color = color.copy(alpha = 0.85f), fontWeight = FontWeight.SemiBold)
        }

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            FilledTonalButton(
                onClick = { if (count > 0) onCountChange(count - 1) },
                contentPadding = PaddingValues(0.dp),
                modifier = Modifier.size(32.dp),
                shape = CircleShape
            ) {
                Text("-", fontWeight = FontWeight.Bold, fontSize = 16.sp)
            }

            Box(
                modifier = Modifier
                    .width(36.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(color)
                    .padding(vertical = 4.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "$count",
                    fontWeight = FontWeight.Black,
                    color = Color.White,
                    fontSize = 14.sp
                )
            }

            FilledTonalButton(
                onClick = { if (count < 12) onCountChange(count + 1) },
                contentPadding = PaddingValues(0.dp),
                modifier = Modifier.size(32.dp),
                shape = CircleShape
            ) {
                Text("+", fontWeight = FontWeight.Bold, fontSize = 16.sp)
            }
        }
    }
}
