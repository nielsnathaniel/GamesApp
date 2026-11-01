package nl.nnbp.gamesapp.ui.screens.games.pighole

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
import nl.nnbp.gamesapp.data.model.GameType
import nl.nnbp.gamesapp.ui.components.*
import nl.nnbp.gamesapp.ui.screens.games.SnelleEindscoreScreen
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SuccessGreen
import nl.nnbp.gamesapp.ui.theme.WarningRed

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PigHoleScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }

    var isGameStarted by remember { mutableStateOf(false) }
    var selectedPlayerNames by remember { mutableStateOf(mutableListOf<String>()) }

    var currentRound by remember { mutableIntStateOf(1) }
    var turnIndex by remember { mutableIntStateOf(0) }
    var pigsPerPlayer by remember { mutableStateOf(mutableListOf<Int>()) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }
    var showFinishConfirmDialog by remember { mutableStateOf(false) }
    var showEditScoresDialog by remember { mutableStateOf(false) }
    var isQuickScoreMode by remember { mutableStateOf(false) }
    var startQuickScoreGame by remember { mutableStateOf(false) }

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
                                    description = "🎮 Begeleid elke ronde: R1 (max 1 worp), R2 (max 2 worpen), daarna onbeperkt."
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

                    item {
                        // Actieve speler beurt banner
                        val turnPlayer = selectedPlayerNames.getOrElse(turnIndex) { "" }
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
                                    Text("Aan de beurt om te gooien:", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                    Text(turnPlayer, style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
                                }
                                Button(
                                    onClick = {
                                        val nextTurn = (turnIndex + 1) % selectedPlayerNames.size
                                        if (nextTurn == 0) {
                                            currentRound += 1
                                        }
                                        turnIndex = nextTurn
                                    },
                                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                                ) {
                                    Text("Beurt klaar ➡️")
                                }
                            }
                        }
                    }

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
                                        Text(playerName, style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
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
                                    // -1 Kwijt (in een gat gegooid of in de pot)
                                    Button(
                                        onClick = {
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
                                        Text("-1 Kwijt 🎯", fontWeight = FontWeight.Bold)
                                    }

                                    // +1 Bezet
                                    FilledTonalButton(
                                        onClick = {
                                            val list = pigsPerPlayer.toMutableList()
                                            list[index] += 1
                                            pigsPerPlayer = list
                                        },
                                        modifier = Modifier.weight(1f),
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text("+1 Bezet", fontWeight = FontWeight.Bold)
                                    }

                                    // +2 Bezet
                                    FilledTonalButton(
                                        onClick = {
                                            val list = pigsPerPlayer.toMutableList()
                                            list[index] += 2
                                            pigsPerPlayer = list
                                        },
                                        modifier = Modifier.weight(1f),
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text("+2 Bezet", fontWeight = FontWeight.Bold)
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
