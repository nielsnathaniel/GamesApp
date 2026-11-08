package nl.nnbp.gamesapp.ui.screens.games

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.model.PlayerScore
import nl.nnbp.gamesapp.ui.components.AppCard
import nl.nnbp.gamesapp.ui.components.NumericScoreStepper
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SuccessGreen
import nl.nnbp.gamesapp.ui.theme.WarningRed

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SnelleEindscoreScreen(
    gameName: String,
    playerNames: List<String>,
    isLowestScoreWins: Boolean = false,
    scoreUnit: String = "pt",
    initialScore: Int = 0,
    onNavigateBack: () -> Unit,
    onFinishGame: (() -> Unit)? = null
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    var scores by remember { mutableStateOf(playerNames.map { initialScore }.toMutableList()) }
    var isGameOver by remember { mutableStateOf(false) }

    val isFiftyFifty = gameName.equals("Fifty Fifty", ignoreCase = true) || gameName.equals("FiftyFifty", ignoreCase = true)
    var manuallyEnteredIndices by remember { mutableStateOf(setOf<Int>()) }
    var autoFilledIndex by remember { mutableStateOf<Int?>(null) }
    val fiftyFiftyTotal = scores.sum()
    val isFiftyFiftyValid = !isFiftyFifty || fiftyFiftyTotal == 100

    fun updatePlayerScore(idx: Int, newScore: Int, isManual: Boolean = true) {
        val clamped = if (isFiftyFifty) newScore.coerceIn(0, 100) else newScore
        val list = scores.toMutableList()
        if (idx < list.size) {
            list[idx] = clamped
        }
        if (isFiftyFifty) {
            val updatedManual = manuallyEnteredIndices.toMutableSet()
            if (isManual) {
                updatedManual.add(idx)
                if (autoFilledIndex == idx) {
                    autoFilledIndex = null
                }
            }
            manuallyEnteredIndices = updatedManual

            val unentered = playerNames.indices.filter { !updatedManual.contains(it) }
            if (unentered.size == 1) {
                val targetIdx = unentered[0]
                val sumOthers = playerNames.indices.filter { it != targetIdx }.sumOf { list.getOrElse(it) { 0 } }
                val remainder = (100 - sumOthers).coerceAtLeast(0)
                if (targetIdx < list.size) {
                    list[targetIdx] = remainder
                    autoFilledIndex = targetIdx
                }
            }
        }
        scores = list
    }

    // Live rangorde
    val sortedIndices = remember(scores, isLowestScoreWins) {
        playerNames.indices.sortedWith { a, b ->
            val scoreA = scores.getOrElse(a) { 0 }
            val scoreB = scores.getOrElse(b) { 0 }
            if (isLowestScoreWins) scoreA.compareTo(scoreB) else scoreB.compareTo(scoreA)
        }
    }

    if (isGameOver) {
        val winningIndex = sortedIndices.firstOrNull() ?: 0
        val winnerName = playerNames.getOrElse(winningIndex) { "" }
        val playerScores = playerNames.indices.map { idx ->
            PlayerScore(
                playerName = playerNames[idx],
                score = scores.getOrElse(idx) { 0 },
                isWinner = idx == winningIndex
            )
        }

        WinnaarScreen(
            gameName = gameName,
            winnerName = winnerName,
            scores = playerScores,
            onFinish = {
                onFinishGame?.invoke() ?: onNavigateBack()
            }
        )
        return
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(gameName, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                        Text(
                            "Snelle eindscore invoer",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item {
                    AppCard {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Text("⚡️", fontSize = 24.sp)
                            Column {
                                Text(
                                    "Directe Eindstand",
                                    fontWeight = FontWeight.Bold,
                                    style = MaterialTheme.typography.titleMedium
                                )
                                Text(
                                    text = if (isLowestScoreWins) "Minste punten wint. Vul per speler de eindscore in." else "Meeste punten wint. Vul per speler de eindscore in.",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                                )
                            }
                        }
                    }
                }

                if (isFiftyFifty) {
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = when {
                                    isFiftyFiftyValid -> SuccessGreen.copy(alpha = 0.12f)
                                    fiftyFiftyTotal > 100 -> WarningRed.copy(alpha = 0.12f)
                                    else -> AccentOrange.copy(alpha = 0.12f)
                                }
                            ),
                            border = androidx.compose.foundation.BorderStroke(
                                1.5.dp,
                                when {
                                    isFiftyFiftyValid -> SuccessGreen.copy(alpha = 0.4f)
                                    fiftyFiftyTotal > 100 -> WarningRed.copy(alpha = 0.4f)
                                    else -> AccentOrange.copy(alpha = 0.4f)
                                }
                            )
                        ) {
                            Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text(
                                            when {
                                                isFiftyFiftyValid -> "✅"
                                                fiftyFiftyTotal > 100 -> "❌"
                                                else -> "⚠️"
                                            },
                                            fontSize = 20.sp
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Column {
                                            Text(
                                                "Totaal: $fiftyFiftyTotal / 100 strafkaarten",
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 15.sp,
                                                color = when {
                                                    isFiftyFiftyValid -> SuccessGreen
                                                    fiftyFiftyTotal > 100 -> WarningRed
                                                    else -> AccentOrange
                                                }
                                            )
                                            Text(
                                                when {
                                                    isFiftyFiftyValid -> "Klopt exact! Alle 100 kaarten zijn verdeeld."
                                                    fiftyFiftyTotal < 100 -> "Nog ${100 - fiftyFiftyTotal} strafkaarten te verdelen."
                                                    else -> "${fiftyFiftyTotal - 100} strafkaarten te veel ingevoerd!"
                                                },
                                                fontSize = 11.sp,
                                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                                            )
                                        }
                                    }
                                    Surface(
                                        shape = RoundedCornerShape(8.dp),
                                        color = when {
                                            isFiftyFiftyValid -> SuccessGreen.copy(alpha = 0.2f)
                                            fiftyFiftyTotal > 100 -> WarningRed.copy(alpha = 0.2f)
                                            else -> AccentOrange.copy(alpha = 0.2f)
                                        }
                                    ) {
                                        Text(
                                            "$fiftyFiftyTotal / 100",
                                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                            fontSize = 12.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = when {
                                                isFiftyFiftyValid -> SuccessGreen
                                                fiftyFiftyTotal > 100 -> WarningRed
                                                else -> AccentOrange
                                            }
                                        )
                                    }
                                }

                                val unentered = playerNames.indices.filter { !manuallyEnteredIndices.contains(it) }
                                if (unentered.size == 1 && fiftyFiftyTotal != 100) {
                                    val targetIdx = unentered[0]
                                    val sumOthers = playerNames.indices.filter { it != targetIdx }.sumOf { scores.getOrElse(it) { 0 } }
                                    val remainder = (100 - sumOthers).coerceAtLeast(0)
                                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                                        TextButton(
                                            onClick = {
                                                updatePlayerScore(targetIdx, remainder, isManual = true)
                                            },
                                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                                        ) {
                                            Text(
                                                "⚡ Vul restant in bij ${playerNames[targetIdx]} ($remainder pt)",
                                                fontSize = 11.sp,
                                                color = AccentOrange,
                                                fontWeight = FontWeight.SemiBold
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                itemsIndexed(playerNames) { idx, name ->
                    val profile = scoreManager.getPlayerProfile(name)
                    val playerColor = Color(profile.colorHex)
                    val rank = sortedIndices.indexOf(idx) + 1
                    val currentScore = scores.getOrElse(idx) { 0 }

                    AppCard {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                // Medaille of rang
                                Box(
                                    modifier = Modifier
                                        .size(32.dp)
                                        .clip(CircleShape)
                                        .background(
                                            when (rank) {
                                                1 -> AccentOrange.copy(alpha = 0.2f)
                                                2 -> Color.Gray.copy(alpha = 0.2f)
                                                3 -> Color(0xFFCD7F32).copy(alpha = 0.2f)
                                                else -> MaterialTheme.colorScheme.surfaceVariant
                                            }
                                        ),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = when (rank) {
                                            1 -> "🥇"
                                            2 -> "🥈"
                                            3 -> "🥉"
                                            else -> "$rank"
                                        },
                                        fontSize = if (rank <= 3) 16.sp else 13.sp,
                                        fontWeight = FontWeight.Bold
                                    )
                                }

                                // Speler Avatar
                                Box(
                                    modifier = Modifier
                                        .size(36.dp)
                                        .clip(CircleShape)
                                        .background(playerColor),
                                    contentAlignment = Alignment.Center
                                ) {
                                    if (profile.avatarEmoji != null) {
                                        Text(profile.avatarEmoji, fontSize = 18.sp)
                                    } else {
                                        Text(
                                            name.take(1).uppercase(),
                                            color = Color.White,
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 15.sp
                                        )
                                    }
                                }

                                Column {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text(name, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                                        if (isFiftyFifty && autoFilledIndex == idx) {
                                            Spacer(modifier = Modifier.width(6.dp))
                                            Surface(shape = RoundedCornerShape(4.dp), color = AccentOrange.copy(alpha = 0.2f)) {
                                                Text("✨ Aangevuld", color = AccentOrange, fontSize = 9.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp))
                                            }
                                        }
                                    }
                                    Text(
                                        text = if (rank == 1) "Leidt de wedstrijd" else "$currentScore $scoreUnit",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = if (rank == 1) AccentOrange else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                    )
                                }
                            }

                            // Stepper voor score
                            NumericScoreStepper(
                                score = currentScore,
                                onScoreChange = { newScore ->
                                    updatePlayerScore(idx, newScore, isManual = true)
                                },
                                enableLargeStep = true
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Button(
                onClick = {
                    val winningIndex = sortedIndices.firstOrNull() ?: 0
                    val winnerName = playerNames.getOrElse(winningIndex) { "" }
                    val playerScores = playerNames.indices.map { idx ->
                        PlayerScore(
                            playerName = playerNames[idx],
                            score = scores.getOrElse(idx) { 0 },
                            isWinner = idx == winningIndex
                        )
                    }

                    scoreManager.saveGame(
                        gameName = gameName,
                        winner = winnerName,
                        playerScores = playerScores
                    )

                    isGameOver = true
                },
                enabled = isFiftyFiftyValid,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isFiftyFiftyValid) PrimaryBlue else Color.Gray.copy(alpha = 0.5f)
                )
            ) {
                if (isFiftyFifty && !isFiftyFiftyValid) {
                    Icon(Icons.Default.Info, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        if (fiftyFiftyTotal < 100) "Totaal moet 100 zijn (nu: $fiftyFiftyTotal, nog ${100 - fiftyFiftyTotal} open)"
                        else "Totaal moet 100 zijn (nu: $fiftyFiftyTotal, ${fiftyFiftyTotal - 100} te veel)",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold
                    )
                } else {
                    Icon(Icons.Default.CheckCircle, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Uitslag Opslaan & Naar Podium", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}
