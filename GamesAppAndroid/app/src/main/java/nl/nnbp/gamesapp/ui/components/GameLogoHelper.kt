package nl.nnbp.gamesapp.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import nl.nnbp.gamesapp.R
import nl.nnbp.gamesapp.data.model.GameType
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue

fun getGameLogoResId(gameType: GameType): Int? {
    return when (gameType) {
        GameType.BALZAKKEN -> R.drawable.game_balzakken
        GameType.BEVERBENDE -> R.drawable.game_beverbende
        GameType.DUIZENDEN -> R.drawable.game_duizenden
        GameType.FIFTY_FIFTY -> R.drawable.game_fiftyfifty
        GameType.JATTEN -> R.drawable.game_jatten
        GameType.LOVE_LETTER -> R.drawable.game_loveletter
        GameType.NMBR9 -> R.drawable.game_nmbr9
        GameType.PIG_HOLE -> R.drawable.game_pighole
        GameType.QUICKSTOP -> R.drawable.game_quickstop
        GameType.QWIXX -> R.drawable.game_qwixx
        GameType.REGENWORMEN -> R.drawable.game_regenwormen
        GameType.TICKET_TO_RIDE -> R.drawable.game_tickettoride
        else -> null
    }
}

fun getGameLogoResIdByName(name: String): Int? {
    val norm = name.trim().lowercase().replace(" ", "")
    return when {
        norm.contains("balzak") -> R.drawable.game_balzakken
        norm.contains("bever") -> R.drawable.game_beverbende
        norm.contains("duizend") -> R.drawable.game_duizenden
        norm.contains("fifty") -> R.drawable.game_fiftyfifty
        norm.contains("jat") -> R.drawable.game_jatten
        norm.contains("love") -> R.drawable.game_loveletter
        norm.contains("nmbr") -> R.drawable.game_nmbr9
        norm.contains("pighole") || norm.contains("varken") -> R.drawable.game_pighole
        norm.contains("quick") -> R.drawable.game_quickstop
        norm.contains("qwixx") -> R.drawable.game_qwixx
        norm.contains("regenworm") || norm.contains("worm") -> R.drawable.game_regenwormen
        norm.contains("ticket") || norm.contains("trein") -> R.drawable.game_tickettoride
        else -> null
    }
}

@Composable
fun GameLogoImage(
    gameType: GameType,
    modifier: Modifier = Modifier,
    size: Dp = 56.dp,
    cornerRadius: Dp = 14.dp
) {
    val resId = getGameLogoResId(gameType)
    if (resId != null) {
        Image(
            painter = painterResource(id = resId),
            contentDescription = gameType.displayName,
            contentScale = ContentScale.Crop,
            modifier = modifier
                .size(size)
                .clip(RoundedCornerShape(cornerRadius))
        )
    } else {
        Box(
            modifier = modifier
                .size(size)
                .clip(RoundedCornerShape(cornerRadius))
                .background(PrimaryBlue.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = when (gameType) {
                    GameType.THIRTY_SECONDS -> Icons.Default.Timer
                    GameType.CRANIUM -> Icons.Default.Psychology
                    GameType.CROCKINOLE -> Icons.Default.RadioButtonChecked
                    else -> Icons.Default.Casino
                },
                contentDescription = gameType.displayName,
                tint = PrimaryBlue,
                modifier = Modifier.size(size * 0.55f)
            )
        }
    }
}

@Composable
fun GameLogoImageByName(
    gameName: String,
    modifier: Modifier = Modifier,
    size: Dp = 44.dp,
    cornerRadius: Dp = 10.dp
) {
    val resId = getGameLogoResIdByName(gameName)
    if (resId != null) {
        Image(
            painter = painterResource(id = resId),
            contentDescription = gameName,
            contentScale = ContentScale.Crop,
            modifier = modifier
                .size(size)
                .clip(RoundedCornerShape(cornerRadius))
        )
    } else {
        Box(
            modifier = modifier
                .size(size)
                .clip(RoundedCornerShape(cornerRadius))
                .background(PrimaryBlue.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = when {
                    gameName.contains("30", ignoreCase = true) -> Icons.Default.Timer
                    gameName.contains("cranium", ignoreCase = true) -> Icons.Default.Psychology
                    gameName.contains("crok", ignoreCase = true) -> Icons.Default.RadioButtonChecked
                    else -> Icons.Default.Casino
                },
                contentDescription = gameName,
                tint = PrimaryBlue,
                modifier = Modifier.size(size * 0.55f)
            )
        }
    }
}
