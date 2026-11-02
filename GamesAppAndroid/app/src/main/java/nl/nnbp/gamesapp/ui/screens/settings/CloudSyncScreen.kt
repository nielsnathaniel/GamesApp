package nl.nnbp.gamesapp.ui.screens.settings

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import nl.nnbp.gamesapp.data.CloudSyncManager
import nl.nnbp.gamesapp.ui.components.AppCard
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CloudSyncScreen(
    onNavigateBack: () -> Unit
) {
    val context = LocalContext.current
    val syncManager = remember { CloudSyncManager.getInstance(context) }
    val keyboardController = LocalSoftwareKeyboardController.current

    val syncCode by syncManager.syncCode.collectAsState()
    val isAutoSyncEnabled by syncManager.isAutoSyncEnabled.collectAsState()
    val isSyncing by syncManager.isSyncing.collectAsState()
    val lastSyncDate by syncManager.lastSyncDate.collectAsState()
    val lastSyncSummary by syncManager.lastSyncSummary.collectAsState()
    val databaseUrl by syncManager.databaseUrl.collectAsState()

    var inputCode by remember { mutableStateOf("") }
    var customDbUrl by remember(databaseUrl) { mutableStateOf(databaseUrl) }
    var isAdvancedExpanded by remember { mutableStateOf(false) }
    var showDisconnectDialog by remember { mutableStateOf(false) }
    var showHelpDialog by remember { mutableStateOf(false) }
    var testResultText by remember { mutableStateOf<String?>(null) }
    var isTestingConnection by remember { mutableStateOf(false) }

    val isConnected = syncCode.trim().isNotEmpty()

    val timeFormatter = remember { SimpleDateFormat("HH:mm", Locale.getDefault()) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Cloud Synchronisatie", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Terug")
                    }
                },
                actions = {
                    IconButton(onClick = { showHelpDialog = true }) {
                        Icon(Icons.Default.HelpOutline, contentDescription = "Hulp")
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
            // MARK: - 1. Hero Header
            item {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(64.dp)
                            .clip(CircleShape)
                            .background(
                                Brush.linearGradient(listOf(PrimaryBlue, Color(0xFF00B4D8)))
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Sync,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(32.dp)
                        )
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    Text(
                        text = "Online Synchronisatie",
                        style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold)
                    )

                    Spacer(modifier = Modifier.height(6.dp))

                    Text(
                        text = "Houd al je spellen, scores, statistieken en tafelschikking automatisch 100% up-to-date tussen iOS en Android met één unieke koppelcode.",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.Gray,
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 12.dp)
                    )
                }
            }

            // MARK: - 2. Actieve Koppeling of Verbindingsopties
            if (isConnected) {
                // VERBONDEN STATUS
                item {
                    SectionTitle(title = "Actieve Koppeling")
                    AppCard {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = "JOUW KOPPELCODE",
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.Gray
                                )
                                Text(
                                    text = syncManager.cleanSyncCode,
                                    fontSize = 26.sp,
                                    fontWeight = FontWeight.Black,
                                    fontFamily = FontFamily.Monospace,
                                    color = PrimaryBlue
                                )
                            }

                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                IconButton(
                                    onClick = {
                                        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                        clipboard.setPrimaryClip(ClipData.newPlainText("Koppelcode", syncManager.cleanSyncCode))
                                        Toast.makeText(context, "Koppelcode gekopieerd!", Toast.LENGTH_SHORT).show()
                                    },
                                    modifier = Modifier
                                        .size(40.dp)
                                        .clip(CircleShape)
                                        .background(PrimaryBlue.copy(alpha = 0.12f))
                                ) {
                                    Icon(Icons.Default.ContentCopy, contentDescription = "Kopieer", tint = PrimaryBlue, modifier = Modifier.size(20.dp))
                                }

                                IconButton(
                                    onClick = {
                                        val shareIntent = Intent(Intent.ACTION_SEND).apply {
                                            type = "text/plain"
                                            putExtra(
                                                Intent.EXTRA_TEXT,
                                                "Mijn GamesApp koppelcode is: ${syncManager.cleanSyncCode}\nVoer deze in bij Instellingen > Cloud Synchronisatie om samen live scores en statistieken te delen!"
                                            )
                                        }
                                        context.startActivity(Intent.createChooser(shareIntent, "Deel Koppelcode via"))
                                    },
                                    modifier = Modifier
                                        .size(40.dp)
                                        .clip(CircleShape)
                                        .background(PrimaryBlue.copy(alpha = 0.12f))
                                ) {
                                    Icon(Icons.Default.Share, contentDescription = "Deel", tint = PrimaryBlue, modifier = Modifier.size(20.dp))
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))
                        HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))
                        Spacer(modifier = Modifier.height(10.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(8.dp)
                                        .clip(CircleShape)
                                        .background(Color(0xFF4CAF50))
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Verbonden met Cloud Vault", fontSize = 12.sp, color = Color.Gray)
                            }

                            lastSyncDate?.let { date ->
                                Text("Laatste: ${timeFormatter.format(Date(date))}", fontSize = 11.sp, color = Color.Gray)
                            }
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        // Nu Synchroniseren Knop
                        Button(
                            onClick = {
                                syncManager.syncNow { result ->
                                    result.onSuccess {
                                        Toast.makeText(context, it, Toast.LENGTH_SHORT).show()
                                    }.onFailure {
                                        Toast.makeText(context, "Fout: ${it.localizedMessage}", Toast.LENGTH_LONG).show()
                                    }
                                }
                            },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = !isSyncing,
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            if (isSyncing) {
                                CircularProgressView(tint = Color.White)
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Bezig met synchroniseren...")
                            } else {
                                Icon(Icons.Default.Sync, contentDescription = null)
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Nu Synchroniseren", fontWeight = FontWeight.Bold)
                            }
                        }

                        if (lastSyncSummary.isNotEmpty()) {
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(
                                text = lastSyncSummary,
                                fontSize = 11.sp,
                                color = Color.Gray,
                                modifier = Modifier.align(Alignment.CenterHorizontally)
                            )
                        }

                        Spacer(modifier = Modifier.height(10.dp))
                        HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))
                        Spacer(modifier = Modifier.height(6.dp))

                        // Automatische Sync Toggle
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text("Automatisch Synchroniseren", fontWeight = FontWeight.SemiBold)
                                Text("Direct bijwerken na elk potje en bij openen app", fontSize = 11.sp, color = Color.Gray)
                            }
                            Switch(
                                checked = isAutoSyncEnabled,
                                onCheckedChange = { syncManager.setAutoSyncEnabled(it) }
                            )
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        // Ontkoppelen knop
                        TextButton(
                            onClick = { showDisconnectDialog = true },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)
                        ) {
                            Icon(Icons.Default.Link, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Toestel Ontkoppelen")
                        }
                    }
                }
            } else {
                // NIET VERBONDEN STATUS: 2 OPTIES
                item {
                    SectionTitle(title = "Optie 1: Nieuwe Koppelcode Aanmaken")
                    AppCard {
                        Text(
                            text = "Wil je vanaf dit toestel starten? Maak een unieke code aan en deel die daarna met je andere apparaten.",
                            fontSize = 12.sp,
                            color = Color.Gray
                        )
                        Spacer(modifier = Modifier.height(12.dp))

                        Button(
                            onClick = {
                                syncManager.generateNewCode { result ->
                                    result.onSuccess { code ->
                                        Toast.makeText(context, "Koppelcode $code aangemaakt!", Toast.LENGTH_SHORT).show()
                                    }.onFailure { err ->
                                        Toast.makeText(context, "Fout: ${err.localizedMessage}", Toast.LENGTH_LONG).show()
                                    }
                                }
                            },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Icon(Icons.Default.Add, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Genereer Nieuwe Koppelcode", fontWeight = FontWeight.Bold)
                        }
                    }
                }

                item {
                    SectionTitle(title = "Optie 2: Koppelen met Bestaande Code")
                    AppCard {
                        Text(
                            text = "Heb je al een code op je andere telefoon of tablet? Vul hem hieronder in om alle data samen te voegen.",
                            fontSize = 12.sp,
                            color = Color.Gray
                        )
                        Spacer(modifier = Modifier.height(12.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            OutlinedTextField(
                                value = inputCode,
                                onValueChange = { inputCode = it.uppercase(Locale.getDefault()) },
                                placeholder = { Text("Bijv. SPEL-8429") },
                                singleLine = true,
                                modifier = Modifier.weight(1f),
                                shape = RoundedCornerShape(10.dp),
                                keyboardOptions = KeyboardOptions(
                                    capitalization = KeyboardCapitalization.Characters,
                                    imeAction = ImeAction.Done
                                ),
                                keyboardActions = KeyboardActions(
                                    onDone = {
                                        keyboardController?.hide()
                                        if (inputCode.isNotBlank()) {
                                            syncManager.connectWithCode(inputCode) { _ -> }
                                        }
                                    }
                                )
                            )

                            Spacer(modifier = Modifier.width(10.dp))

                            Button(
                                onClick = {
                                    keyboardController?.hide()
                                    syncManager.connectWithCode(inputCode) { result ->
                                        result.onSuccess {
                                            Toast.makeText(context, "Verbonden en gesynchroniseerd!", Toast.LENGTH_SHORT).show()
                                        }.onFailure {
                                            Toast.makeText(context, "Fout: ${it.localizedMessage}", Toast.LENGTH_LONG).show()
                                        }
                                    }
                                },
                                enabled = inputCode.isNotBlank() && !isSyncing,
                                shape = RoundedCornerShape(10.dp)
                            ) {
                                Text("Koppelen")
                            }
                        }

                        if (isSyncing) {
                            Spacer(modifier = Modifier.height(10.dp))
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                CircularProgressView(tint = PrimaryBlue)
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Data ophalen en samenvoegen...", fontSize = 12.sp, color = Color.Gray)
                            }
                        }
                    }
                }
            }

            // MARK: - 3. Server Instellingen
            item {
                SectionTitle(title = "Server & Database")
                AppCard {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { isAdvancedExpanded = !isAdvancedExpanded }
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Settings, contentDescription = null, tint = PrimaryBlue)
                            Spacer(modifier = Modifier.width(10.dp))
                            Text("Geavanceerde Database Instellingen", fontWeight = FontWeight.SemiBold)
                        }
                        Icon(
                            if (isAdvancedExpanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                            contentDescription = null,
                            tint = Color.Gray
                        )
                    }

                    AnimatedVisibility(visible = isAdvancedExpanded) {
                        Column(modifier = Modifier.padding(top = 10.dp)) {
                            Text("Firebase Realtime Database URL:", fontSize = 11.sp, color = Color.Gray)
                            Spacer(modifier = Modifier.height(4.dp))

                            OutlinedTextField(
                                value = customDbUrl,
                                onValueChange = { customDbUrl = it },
                                modifier = Modifier.fillMaxWidth(),
                                singleLine = true,
                                textStyle = LocalTextStyle.current.copy(fontSize = 12.sp, fontFamily = FontFamily.Monospace),
                                shape = RoundedCornerShape(8.dp)
                            )

                            Spacer(modifier = Modifier.height(10.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Button(
                                    onClick = {
                                        syncManager.updateDatabaseUrl(customDbUrl)
                                        Toast.makeText(context, "URL opgeslagen", Toast.LENGTH_SHORT).show()
                                    },
                                    modifier = Modifier.weight(1f),
                                    shape = RoundedCornerShape(8.dp)
                                ) {
                                    Text("Opslaan", fontSize = 12.sp)
                                }

                                OutlinedButton(
                                    onClick = {
                                        syncManager.resetDatabaseUrlToDefault()
                                        customDbUrl = CloudSyncManager.DEFAULT_DATABASE_URL
                                        Toast.makeText(context, "Standaard hersteld", Toast.LENGTH_SHORT).show()
                                    },
                                    modifier = Modifier.weight(1f),
                                    shape = RoundedCornerShape(8.dp)
                                ) {
                                    Text("Standaard", fontSize = 12.sp)
                                }
                            }

                            Spacer(modifier = Modifier.height(8.dp))

                            OutlinedButton(
                                onClick = {
                                    isTestingConnection = true
                                    testResultText = null
                                    syncManager.updateDatabaseUrl(customDbUrl)
                                    syncManager.testConnection { success, message ->
                                        isTestingConnection = false
                                        testResultText = message
                                    }
                                },
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(8.dp),
                                enabled = !isTestingConnection
                            ) {
                                if (isTestingConnection) {
                                    CircularProgressView(tint = PrimaryBlue)
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text("Testen...", fontSize = 12.sp)
                                } else {
                                    Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(16.dp))
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text("Test Verbinding", fontSize = 12.sp)
                                }
                            }

                            testResultText?.let { msg ->
                                Spacer(modifier = Modifier.height(6.dp))
                                Text(
                                    text = msg,
                                    fontSize = 11.sp,
                                    color = if (msg.contains("geslaagd")) Color(0xFF4CAF50) else MaterialTheme.colorScheme.error
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))
                    HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))
                    Spacer(modifier = Modifier.height(8.dp))

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { showHelpDialog = true }
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.HelpOutline, contentDescription = null, tint = PrimaryBlue)
                        Spacer(modifier = Modifier.width(10.dp))
                        Text("Hoe stel ik mijn eigen Firebase in? (Stappenplan)", fontSize = 13.sp, color = PrimaryBlue)
                    }
                }
            }
        }
    }

    // Dialoog: Ontkoppelen
    if (showDisconnectDialog) {
        AlertDialog(
            onDismissRequest = { showDisconnectDialog = false },
            title = { Text("Toestel Ontkoppelen?") },
            text = { Text("Je apparaat wordt losgekoppeld van deze cloud-kluis. Al je huidige spelers en scores blijven veilig lokaal op je toestel bewaard.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDisconnectDialog = false
                        syncManager.disconnect()
                        Toast.makeText(context, "Toestel ontkoppeld", Toast.LENGTH_SHORT).show()
                    },
                    colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)
                ) {
                    Text("Ontkoppel")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDisconnectDialog = false }) {
                    Text("Annuleren")
                }
            }
        )
    }

    // Dialoog: Firebase Stappenplan
    if (showHelpDialog) {
        AlertDialog(
            onDismissRequest = { showHelpDialog = false },
            title = { Text("In 2 minuten gratis Firebase instellen") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("1. Ga naar console.firebase.google.com en maak een nieuw gratis project aan.")
                    Text("2. Klik in het linkermenu op 'Build' ➔ 'Realtime Database' en klik op 'Database maken' (kies europe-west1).")
                    Text("3. Ga naar tabblad 'Rules' en stel in:\n{\n  \"rules\": {\n    \"vaults\": {\n      \"\$vault\": {\n        \".read\": true,\n        \".write\": true\n      }\n    }\n  }\n}")
                    Text("4. Kopieer de database-URL (eindigt op .firebasedatabase.app) en plak deze bij Geavanceerde Database Instellingen.")
                }
            },
            confirmButton = {
                TextButton(onClick = { showHelpDialog = false }) {
                    Text("Begrepen")
                }
            }
        )
    }
}

@Composable
private fun CircularProgressView(tint: Color) {
    CircularProgressIndicator(
        modifier = Modifier.size(16.dp),
        color = tint,
        strokeWidth = 2.dp
    )
}
