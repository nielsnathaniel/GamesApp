package nl.nnbp.gamesapp.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
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
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue

@Composable
fun SavedPlayersQuickChips(
    selectedPlayers: List<String>,
    onTogglePlayer: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val savedPlayers by scoreManager.savedPlayerNames.collectAsState()
    val playerProfiles by scoreManager.playerProfiles.collectAsState()
    var showAddDialog by remember { mutableStateOf(false) }
    var newPlayerName by remember { mutableStateOf("") }

    Column(modifier = modifier.fillMaxWidth()) {
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
}
