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
                                    Text(name, fontWeight = FontWeight.Bold, fontSize = 16.sp)
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
                                    val list = scores.toMutableList()
                                    if (idx < list.size) {
                                        list[idx] = newScore
                                        scores = list
                                    }
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
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(containerColor = PrimaryBlue)
            ) {
                Icon(Icons.Default.CheckCircle, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Uitslag Opslaan & Naar Podium", fontSize = 16.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}
