package nl.nnbp.gamesapp.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue

@Composable
fun SavedPlayersQuickChips(
    selectedPlayers: List<String>,
    onTogglePlayer: (String) -> Unit,
    onApplyTafelschikking: ((List<String>) -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val savedPlayers by scoreManager.savedPlayerNames.collectAsState()
    val playerProfiles by scoreManager.playerProfiles.collectAsState()
    val savedTafelschikking by scoreManager.savedTafelschikking.collectAsState()

    var showAddDialog by remember { mutableStateOf(false) }
    var newPlayerName by remember { mutableStateOf("") }
    var showTafelschikkingDialog by remember { mutableStateOf(false) }
    var showAppliedBanner by remember { mutableStateOf(false) }

    LaunchedEffect(showAppliedBanner) {
        if (showAppliedBanner) {
            delay(2500)
            showAppliedBanner = false
        }
    }

    Column(modifier = modifier.fillMaxWidth()) {
        // Tafelschikking optie
        if (savedTafelschikking.size >= 2) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = {
                        if (onApplyTafelschikking != null) {
                            onApplyTafelschikking(savedTafelschikking)
                        } else {
                            savedTafelschikking.forEach { name ->
                                if (!selectedPlayers.any { it.equals(name, ignoreCase = true) }) {
                                    onTogglePlayer(name)
                                }
                            }
                        }
                        showAppliedBanner = true
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF10B981)),
                    shape = RoundedCornerShape(20.dp),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp),
                    modifier = Modifier.height(36.dp)
                ) {
                    Icon(Icons.Default.People, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "🪑 Tafelschikking overnemen (${savedTafelschikking.size})",
                        style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                        color = Color.White
                    )
                }

                OutlinedButton(
                    onClick = { showTafelschikkingDialog = true },
                    shape = RoundedCornerShape(20.dp),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp),
                    modifier = Modifier.height(36.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color.White.copy(alpha = 0.25f))
                ) {
                    Icon(Icons.Default.Edit, contentDescription = null, modifier = Modifier.size(14.dp), tint = Color.White)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Bekijk tafel", style = MaterialTheme.typography.labelSmall, color = Color.White)
                }
            }
        } else {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                AssistChip(
                    onClick = { showTafelschikkingDialog = true },
                    label = { Text("🪑 Stel tafelschikking in", fontSize = 11.sp) },
                    leadingIcon = {
                        Icon(Icons.Default.People, contentDescription = null, modifier = Modifier.size(14.dp))
                    },
                    shape = RoundedCornerShape(16.dp)
                )
            }
        }

        AnimatedVisibility(
            visible = showAppliedBanner,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                color = Color(0xFF10B981).copy(alpha = 0.18f),
                shape = RoundedCornerShape(8.dp)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Default.Check, contentDescription = null, tint = Color(0xFF10B981), modifier = Modifier.size(14.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        "Tafelschikking toegepast (${savedTafelschikking.take(4).joinToString(", ")}${if (savedTafelschikking.size > 4) "..." else ""})",
                        color = Color(0xFF10B981),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = "Snelle Spelerkeuze",
                style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold),
                color = MaterialTheme.colorScheme.onBackground
            )
            TextButton(
                onClick = { showAddDialog = true },
                contentPadding = PaddingValues(horizontal = 8.dp, vertical = 0.dp)
            ) {
                Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text("Nieuw", style = MaterialTheme.typography.labelMedium)
            }
        }

        if (savedPlayers.isEmpty()) {
            Text(
                text = "Nog geen opgeslagen spelers. Voeg spelers toe om ze hier snel te kiezen.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f),
                modifier = Modifier.padding(vertical = 4.dp)
            )
        } else {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                savedPlayers.forEach { name ->
                    val isSelected = selectedPlayers.any { it.equals(name, ignoreCase = true) }
                    val profile = playerProfiles[name.trim().lowercase()] ?: nl.nnbp.gamesapp.data.model.PlayerProfile.defaultFor(name)
                    val playerColor = Color(profile.colorHex)

                    FilterChip(
                        selected = isSelected,
                        onClick = { onTogglePlayer(name) },
                        label = {
                            Text(
                                text = name,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                            )
                        },
                        leadingIcon = {
                            Box(
                                modifier = Modifier
                                    .size(22.dp)
                                    .clip(CircleShape)
                                    .background(if (isSelected) PrimaryBlue else playerColor),
                                contentAlignment = Alignment.Center
                            ) {
                                if (isSelected) {
                                    Icon(
                                        imageVector = Icons.Default.Check,
                                        contentDescription = null,
                                        tint = Color.White,
                                        modifier = Modifier.size(12.dp)
                                    )
                                } else if (profile.avatarEmoji != null) {
                                    Text(
                                        text = profile.avatarEmoji,
                                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp)
                                    )
                                } else {
                                    Text(
                                        text = name.take(1).uppercase(),
                                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp, fontWeight = FontWeight.Bold),
                                        color = Color.White
                                    )
                                }
                            }
                        },
                        shape = RoundedCornerShape(20.dp)
                    )
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
            title = { Text("Nieuwe Speler Toevoegen") },
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
                            onTogglePlayer(trimmed)
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

    if (showTafelschikkingDialog) {
        TafelschikkingDialog(
            players = emptyList(),
            onDismiss = { showTafelschikkingDialog = false },
            onApplyOrder = { ordered ->
                val names = ordered.map { it.name }
                if (onApplyTafelschikking != null) {
                    onApplyTafelschikking(names)
                } else {
                    names.forEach { name ->
                        if (!selectedPlayers.any { it.equals(name, ignoreCase = true) }) {
                            onTogglePlayer(name)
                        }
                    }
                }
                showAppliedBanner = true
                showTafelschikkingDialog = false
            }
        )
    }
}
