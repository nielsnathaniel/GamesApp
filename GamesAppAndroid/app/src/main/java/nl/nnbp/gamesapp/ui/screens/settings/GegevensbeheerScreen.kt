package nl.nnbp.gamesapp.ui.screens.settings

import android.net.Uri
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import nl.nnbp.gamesapp.data.DataBackupManager
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.ui.components.AppCard
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GegevensbeheerScreen(
    onNavigateBack: () -> Unit,
    onNavigateToPlayers: () -> Unit,
    onNavigateToSessions: () -> Unit
) {
    val context = LocalContext.current
    val scoreManager = remember { ScoreManager.getInstance(context) }

    val players by scoreManager.savedPlayerNames.collectAsState()
    val games by scoreManager.playedGames.collectAsState()
    val scores by scoreManager.scores.collectAsState()

    var pendingImportUri by remember { mutableStateOf<Uri?>(null) }
    var showMergeDialog by remember { mutableStateOf(false) }
    var showStatusAlert by remember { mutableStateOf(false) }
    var statusAlertMessage by remember { mutableStateOf("") }

    var showClearHistoryDialog by remember { mutableStateOf(false) }
    var showClearPlayersDialog by remember { mutableStateOf(false) }

    // Launcher voor het opslaan van een JSON backup bestand
    val saveDocumentLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CreateDocument("application/json")
    ) { uri: Uri? ->
        uri?.let {
            val result = DataBackupManager.writeBackupToUri(context, it)
            result.onSuccess { msg ->
                statusAlertMessage = msg
                showStatusAlert = true
            }.onFailure { err ->
                statusAlertMessage = "Opslaan mislukt: ${err.localizedMessage}"
                showStatusAlert = true
            }
        }
    }

    // Launcher voor het importeren van een JSON backup bestand
    val openDocumentLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenDocument()
    ) { uri: Uri? ->
        uri?.let {
            pendingImportUri = it
            showMergeDialog = true
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Gegevensbeheer", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Terug")
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Samenvatting Header Cards
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Spelers card
                    Card(
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(containerColor = PrimaryBlue.copy(alpha = 0.12f))
                    ) {
                        Column(modifier = Modifier.padding(14.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.People, contentDescription = null, tint = PrimaryBlue, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Spelers", style = MaterialTheme.typography.bodySmall, color = PrimaryBlue)
                            }
                            Spacer(modifier = Modifier.height(4.dp))
                            Text("${players.size}", style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold))
                        }
                    }

                    // Sessies card
                    Card(
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(containerColor = AccentOrange.copy(alpha = 0.12f))
                    ) {
                        Column(modifier = Modifier.padding(14.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.History, contentDescription = null, tint = AccentOrange, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Sessies", style = MaterialTheme.typography.bodySmall, color = AccentOrange)
                            }
                            Spacer(modifier = Modifier.height(4.dp))
                            Text("${games.size}", style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold))
                        }
                    }

                    // Scores card
                    Card(
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                    ) {
                        Column(modifier = Modifier.padding(14.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.Leaderboard, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Scores", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                            Spacer(modifier = Modifier.height(4.dp))
                            Text("${scores.size}", style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold))
                        }
                    }
                }
            }

            // Back-up & Synchronisatie (JSON)
            item {
                SectionTitle(title = "Back-up & Synchronisatie (JSON)")
                AppCard {
                    Text(
                        text = "Exporteer of importeer al je spelgeschiedenis en spelers via een JSON-bestand. Dit formaat is 100% uitwisselbaar met de iOS-versie van GamesApp!",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )

                    Spacer(modifier = Modifier.height(14.dp))

                    // Export knoppen
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Button(
                            onClick = {
                                val result = DataBackupManager.createShareIntent(context)
                                result.onSuccess { intent ->
                                    context.startActivity(intent)
                                }.onFailure { err ->
                                    Toast.makeText(context, "Fout bij delen: ${err.localizedMessage}", Toast.LENGTH_SHORT).show()
                                }
                            },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Deel Back-up", fontSize = 13.sp)
                        }

                        OutlinedButton(
                            onClick = {
                                saveDocumentLauncher.launch(DataBackupManager.generateBackupFileName())
                            },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Icon(Icons.Default.SaveAlt, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Opslaan", fontSize = 13.sp)
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))
                    HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))
                    Spacer(modifier = Modifier.height(10.dp))

                    // Import knop
                    FilledTonalButton(
                        onClick = {
                            openDocumentLauncher.launch(arrayOf("application/json", "text/*", "*/*"))
                        },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.filledTonalButtonColors(containerColor = AccentOrange.copy(alpha = 0.15f))
                    ) {
                        Icon(Icons.Default.FileOpen, contentDescription = null, tint = AccentOrange, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("JSON Back-up Importeren...", color = AccentOrange, fontWeight = FontWeight.Bold)
                    }
                }
            }

            // Beheer Schermen Links
            item {
                SectionTitle(title = "Beheer")
                AppCard {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable(onClick = onNavigateToPlayers)
                            .padding(vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(36.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(PrimaryBlue.copy(alpha = 0.15f)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Default.People, contentDescription = null, tint = PrimaryBlue, modifier = Modifier.size(20.dp))
                            }
                            Spacer(modifier = Modifier.width(14.dp))
                            Column {
                                Text("Opgeslagen Spelers", fontWeight = FontWeight.Bold)
                                Text("Spelers bekijken, kleuren, avatars & namen bewerken", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                            }
                        }
                        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color.Gray)
                    }

                    HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable(onClick = onNavigateToSessions)
                            .padding(vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(36.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(AccentOrange.copy(alpha = 0.15f)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Default.History, contentDescription = null, tint = AccentOrange, modifier = Modifier.size(20.dp))
                            }
                            Spacer(modifier = Modifier.width(14.dp))
                            Column {
                                Text("Opgeslagen Spelsessies", fontWeight = FontWeight.Bold)
                                Text("Geschiedenis per dag bekijken of potjes wissen", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                            }
                        }
                        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color.Gray)
                    }
                }
            }

            // Volledige Reset
            item {
                SectionTitle(title = "Volledige Reset")
                AppCard {
                    Text(
                        text = "Let op: Deze acties kunnen niet ongedaan worden gemaakt.",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.Gray
                    )
                    Spacer(modifier = Modifier.height(10.dp))

                    TextButton(
                        onClick = { showClearHistoryDialog = true },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)
                    ) {
                        Icon(Icons.Default.DeleteSweep, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Alle spelgeschiedenis & scores wissen")
                    }

                    TextButton(
                        onClick = { showClearPlayersDialog = true },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)
                    ) {
                        Icon(Icons.Default.PersonRemove, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Alle opgeslagen spelers wissen")
                    }
                }
            }
        }
    }

    // Dialoog: Hoe wil je importeren? (Samenvoegen vs Overschrijven)
    if (showMergeDialog && pendingImportUri != null) {
        val uri = pendingImportUri!!
        AlertDialog(
            onDismissRequest = { showMergeDialog = false },
            title = { Text("Hoe wil je de back-up importeren?") },
            text = {
                Text("Kies 'Samenvoegen' om nieuwe potjes en spelers toe te voegen zonder je huidige data kwijt te raken, of 'Alles overschrijven' om je huidige data volledig te vervangen door de back-up.")
            },
            confirmButton = {
                Button(
                    onClick = {
                        val result = DataBackupManager.importBackupFromUri(context, uri, merge = true)
                        showMergeDialog = false
                        pendingImportUri = null
                        result.onSuccess {
                            statusAlertMessage = it
                            showStatusAlert = true
                        }.onFailure {
                            statusAlertMessage = "Importeren mislukt: ${it.localizedMessage}"
                            showStatusAlert = true
                        }
                    }
                ) {
                    Text("Samenvoegen")
                }
            },
            dismissButton = {
                Row {
                    TextButton(
                        onClick = {
                            val result = DataBackupManager.importBackupFromUri(context, uri, merge = false)
                            showMergeDialog = false
                            pendingImportUri = null
                            result.onSuccess {
                                statusAlertMessage = it
                                showStatusAlert = true
                            }.onFailure {
                                statusAlertMessage = "Importeren mislukt: ${it.localizedMessage}"
                                showStatusAlert = true
                            }
                        }
                    ) {
                        Text("Overschrijven", color = MaterialTheme.colorScheme.error)
                    }
                    TextButton(onClick = { showMergeDialog = false; pendingImportUri = null }) {
                        Text("Annuleren")
                    }
                }
            }
        )
    }

    // Status Alert na import of export
    if (showStatusAlert) {
        AlertDialog(
            onDismissRequest = { showStatusAlert = false },
            title = { Text("Back-up Status") },
            text = { Text(statusAlertMessage) },
            confirmButton = {
                TextButton(onClick = { showStatusAlert = false }) {
                    Text("OK")
                }
            }
        )
    }

    // Bevestigingsdialoog geschiedenis wissen
    if (showClearHistoryDialog) {
        AlertDialog(
            onDismissRequest = { showClearHistoryDialog = false },
            title = { Text("Alle geschiedenis wissen?") },
            text = { Text("Weet je zeker dat je alle gespeelde potjes en statistieken wilt wissen?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        scoreManager.clearHistory()
                        showClearHistoryDialog = false
                        Toast.makeText(context, "Spelgeschiedenis gewist", Toast.LENGTH_SHORT).show()
                    }
                ) {
                    Text("Wissen", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showClearHistoryDialog = false }) {
                    Text("Annuleren")
                }
            }
        )
    }

    // Bevestigingsdialoog spelers wissen
    if (showClearPlayersDialog) {
        AlertDialog(
            onDismissRequest = { showClearPlayersDialog = false },
            title = { Text("Alle spelers wissen?") },
            text = { Text("Weet je zeker dat je alle opgeslagen spelers wilt wissen?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        scoreManager.clearAllPlayers()
                        showClearPlayersDialog = false
                        Toast.makeText(context, "Opgeslagen spelers gewist", Toast.LENGTH_SHORT).show()
                    }
                ) {
                    Text("Wissen", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showClearPlayersDialog = false }) {
                    Text("Annuleren")
                }
            }
        )
    }
}
