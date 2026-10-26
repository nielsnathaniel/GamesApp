package nl.nnbp.gamesapp.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import nl.nnbp.gamesapp.data.model.Player
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.CardBackground
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SurfaceDark

@Composable
fun TafelschikkingDialog(
    players: List<Player>,
    onDismiss: () -> Unit,
    onApplyOrder: (List<Player>) -> Unit
) {
    var orderedPlayers by remember(players) { mutableStateOf(players) }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 16.dp),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = SurfaceDark)
        ) {
            Column(
                modifier = Modifier
                    .padding(20.dp)
                    .fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "Tafelschikking",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        Text(
                            text = "Wie zit waar aan tafel?",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.White.copy(alpha = 0.6f)
                        )
                    }
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Sluiten", tint = Color.White)
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Ronde tafel visualisatie
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(110.dp)
                        .clip(RoundedCornerShape(20.dp))
                        .background(CardBackground)
                        .padding(12.dp),
                    contentAlignment = Alignment.Center
                ) {
                    // Ronde tafel midden
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(0.7f)
                            .height(55.dp)
                            .clip(RoundedCornerShape(30.dp))
                            .background(Color(0xFF2C2C2E))
                            .border(1.dp, Color.White.copy(alpha = 0.15f), RoundedCornerShape(30.dp)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "🎲 Speeltafel",
                            color = Color.White.copy(alpha = 0.7f),
                            fontWeight = FontWeight.Medium,
                            fontSize = 13.sp
                        )
                    }

                    // Kloksgewijze beurt indicator banner
                    Row(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .offset(y = 2.dp)
                            .background(PrimaryBlue.copy(alpha = 0.15f), RoundedCornerShape(12.dp))
                            .padding(horizontal = 8.dp, vertical = 2.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.Refresh,
                            contentDescription = null,
                            tint = PrimaryBlue,
                            modifier = Modifier.size(12.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            "Kloksgewijze beurtenvolgorde",
                            color = PrimaryBlue,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Snelle rotatieknoppen
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = {
                            if (orderedPlayers.isNotEmpty()) {
                                // Tegen de klok in: eerste wordt laatste
                                val first = orderedPlayers.first()
                                orderedPlayers = orderedPlayers.drop(1) + first
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White)
                    ) {
                        Icon(Icons.Default.ArrowBack, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Draai ↺", fontSize = 12.sp)
                    }

                    OutlinedButton(
                        onClick = {
                            if (orderedPlayers.isNotEmpty()) {
                                // Met de klok mee: laatste wordt eerste
                                val last = orderedPlayers.last()
                                orderedPlayers = listOf(last) + orderedPlayers.dropLast(1)
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White)
                    ) {
                        Text("Draai ↻", fontSize = 12.sp)
                        Spacer(modifier = Modifier.width(4.dp))
                        Icon(Icons.Default.ArrowForward, contentDescription = null, modifier = Modifier.size(16.dp))
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Lijst met spelers om positie handmatig omhoog/omlaag te verplaatsen
                LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 240.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    itemsIndexed(orderedPlayers) { index, player ->
                        val isStarter = index == 0
                        val playerColor = Color(player.colorHex)

                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(14.dp))
                                .background(if (isStarter) PrimaryBlue.copy(alpha = 0.15f) else CardBackground)
                                .border(
                                    width = if (isStarter) 1.5.dp else 1.dp,
                                    color = if (isStarter) PrimaryBlue else Color.White.copy(alpha = 0.08f),
                                    shape = RoundedCornerShape(14.dp)
                                )
                                .padding(horizontal = 12.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            // Volgorde index / startspeler kroontje
                            Box(
                                modifier = Modifier
                                    .size(28.dp)
                                    .clip(CircleShape)
                                    .background(playerColor),
                                contentAlignment = Alignment.Center
                            ) {
                                if (player.avatarEmoji != null) {
                                    Text(player.avatarEmoji, fontSize = 14.sp)
                                } else {
                                    Text(
                                        "${index + 1}",
                                        color = Color.White,
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 13.sp
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.width(10.dp))

                            Column(modifier = Modifier.weight(1f)) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        text = player.name,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White,
                                        fontSize = 15.sp
                                    )
                                    if (isStarter) {
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Surface(
                                            color = PrimaryBlue,
                                            shape = RoundedCornerShape(6.dp)
                                        ) {
                                            Text(
                                                "Begint",
                                                color = Color.White,
                                                fontSize = 10.sp,
                                                fontWeight = FontWeight.Bold,
                                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                            )
                                        }
                                    }
                                }
                                Text(
                                    text = if (isStarter) "Startspeler" else "Stoel ${index + 1}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Color.White.copy(alpha = 0.5f),
                                    fontSize = 11.sp
                                )
                            }

                            // Maak startspeler / zet bovenaan
                            IconButton(
                                onClick = {
                                    if (index > 0) {
                                        val mutable = orderedPlayers.toMutableList()
                                        val target = mutable.removeAt(index)
                                        mutable.add(0, target)
                                        orderedPlayers = mutable
                                    }
                                },
                                enabled = index > 0,
                                modifier = Modifier.size(32.dp)
                            ) {
                                Icon(
                                    Icons.Default.VerticalAlignTop,
                                    contentDescription = "Zet bovenaan (Startspeler)",
                                    tint = if (index > 0) AccentOrange else Color.White.copy(alpha = 0.2f),
                                    modifier = Modifier.size(18.dp)
                                )
                            }

                            // Omhoog / Omlaag knoppen
                            IconButton(
                                onClick = {
                                    if (index > 0) {
                                        val mutable = orderedPlayers.toMutableList()
                                        val temp = mutable[index]
                                        mutable[index] = mutable[index - 1]
                                        mutable[index - 1] = temp
                                        orderedPlayers = mutable
                                    }
                                },
                                enabled = index > 0,
                                modifier = Modifier.size(32.dp)
                            ) {
                                Icon(
                                    Icons.Default.KeyboardArrowUp,
                                    contentDescription = "Omhoog",
                                    tint = if (index > 0) Color.White else Color.White.copy(alpha = 0.2f)
                                )
                            }

                            IconButton(
                                onClick = {
                                    if (index < orderedPlayers.size - 1) {
                                        val mutable = orderedPlayers.toMutableList()
                                        val temp = mutable[index]
                                        mutable[index] = mutable[index + 1]
                                        mutable[index + 1] = temp
                                        orderedPlayers = mutable
                                    }
                                },
                                enabled = index < orderedPlayers.size - 1,
                                modifier = Modifier.size(32.dp)
                            ) {
                                Icon(
                                    Icons.Default.KeyboardArrowDown,
                                    contentDescription = "Omlaag",
                                    tint = if (index < orderedPlayers.size - 1) Color.White else Color.White.copy(alpha = 0.2f)
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = {
                        onApplyOrder(orderedPlayers)
                        onDismiss()
                    },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = PrimaryBlue)
                ) {
                    Icon(Icons.Default.Check, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Tafelschikking Toepassen", fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}
