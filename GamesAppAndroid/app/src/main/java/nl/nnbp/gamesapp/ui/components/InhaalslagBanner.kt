package nl.nnbp.gamesapp.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SuccessGreen
import kotlin.math.abs

@Composable
fun InhaalslagBanner(
    playerNames: List<String>,
    scores: List<Int>,
    lowestWins: Boolean = false,
    modifier: Modifier = Modifier
) {
    if (playerNames.size < 2 || scores.size != playerNames.size) return

    val ranking = remember(playerNames, scores, lowestWins) {
        val list = playerNames.indices.map { i ->
            Pair(playerNames[i], scores[i])
        }
        if (lowestWins) {
            list.sortedBy { it.second }
        } else {
            list.sortedByDescending { it.second }
        }
    }

    val first = ranking[0]
    val second = ranking[1]
    val diff = abs(first.second - second.second)

    // Alleen tonen als er daadwerkelijk al punten zijn gescoord
    val hasNonZero = scores.any { it != 0 }
    if (!hasNonZero) return

    val (emoji, text, highlightColor) = remember(first, second, diff, lowestWins) {
        when {
            diff == 0 -> {
                Triple(
                    "⚖️",
                    "Gelijke stand aan kop: ${first.first} en ${second.first} delen de 1e plek met ${first.second} pt!",
                    PrimaryBlue
                )
            }
            diff in 1..4 -> {
                Triple(
                    "🔥",
                    "Spannende nek-aan-nek race! ${first.first} leidt met slechts $diff pt voorsprong op ${second.first}.",
                    AccentOrange
                )
            }
            lowestWins -> {
                Triple(
                    "🏆",
                    "${first.first} staat virtueel 1e met ${first.second} strafpunten (${diff} pt voor op ${second.first}).",
                    SuccessGreen
                )
            }
            else -> {
                Triple(
                    "🏆",
                    "${first.first} aan de leiding met ${first.second} pt (+${diff} pt op ${second.first})!",
                    SuccessGreen
                )
            }
        }
    }

    AnimatedVisibility(
        visible = true,
        enter = fadeIn(),
        exit = fadeOut()
    ) {
        Row(
            modifier = modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(highlightColor.copy(alpha = 0.12f))
                .border(1.dp, highlightColor.copy(alpha = 0.3f), RoundedCornerShape(12.dp))
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(emoji, fontSize = 16.sp)
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = text,
                style = MaterialTheme.typography.bodySmall.copy(
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White
                ),
                lineHeight = 16.sp
            )
        }
    }
}
