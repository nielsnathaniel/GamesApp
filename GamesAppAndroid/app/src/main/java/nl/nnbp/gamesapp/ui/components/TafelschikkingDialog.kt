package nl.nnbp.gamesapp.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import kotlinx.coroutines.delay
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.model.Player
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.CardBackground
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SurfaceDark

@Composable
fun TafelschikkingDialog(
    players: List<Player> = emptyList(),
    onDismiss: () -> Unit,
    onApplyOrder: (List<Player>) -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val savedPlayerNames by scoreManager.savedPlayerNames.collectAsState()
    val playerProfiles by scoreManager.playerProfiles.collectAsState()

    var orderedPlayers by remember(players) {
        val initial = if (players.isNotEmpty()) {
            players
        } else {
            val savedTafel = scoreManager.getSavedTafelschikking()
            if (savedTafel.isNotEmpty()) {
                savedTafel.map { name ->
                    val prof = scoreManager.getPlayerProfile(name)
                    Player(name = name, colorHex = prof.colorHex, avatarEmoji = prof.avatarEmoji)
                }
            } else {
                scoreManager.savedPlayerNames.value.take(6).map { name ->
                    val prof = scoreManager.getPlayerProfile(name)
                    Player(name = name, colorHex = prof.colorHex, avatarEmoji = prof.avatarEmoji)
                }
            }
        }
        mutableStateOf(initial)
    }

    var showSaveToast by remember { mutableStateOf(false) }
    var showAddDialog by remember { mutableStateOf(false) }
    var newPlayerName by remember { mutableStateOf("") }

    LaunchedEffect(showSaveToast) {
        if (showSaveToast) {
            delay(2500)
            showSaveToast = false
        }
    }

    fun persistTafelschikking(notify: Boolean = false) {
        scoreManager.saveTafelschikking(orderedPlayers.map { it.name })
        if (notify) {
            showSaveToast = true
        }
    }

    fun togglePlayerAtTable(name: String) {
        val existingIndex = orderedPlayers.indexOfFirst { it.name.equals(name, ignoreCase = true) }
        val mutable = orderedPlayers.toMutableList()
        if (existingIndex >= 0) {
            mutable.removeAt(existingIndex)
        } else {
            val prof = scoreManager.getPlayerProfile(name)
            mutable.add(Player(name = name, colorHex = prof.colorHex, avatarEmoji = prof.avatarEmoji))
        }
        orderedPlayers = mutable
        persistTafelschikking(notify = false)
    }

    Dialog(onDismissRequest = {
        persistTafelschikking(notify = false)
        onDismiss()
    }) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = SurfaceDark)
        ) {
            Column(
                modifier = Modifier
                    .padding(18.dp)
                    .fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Tafelschikking",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        Text(
                            text = "Wie zit waar aan tafel? (${orderedPlayers.size} spelers)",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.White.copy(alpha = 0.6f)
                        )
                    }

                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        FilledTonalButton(
                            onClick = { persistTafelschikking(notify = true) },
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 2.dp),
                            shape = RoundedCornerShape(12.dp),
                            colors = ButtonDefaults.filledTonalButtonColors(
                                containerColor = if (showSaveToast) Color(0xFF10B981) else Color.White.copy(alpha = 0.15f),
                                contentColor = Color.White
                            )
                        ) {
                            Icon(
                                if (showSaveToast) Icons.Default.Check else Icons.Default.Done,
                                contentDescription = null,
                                modifier = Modifier.size(14.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(if (showSaveToast) "Opgeslagen" else "Opslaan", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        }

                        IconButton(onClick = {
                            persistTafelschikking(notify = false)
                            onDismiss()
                        }) {
                            Icon(Icons.Default.Close, contentDescription = "Sluiten", tint = Color.White)
                        }
                    }
                }

                AnimatedVisibility(
                    visible = showSaveToast,
                    enter = fadeIn(),
                    exit = fadeOut()
                ) {
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 6.dp),
                        color = Color(0xFF10B981).copy(alpha = 0.2f),
                        shape = RoundedCornerShape(10.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF10B981).copy(alpha = 0.4f))
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF10B981), modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                "Tafelschikking opgeslagen! Beschikbaar in alle spellen.",
                                color = Color.White,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Snelle spelerskeuze (chips) om spelers aan tafel toe te voegen / verwijderen
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState())
                        .padding(vertical = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Knop om direct een nieuwe speler toe te voegen
                    AssistChip(
                        onClick = { showAddDialog = true },
                        label = { Text("+ Speler", fontSize = 11.sp, fontWeight = FontWeight.Bold) },
                        colors = AssistChipDefaults.assistChipColors(
                            containerColor = Color.White.copy(alpha = 0.12f),
                            labelColor = Color.White
                        ),
                        shape = RoundedCornerShape(16.dp)
                    )

                    savedPlayerNames.forEach { name ->
                        val isSeated = orderedPlayers.any { it.name.equals(name, ignoreCase = true) }
                        FilterChip(
                            selected = isSeated,
                            onClick = { togglePlayerAtTable(name) },
                            label = { Text(name, fontSize = 11.sp, fontWeight = if (isSeated) FontWeight.Bold else FontWeight.Normal) },
                            leadingIcon = if (isSeated) {
                                {
                                    Icon(
                                        imageVector = Icons.Default.Check,
                                        contentDescription = null,
                                        tint = Color.White,
                                        modifier = Modifier.size(12.dp)
                                    )
                                }
                            } else null,
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = Color(0xFF10B981).copy(alpha = 0.4f),
                                selectedLabelColor = Color.White,
                                containerColor = Color.White.copy(alpha = 0.08f),
                                labelColor = Color.White.copy(alpha = 0.8f)
                            ),
                            shape = RoundedCornerShape(16.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Ronde tafel visualisatie
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(95.dp)
                        .clip(RoundedCornerShape(18.dp))
                        .background(CardBackground)
                        .padding(10.dp),
                    contentAlignment = Alignment.Center
                ) {
                    // Ronde tafel midden
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(0.75f)
                            .height(48.dp)
                            .clip(RoundedCornerShape(26.dp))
                            .background(Color(0xFF2C2C2E))
                            .border(1.dp, Color.White.copy(alpha = 0.15f), RoundedCornerShape(26.dp)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "🎲 Speeltafel (${orderedPlayers.size} stoelen)",
                            color = Color.White.copy(alpha = 0.8f),
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 12.sp
                        )
                    }

                    // Kloksgewijze beurt indicator banner
                    Row(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .offset(y = 2.dp)
                            .background(PrimaryBlue.copy(alpha = 0.18f), RoundedCornerShape(10.dp))
                            .padding(horizontal = 8.dp, vertical = 2.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.Refresh,
                            contentDescription = null,
                            tint = PrimaryBlue,
                            modifier = Modifier.size(11.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            "Met de klok mee (stoelvolgorde)",
                            color = PrimaryBlue,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Snelle rotatieknoppen
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = {
                            if (orderedPlayers.isNotEmpty()) {
                                val first = orderedPlayers.first()
                                orderedPlayers = orderedPlayers.drop(1) + first
                                persistTafelschikking(notify = false)
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White)
                    ) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null, modifier = Modifier.size(15.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Draai ↺", fontSize = 11.sp)
                    }

                    OutlinedButton(
                        onClick = {
                            if (orderedPlayers.isNotEmpty()) {
                                orderedPlayers = orderedPlayers.shuffled()
                                persistTafelschikking(notify = false)
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White)
                    ) {
                        Icon(Icons.Default.Shuffle, contentDescription = null, modifier = Modifier.size(15.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Hussel", fontSize = 11.sp)
                    }

                    OutlinedButton(
                        onClick = {
                            if (orderedPlayers.isNotEmpty()) {
                                val last = orderedPlayers.last()
                                orderedPlayers = listOf(last) + orderedPlayers.dropLast(1)
                                persistTafelschikking(notify = false)
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White)
                    ) {
                        Text("Draai ↻", fontSize = 11.sp)
                        Spacer(modifier = Modifier.width(4.dp))
                        Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, modifier = Modifier.size(15.dp))
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Lijst met spelers om positie handmatig omhoog/omlaag te verplaatsen
                LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 220.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    itemsIndexed(orderedPlayers) { index, player ->
                        val isStarter = index == 0
                        val playerColor = Color(player.colorHex)

                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .background(if (isStarter) PrimaryBlue.copy(alpha = 0.15f) else CardBackground)
                                .border(
                                    width = if (isStarter) 1.5.dp else 1.dp,
                                    color = if (isStarter) PrimaryBlue else Color.White.copy(alpha = 0.08f),
                                    shape = RoundedCornerShape(12.dp)
                                )
                                .padding(horizontal = 10.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(26.dp)
                                    .clip(CircleShape)
                                    .background(playerColor),
                                contentAlignment = Alignment.Center
                            ) {
                                if (player.avatarEmoji != null) {
                                    Text(player.avatarEmoji, fontSize = 13.sp)
                                } else {
                                    Text(
                                        "${index + 1}",
                                        color = Color.White,
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 12.sp
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
                                        fontSize = 14.sp
                                    )
                                    if (isStarter) {
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Surface(
                                            color = PrimaryBlue,
                                            shape = RoundedCornerShape(5.dp)
                                        ) {
                                            Text(
                                                "1e Stoel",
                                                color = Color.White,
                                                fontSize = 9.sp,
                                                fontWeight = FontWeight.Bold,
                                                modifier = Modifier.padding(horizontal = 5.dp, vertical = 1.dp)
                                            )
                                        }
                                    }
                                }
                                Text(
                                    text = "Stoel ${index + 1}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Color.White.copy(alpha = 0.5f),
                                    fontSize = 10.sp
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
                                        persistTafelschikking(notify = false)
                                    }
                                },
                                enabled = index > 0,
                                modifier = Modifier.size(28.dp)
                            ) {
                                Icon(
                                    Icons.Default.KeyboardArrowUp,
                                    contentDescription = "Omhoog",
                                    tint = if (index > 0) Color.White else Color.White.copy(alpha = 0.2f),
                                    modifier = Modifier.size(18.dp)
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
                                        persistTafelschikking(notify = false)
                                    }
                                },
                                enabled = index < orderedPlayers.size - 1,
                                modifier = Modifier.size(28.dp)
                            ) {
                                Icon(
                                    Icons.Default.KeyboardArrowDown,
                                    contentDescription = "Omlaag",
                                    tint = if (index < orderedPlayers.size - 1) Color.White else Color.White.copy(alpha = 0.2f),
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                Button(
                    onClick = {
                        persistTafelschikking(notify = false)
                        onApplyOrder(orderedPlayers)
                        onDismiss()
                    },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = PrimaryBlue)
                ) {
                    Icon(Icons.Default.Check, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Tafelschikking Toepassen (${orderedPlayers.size} spelers)", fontWeight = FontWeight.Bold)
                }
            }
        }
    }

    if (showAddDialog) {
        AlertDialog(
            onDismissRequest = {
                showAddDialog = false
                newPlayerName = ""
            },
            title = { Text("Nieuwe Speler Aan Tafel") },
            text = {
                OutlinedTextField(
                    value = newPlayerName,
                    onValueChange = { newPlayerName = it },
                    label = { Text("Naam van speler") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        val trimmed = newPlayerName.trim()
                        if (trimmed.isNotEmpty()) {
                            scoreManager.savePlayerName(trimmed)
                            togglePlayerAtTable(trimmed)
                            newPlayerName = ""
                            showAddDialog = false
                        }
                    }
                ) {
                    Text("Toevoegen")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddDialog = false; newPlayerName = "" }) {
                    Text("Annuleren")
                }
            }
        )
    }
}
