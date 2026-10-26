package nl.nnbp.gamesapp.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Casino
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue

@Composable
fun StartspelerKiezerDialog(
    players: List<String>,
    onDismiss: () -> Unit,
    onStartspelerChosen: (String) -> Unit
) {
    var isRolling by remember { mutableStateOf(false) }
    var selectedPlayer by remember { mutableStateOf<String?>(null) }
    var rotationAngle by remember { mutableStateOf(0f) }

    val animatedRotation by animateFloatAsState(
        targetValue = rotationAngle,
        animationSpec = tween(durationMillis = 600),
        label = "dice_rotation"
    )

    LaunchedEffect(isRolling) {
        if (isRolling) {
            rotationAngle += 720f
            for (i in 0..12) {
                selectedPlayer = players.random()
                delay(60)
            }
            isRolling = false
            selectedPlayer?.let { onStartspelerChosen(it) }
        }
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Casino,
                    contentDescription = null,
                    tint = PrimaryBlue,
                    modifier = Modifier.rotate(animatedRotation)
                )
                Text("Wie mag beginnen?")
            }
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 12.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                if (selectedPlayer != null) {
                    Box(
                        modifier = Modifier
                            .size(72.dp)
                            .clip(CircleShape)
                            .background(PrimaryBlue.copy(alpha = 0.15f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = selectedPlayer?.take(1)?.uppercase() ?: "",
                            style = MaterialTheme.typography.headlineMedium.copy(color = PrimaryBlue)
                        )
                    }
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = selectedPlayer ?: "",
                        style = MaterialTheme.typography.titleLarge.copy(
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold,
                            color = PrimaryBlue
                        )
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "mag de eerste beurt spelen! 🎲",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                } else {
                    Text(
                        text = "Laat het lot bepalen welke speler de eerste worp of beurt mag nemen.",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (players.isNotEmpty()) {
                        isRolling = true
                    }
                },
                enabled = !isRolling && players.isNotEmpty()
            ) {
                Text(if (selectedPlayer == null) "Gooi dobbelsteen" else "Opnieuw gooien")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Klaar")
            }
        }
    )
}
