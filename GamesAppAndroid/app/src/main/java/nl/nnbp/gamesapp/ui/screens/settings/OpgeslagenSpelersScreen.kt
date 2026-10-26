package nl.nnbp.gamesapp.ui.screens.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
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
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.model.PlayerProfile
import nl.nnbp.gamesapp.data.model.PresetAvatarEmojis
import nl.nnbp.gamesapp.data.model.PresetTableColors
import nl.nnbp.gamesapp.ui.components.SpelerspaspoortDialog
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OpgeslagenSpelersScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val savedPlayers by scoreManager.savedPlayerNames.collectAsState()
    val playerProfiles by scoreManager.playerProfiles.collectAsState()

    var searchQuery by remember { mutableStateOf("") }
    var showAddDialog by remember { mutableStateOf(false) }
    var newPlayerName by remember { mutableStateOf("") }
    var newPlayerColor by remember { mutableStateOf(PresetTableColors[0]) }
    var newPlayerEmoji by remember { mutableStateOf<String?>(null) }
    var playerToDelete by remember { mutableStateOf<String?>(null) }
    var showResetAllDialog by remember { mutableStateOf(false) }
    var activePassportPlayer by remember { mutableStateOf<String?>(null) }

    val filteredPlayers = remember(savedPlayers, searchQuery) {
        if (searchQuery.trim().isEmpty()) {
            savedPlayers
        } else {
            savedPlayers.filter { it.contains(searchQuery.trim(), ignoreCase = true) }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Opgeslagen Spelers", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Terug")
                    }
                },
                actions = {
                    if (savedPlayers.isNotEmpty()) {
                        IconButton(onClick = { showResetAllDialog = true }) {
                            Icon(Icons.Default.Delete, contentDescription = "Alles wissen", tint = MaterialTheme.colorScheme.error)
                        }
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = {
                    newPlayerName = ""
                    newPlayerColor = PresetTableColors[(savedPlayers.size) % PresetTableColors.size]
                    newPlayerEmoji = null
                    showAddDialog = true
                },
                containerColor = PrimaryBlue,
                contentColor = Color.White
            ) {
                Icon(Icons.Default.Add, contentDescription = "Speler toevoegen")
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp)
        ) {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                placeholder = { Text("Zoek speler...") },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )

            if (filteredPlayers.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = if (searchQuery.isEmpty()) "Geen opgeslagen spelers gevonden." else "Geen resultaten voor \"$searchQuery\".",
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 80.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(filteredPlayers) { name ->
                        val playCount = scoreManager.playerPlayCount(name)
                        val profile = playerProfiles[name.trim().lowercase()] ?: PlayerProfile.defaultFor(name)
                        val playerColor = Color(profile.colorHex)

                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { activePassportPlayer = name },
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 14.dp, vertical = 10.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(42.dp)
                                            .clip(CircleShape)
                                            .background(playerColor)
                                            .border(1.5.dp, Color.White.copy(alpha = 0.25f), CircleShape),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        if (profile.avatarEmoji != null) {
                                            Text(profile.avatarEmoji, fontSize = 20.sp)
                                        } else {
                                            Text(
                                                text = name.take(1).uppercase(),
                                                fontWeight = FontWeight.Bold,
                                                color = Color.White,
                                                fontSize = 18.sp
                                            )
                                        }
                                    }
                                    Spacer(modifier = Modifier.width(12.dp))
                                    Column {
                                        Text(name, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                                        Text(
                                            "$playCount potjes • Tik voor paspoort 🪪",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                        )
                                    }
                                }

                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    IconButton(onClick = { activePassportPlayer = name }) {
                                        Icon(
                                            Icons.Default.Info,
                                            contentDescription = "Spelerspaspoort",
                                            tint = PrimaryBlue
                                        )
                                    }
                                    IconButton(onClick = { playerToDelete = name }) {
                                        Icon(
                                            Icons.Default.Delete,
                                            contentDescription = "Verwijderen",
                                            tint = MaterialTheme.colorScheme.error.copy(alpha = 0.7f),
                                            modifier = Modifier.size(20.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (showAddDialog) {
        AlertDialog(
            onDismissRequest = { showAddDialog = false },
            title = { Text("Speler toevoegen", fontWeight = FontWeight.Bold) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedTextField(
                        value = newPlayerName,
                        onValueChange = { newPlayerName = it },
                        label = { Text("Spelernaam") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp)
                    )

                    Text("Kies herkenbare tafelkleur:", fontWeight = FontWeight.Medium, fontSize = 13.sp)
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        items(PresetTableColors) { colHex ->
                            val isSel = colHex == newPlayerColor
                            Box(
                                modifier = Modifier
                                    .size(32.dp)
                                    .clip(CircleShape)
                                    .background(Color(colHex))
                                    .border(if (isSel) 3.dp else 1.dp, if (isSel) Color.White else Color.Transparent, CircleShape)
                                    .clickable { newPlayerColor = colHex },
                                contentAlignment = Alignment.Center
                            ) {
                                if (isSel) {
                                    Icon(Icons.Default.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                                }
                            }
                        }
                    }

                    Text("Avatar emoji (optioneel):", fontWeight = FontWeight.Medium, fontSize = 13.sp)
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        item {
                            Box(
                                modifier = Modifier
                                    .size(34.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(if (newPlayerEmoji == null) PrimaryBlue.copy(alpha = 0.2f) else MaterialTheme.colorScheme.surfaceVariant)
                                    .border(1.dp, if (newPlayerEmoji == null) PrimaryBlue else Color.Transparent, RoundedCornerShape(8.dp))
                                    .clickable { newPlayerEmoji = null },
                                contentAlignment = Alignment.Center
                            ) {
                                Text("✕", fontSize = 13.sp)
                            }
                        }
                        items(PresetAvatarEmojis) { emoji ->
                            val isSel = emoji == newPlayerEmoji
                            Box(
                                modifier = Modifier
                                    .size(34.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(if (isSel) PrimaryBlue.copy(alpha = 0.2f) else MaterialTheme.colorScheme.surfaceVariant)
                                    .border(1.dp, if (isSel) PrimaryBlue else Color.Transparent, RoundedCornerShape(8.dp))
                                    .clickable { newPlayerEmoji = emoji },
                                contentAlignment = Alignment.Center
                            ) {
                                Text(emoji, fontSize = 16.sp)
                            }
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val trimmed = newPlayerName.trim()
                        if (trimmed.isNotEmpty()) {
                            val profile = PlayerProfile(
                                name = trimmed,
                                colorHex = newPlayerColor,
                                avatarEmoji = newPlayerEmoji
                            )
                            scoreManager.savePlayerProfile(profile)
                            newPlayerName = ""
                            showAddDialog = false
                        }
                    }
                ) {
                    Text("Toevoegen")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddDialog = false }) {
                    Text("Annuleren")
                }
            }
        )
    }

    playerToDelete?.let { name ->
        AlertDialog(
            onDismissRequest = { playerToDelete = null },
            title = { Text("Speler verwijderen?") },
            text = { Text("Weet je zeker dat je \"$name\" wilt verwijderen uit je opgeslagen spelers?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        scoreManager.deletePlayer(name)
                        playerToDelete = null
                    }
                ) {
                    Text("Verwijderen", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { playerToDelete = null }) {
                    Text("Annuleren")
                }
            }
        )
    }

    if (showResetAllDialog) {
        AlertDialog(
            onDismissRequest = { showResetAllDialog = false },
            title = { Text("Alle spelers wissen?") },
            text = { Text("Weet je zeker dat je alle opgeslagen spelers wilt wissen? Dit kan niet ongedaan worden gemaakt.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        scoreManager.clearAllPlayers()
                        showResetAllDialog = false
                    }
                ) {
                    Text("Alles Wissen", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showResetAllDialog = false }) {
                    Text("Annuleren")
                }
            }
        )
    }

    activePassportPlayer?.let { playerName ->
        SpelerspaspoortDialog(
            playerName = playerName,
            scoreManager = scoreManager,
            onDismiss = { activePassportPlayer = null }
        )
    }
}
