package nl.nnbp.gamesapp.ui.screens.games.qwixx

import androidx.compose.animation.AnimatedVisibility
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
import nl.nnbp.gamesapp.ui.components.SavedPlayersQuickChips
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SuccessGreen
import nl.nnbp.gamesapp.ui.theme.WarningRed

data class QwixxSheet(
    var redCrosses: Int = 0,
    var yellowCrosses: Int = 0,
    var greenCrosses: Int = 0,
    var blueCrosses: Int = 0,
    var misworpen: Int = 0,
    var directScore: Int = 0
) {
    private fun points(crosses: Int): Int = if (crosses > 0) (crosses * (crosses + 1)) / 2 else 0

    fun total(isDirectMode: Boolean): Int {
        if (isDirectMode) return directScore
        val r = points(redCrosses)
        val y = points(yellowCrosses)
        val g = points(greenCrosses)
        val b = points(blueCrosses)
        return r + y + g + b - (misworpen * 5)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QwixxScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }

    var isGameStarted by remember { mutableStateOf(false) }
    var selectedPlayerNames by remember { mutableStateOf(mutableListOf<String>()) }
    var isDirectMode by remember { mutableStateOf(false) }

    var sheets by remember { mutableStateOf(mutableListOf<QwixxSheet>()) }
    var expandedPlayerIndex by remember { mutableStateOf<Int?>(0) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerPlayer by remember { mutableStateOf<String?>(null) }

    val calculatedTotals = remember(sheets, isDirectMode) {
        sheets.map { it.total(isDirectMode) }
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

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Qwixx", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Terug")
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
                                text = "Spelregels Qwixx 🎲",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Kruis zoveel mogelijk getallen aan in 4 kleuren (Rood, Geel, Groen, Blauw). Elk kruisje meer levert steeds meer punten op volgens n*(n+1)/2. Elke misworp kost -5 punten. De hoogste score wint!",
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
                                Text("Invoermethode:", fontWeight = FontWeight.SemiBold)
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    FilterChip(
                                        selected = !isDirectMode,
                                        onClick = { isDirectMode = false },
                                        label = { Text("Kleurrijen") },
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
                                if (list.contains(name)) list.remove(name) else list.add(name)
                                selectedPlayerNames = list
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
                        sheets = MutableList(selectedPlayerNames.size) { QwixxSheet() }
                        isGameStarted = true
                    },
                    enabled = selectedPlayerNames.size >= 2,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text("Start Qwixx Formulier", style = MaterialTheme.typography.titleMedium)
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
                                Text("Scoreoverzicht", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
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
                        val sheet = sheets.getOrElse(index) { QwixxSheet() }
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
                                    Text(playerName, style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
                                    Text(
                                        text = "$total pt",
                                        style = MaterialTheme.typography.headlineSmall.copy(
                                            fontWeight = FontWeight.Bold,
                                            color = PrimaryBlue
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
                                            // 4 Kleurenrijen + Misworpen
                                            QwixxRowStepper(
                                                title = "🔴 Rood (2 ➔ 12)",
                                                count = sheet.redCrosses,
                                                color = Color(0xFFE53935),
                                                onCountChange = {
                                                    val list = sheets.toMutableList()
                                                    list[index] = list[index].copy(redCrosses = it)
                                                    sheets = list
                                                }
                                            )

                                            QwixxRowStepper(
                                                title = "🟡 Geel (2 ➔ 12)",
                                                count = sheet.yellowCrosses,
                                                color = Color(0xFFFDD835),
                                                onCountChange = {
                                                    val list = sheets.toMutableList()
                                                    list[index] = list[index].copy(yellowCrosses = it)
                                                    sheets = list
                                                }
                                            )

                                            QwixxRowStepper(
                                                title = "🟢 Groen (12 ➔ 2)",
                                                count = sheet.greenCrosses,
                                                color = Color(0xFF43A047),
                                                onCountChange = {
                                                    val list = sheets.toMutableList()
                                                    list[index] = list[index].copy(greenCrosses = it)
                                                    sheets = list
                                                }
                                            )

                                            QwixxRowStepper(
                                                title = "🔵 Blauw (12 ➔ 2)",
                                                count = sheet.blueCrosses,
                                                color = Color(0xFF1E88E5),
                                                onCountChange = {
                                                    val list = sheets.toMutableList()
                                                    list[index] = list[index].copy(blueCrosses = it)
                                                    sheets = list
                                                }
                                            )

                                            QwixxRowStepper(
                                                title = "⚠️ Misworpen (-5 pt elk)",
                                                count = sheet.misworpen,
                                                maxCount = 4,
                                                color = WarningRed,
                                                onCountChange = {
                                                    val list = sheets.toMutableList()
                                                    list[index] = list[index].copy(misworpen = it)
                                                    sheets = list
                                                }
                                            )
                                        } else {
                                            NumericScoreStepper(
                                                score = sheet.directScore,
                                                onScoreChange = {
                                                    val list = sheets.toMutableList()
                                                    list[index] = list[index].copy(directScore = it)
                                                    sheets = list
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
                            gameName = "Qwixx",
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
                    Text("Spel Voltooien & Opslaan", style = MaterialTheme.typography.titleMedium)
                }
            }
        }
    }
}

@Composable
fun QwixxRowStepper(
    title: String,
    count: Int,
    color: Color,
    maxCount: Int = 12,
    onCountChange: (Int) -> Unit
) {
    val points = if (maxCount == 4) count * -5 else (count * (count + 1)) / 2

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            Text(title, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
            Text("$count kruisjes = ${if (points >= 0) "+" else ""}$points pt", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
        }

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            FilledTonalButton(
                onClick = { if (count > 0) onCountChange(count - 1) },
                modifier = Modifier.size(32.dp),
                contentPadding = PaddingValues(0.dp),
                shape = CircleShape
            ) {
                Text("-", fontWeight = FontWeight.Bold)
            }

            Text(
                text = "$count",
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                modifier = Modifier.width(24.dp)
            )

            FilledTonalButton(
                onClick = { if (count < maxCount) onCountChange(count + 1) },
                modifier = Modifier.size(32.dp),
                contentPadding = PaddingValues(0.dp),
                shape = CircleShape
            ) {
                Text("+", fontWeight = FontWeight.Bold)
            }
        }
    }
}
