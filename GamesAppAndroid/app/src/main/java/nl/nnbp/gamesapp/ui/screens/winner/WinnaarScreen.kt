package nl.nnbp.gamesapp.ui.screens.winner

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Home
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.model.PlayerScore
import nl.nnbp.gamesapp.ui.audio.SoundManager
import nl.nnbp.gamesapp.ui.components.AppCard
import nl.nnbp.gamesapp.ui.components.ConfettiEffect
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SurfaceDark

@Composable
fun WinnaarScreen(
    gameName: String,
    winnerName: String,
    scores: List<PlayerScore>,
    onFinish: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val soundManager = remember { SoundManager.getInstance() }
    val winnerProfile = remember(winnerName) { scoreManager.getPlayerProfile(winnerName) }
    val winnerColor = Color(winnerProfile.colorHex)

    val sortedScores = scores.sortedByDescending { it.score }

    LaunchedEffect(Unit) {
        soundManager.playFanfare()
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // Feestelijke Confetti Laag op de achtergrond
        ConfettiEffect(
            modifier = Modifier.fillMaxSize(),
            particleCount = 80
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.weight(1f)
            ) {
                Spacer(modifier = Modifier.height(20.dp))

                // Winnaar Beker + Avatar met gouden glans
                Box(
                    modifier = Modifier
                        .size(105.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.sweepGradient(
                                listOf(
                                    Color(0xFFFFD700),
                                    Color(0xFFFFB300),
                                    Color(0xFFFFE082),
                                    Color(0xFFFFD700)
                                )
                            )
                        )
                        .padding(4.dp)
                        .clip(CircleShape)
                        .background(SurfaceDark),
                    contentAlignment = Alignment.Center
                ) {
                    Box(
                        modifier = Modifier
                            .size(86.dp)
                            .clip(CircleShape)
                            .background(winnerColor.copy(alpha = 0.25f)),
                        contentAlignment = Alignment.Center
                    ) {
                        if (winnerProfile.avatarEmoji != null) {
                            Text(winnerProfile.avatarEmoji, fontSize = 42.sp)
                        } else {
                            Icon(
                                imageVector = Icons.Default.EmojiEvents,
                                contentDescription = null,
                                tint = Color(0xFFFFD700),
                                modifier = Modifier.size(50.dp)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                Text(
                    text = "Gefeliciteerd! 🎉",
                    style = MaterialTheme.typography.headlineLarge.copy(
                        fontWeight = FontWeight.ExtraBold,
                        color = Color.White
                    ),
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = "$winnerName pakt de overwinning in $gameName!",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                    color = Color.White.copy(alpha = 0.85f),
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(20.dp))

                // Gouden Podium / Eindstand Kaart
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(
                            width = 1.5.dp,
                            brush = Brush.horizontalGradient(
                                listOf(
                                    Color(0xFFFFD700).copy(alpha = 0.8f),
                                    Color(0xFFFFB300).copy(alpha = 0.4f),
                                    Color(0xFFFFD700).copy(alpha = 0.8f)
                                )
                            ),
                            shape = RoundedCornerShape(20.dp)
                        ),
                    shape = RoundedCornerShape(20.dp),
                    colors = CardDefaults.cardColors(containerColor = SurfaceDark.copy(alpha = 0.95f))
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "🏆 Eindstand",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                color = Color(0xFFFFD700)
                            )
                            Text(
                                text = "$gameName",
                                style = MaterialTheme.typography.labelSmall,
                                color = Color.White.copy(alpha = 0.5f)
                            )
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        sortedScores.forEachIndexed { index, playerScore ->
                            val medal = when (index) {
                                0 -> "🥇"
                                1 -> "🥈"
                                2 -> "🥉"
                                else -> "${index + 1}."
                            }
                            val pProfile = scoreManager.getPlayerProfile(playerScore.playerName)
                            val pColor = Color(pProfile.colorHex)

                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 7.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Text(
                                        text = medal,
                                        style = MaterialTheme.typography.titleMedium,
                                        modifier = Modifier.width(32.dp)
                                    )
                                    Box(
                                        modifier = Modifier
                                            .size(24.dp)
                                            .clip(CircleShape)
                                            .background(pColor),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        if (pProfile.avatarEmoji != null) {
                                            Text(pProfile.avatarEmoji, fontSize = 12.sp)
                                        } else {
                                            Text(
                                                pProfile.name.take(1).uppercase(),
                                                color = Color.White,
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 11.sp
                                            )
                                        }
                                    }
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = playerScore.playerName,
                                        style = MaterialTheme.typography.bodyLarge.copy(
                                            fontWeight = if (index == 0) FontWeight.Bold else FontWeight.Normal,
                                            color = Color.White
                                        )
                                    )
                                }

                                Text(
                                    text = "${playerScore.score} pt",
                                    style = MaterialTheme.typography.titleMedium.copy(
                                        fontWeight = FontWeight.Bold,
                                        color = if (index == 0) Color(0xFFFFD700) else Color.White.copy(alpha = 0.8f)
                                    )
                                )
                            }

                            if (index < sortedScores.size - 1) {
                                HorizontalDivider(color = Color.White.copy(alpha = 0.08f))
                            }
                        }
                    }
                }
            }

            Button(
                onClick = onFinish,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = PrimaryBlue)
            ) {
                Icon(Icons.Default.Home, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Naar Hoofdmenu", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold))
            }
        }
    }
}
