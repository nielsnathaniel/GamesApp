package nl.nnbp.gamesapp.ui.screens.games.nmbr9

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun Nmbr9Screen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }

    var isGameStarted by remember { mutableStateOf(false) }
    var selectedPlayerNames by remember { mutableStateOf(mutableListOf<String>()) }

    // Per speler: scores per verdieping/laag (Laag 1 = 1x, Laag 2 = 2x, Laag 3 = 3x, Laag 4 = 4x)
    // Waarde op Laag 0 telt voor 0 pt volgens officiële spelregels
    var playerLevelPoints by remember { mutableStateOf(mutableListOf<MutableList<Int>>()) }
    var expandedPlayerIndex by remember { mutableStateOf<Int?>(0) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }
    var showEditScoresDialog by remember { mutableStateOf(false) }
    var isQuickScoreMode by remember { mutableStateOf(false) }
    var startQuickScoreGame by remember { mutableStateOf(false) }

    if (startQuickScoreGame) {
        SnelleEindscoreScreen(
            gameName = "Nmbr9",
            playerNames = selectedPlayerNames,
            isLowestScoreWins = false,
            scoreUnit = "pt",
            onNavigateBack = { startQuickScoreGame = false }
        )
        return
    }

    // Bereken totale score per speler: Laag 1 * 1 + Laag 2 * 2 + Laag 3 * 3 + Laag 4 * 4
    val computedScores = remember(playerLevelPoints) {
        playerLevelPoints.map { levels ->
            val l1 = levels.getOrElse(0) { 0 } * 1
            val l2 = levels.getOrElse(1) { 0 } * 2
            val l3 = levels.getOrElse(2) { 0 } * 3
            val l4 = levels.getOrElse(3) { 0 } * 4
            l1 + l2 + l3 + l4
        }
    }

    if (isGameOver && winnerPlayer != null) {
        val playerScores = selectedPlayerNames.indices.map { i ->
            PlayerScore(
                playerName = selectedPlayerNames[i],
                score = computedScores.getOrElse(i) { 0 },
                isWinner = selectedPlayerNames[i] == winnerPlayer
            )
        }
        WinnaarScreen(
            gameName = "Nmbr9",
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
                title = { Text("Nmbr9", fontWeight = FontWeight.Bold) },
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
                                text = "Spelregels Nmbr9 🧩",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Puzzel met cijfertegels in lagen. Cijfers op de begane grond (Laag 0) leveren 0 pt op. Op Laag 1 tellen ze 1x, op Laag 2 tellen ze 2x, op Laag 3 tellen ze 3x, etc. De hoogste totaalscore wint!",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
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
                                    label = { Text("Lagen tellen") },
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
                            Text(
                                text = "Voeg minimaal 1 speler toe.",
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

                Button(
                    onClick = {
                        if (isQuickScoreMode) {
                            startQuickScoreGame = true
                        } else {
                            playerLevelPoints = MutableList(selectedPlayerNames.size) { mutableListOf(0, 0, 0, 0) }
                            isGameStarted = true
                        }
                    },
                    enabled = selectedPlayerNames.isNotEmpty(),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text(
                        if (isQuickScoreMode) "Start Snelle Eindscore" else "Start Berekening",
                        style = MaterialTheme.typography.titleMedium
                    )
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
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
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
                                    Text("Nmbr9 Eindtelling", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
                                    Text("Laag 1 = 1x • Laag 2 = 2x • Laag 3 = 3x • Laag 4 = 4x", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                                }
                                val leader = selectedPlayerNames.indices.maxByOrNull { computedScores.getOrElse(it) { 0 } }
                                if (leader != null) {
                                    Surface(shape = RoundedCornerShape(8.dp), color = PrimaryBlue.copy(alpha = 0.12f)) {
                                        Text(
                                            text = "Leider: ${selectedPlayerNames[leader]} (${computedScores[leader]} pt)",
                                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold, color = PrimaryBlue),
                                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }

                    itemsIndexed(selectedPlayerNames) { index, playerName ->
                        val isExpanded = expandedPlayerIndex == index
                        val totalScore = computedScores.getOrElse(index) { 0 }
                        val levels = playerLevelPoints.getOrElse(index) { mutableListOf(0, 0, 0, 0) }

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
                                    Text(playerName, style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
                                    Text(
                                        text = "$totalScore pt",
                                        style = MaterialTheme.typography.headlineSmall.copy(fontWeight = FontWeight.Bold, color = PrimaryBlue)
                                    )
                                }

                                AnimatedVisibility(visible = isExpanded) {
                                    Column(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(top = 12.dp),
                                        verticalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))

                                        listOf(
                                            Triple("Laag 1 (1x waarde)", 0, 1),
                                            Triple("Laag 2 (2x waarde)", 1, 2),
                                            Triple("Laag 3 (3x waarde)", 2, 3),
                                            Triple("Laag 4 (4x waarde)", 3, 4)
                                        ).forEach { (label, lIdx, multiplier) ->
                                            val pts = levels.getOrElse(lIdx) { 0 }
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                horizontalArrangement = Arrangement.SpaceBetween,
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Column {
                                                    Text(label, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
                                                    Text("Cijfersom: $pts • Totaal: ${pts * multiplier} pt", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                                }
                                                NumericScoreStepper(
                                                    score = pts,
                                                    onScoreChange = { newVal ->
                                                        val list = playerLevelPoints.toMutableList()
                                                        val pLevels = list[index].toMutableList()
                                                        pLevels[lIdx] = maxOf(0, newVal)
                                                        list[index] = pLevels
                                                        playerLevelPoints = list
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
                }

                Button(
                    onClick = {
                        val maxScore = computedScores.maxOrNull() ?: 0
                        val winnerIdx = computedScores.indexOf(maxScore)
                        val winner = selectedPlayerNames.getOrElse(winnerIdx) { "" }
                        winnerPlayer = winner

                        val detailed = selectedPlayerNames.indices.map { idx ->
                            PlayerScoreDetail(
                                name = selectedPlayerNames[idx],
                                score = computedScores[idx]
                            )
                        }
                        scoreManager.saveGame(
                            gameName = "Nmbr9",
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
                    Text("Afronden & Opslaan", style = MaterialTheme.typography.titleMedium)
                }
            }
        }
    }

    if (showEditScoresDialog) {
        PuntenWijzigenDialog(
            playerNames = selectedPlayerNames,
            currentScores = computedScores,
            isLowestScoreWins = false,
            onDismiss = { showEditScoresDialog = false },
            onSave = { newScores ->
                playerLevelPoints = newScores.indices.map { i ->
                    val pts = newScores.getOrElse(i) { 0 }
                    mutableListOf(pts, 0, 0, 0)
                }.toMutableList()
            }
        )
    }
}
