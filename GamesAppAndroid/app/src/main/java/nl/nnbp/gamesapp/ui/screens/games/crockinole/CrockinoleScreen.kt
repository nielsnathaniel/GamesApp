package nl.nnbp.gamesapp.ui.screens.games.crockinole

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import nl.nnbp.gamesapp.data.ActiveGameManager
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.TeamGameInput
import nl.nnbp.gamesapp.data.model.CrokinoleGameStats
import nl.nnbp.gamesapp.data.model.CrokinoleRoundRecord
import nl.nnbp.gamesapp.data.model.PlayerScore
import nl.nnbp.gamesapp.ui.components.AppCard
import nl.nnbp.gamesapp.ui.components.PuntenWijzigenDialog
import nl.nnbp.gamesapp.ui.components.SavedPlayersQuickChips
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SuccessGreen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CrockinoleScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }

    var isGameStarted by remember { mutableStateOf(false) }
    var isTeamMode by remember { mutableStateOf(false) } // false = 1v1, true = 2v2

    // Team Wit & Zwart spelers
    var teamWitSpelers by remember { mutableStateOf(mutableListOf<String>()) }
    var teamZwartSpelers by remember { mutableStateOf(mutableListOf<String>()) }

    // Scoring mode: "Alles" (Direct) vs "Berekend" (Per schijf)
    var isCalculatedMode by remember { mutableStateOf(false) }

    // In-game state
    var currentRound by remember { mutableIntStateOf(1) }
    var currentSet by remember { mutableIntStateOf(1) }
    var setsWonWit by remember { mutableIntStateOf(0) }
    var setsWonZwart by remember { mutableIntStateOf(0) }
    var setPointsWit by remember { mutableIntStateOf(0) }
    var setPointsZwart by remember { mutableIntStateOf(0) }

    // Direct input points
    var roundPointsWit by remember { mutableIntStateOf(0) }
    var roundPointsZwart by remember { mutableIntStateOf(0) }

    // Schijventellers voor berekende modus (20, 15, 10, 5)
    var discsWit20 by remember { mutableIntStateOf(0) }
    var discsWit15 by remember { mutableIntStateOf(0) }
    var discsWit10 by remember { mutableIntStateOf(0) }
    var discsWit5 by remember { mutableIntStateOf(0) }

    var discsZwart20 by remember { mutableIntStateOf(0) }
    var discsZwart15 by remember { mutableIntStateOf(0) }
    var discsZwart10 by remember { mutableIntStateOf(0) }
    var discsZwart5 by remember { mutableIntStateOf(0) }

    // Effective round scores
    val effectiveWitScore = if (isCalculatedMode) {
        (discsWit20 * 20) + (discsWit15 * 15) + (discsWit10 * 10) + (discsWit5 * 5)
    } else roundPointsWit

    val effectiveZwartScore = if (isCalculatedMode) {
        (discsZwart20 * 20) + (discsZwart15 * 15) + (discsZwart10 * 10) + (discsZwart5 * 5)
    } else roundPointsZwart

    val differential = kotlin.math.abs(effectiveWitScore - effectiveZwartScore)
    val roundWinnerName = when {
        effectiveWitScore > effectiveZwartScore -> "Wit"
        effectiveZwartScore > effectiveWitScore -> "Zwart"
        else -> "Gelijkspel"
    }

    var roundRecords by remember { mutableStateOf(mutableListOf<CrokinoleRoundRecord>()) }
    var showHistorySheet by remember { mutableStateOf(false) }
    var showEditScoresDialog by remember { mutableStateOf(false) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerTeamName by remember { mutableStateOf<String?>(null) }

    val teamWitDisplayName = remember(teamWitSpelers) {
        if (teamWitSpelers.isEmpty()) "Team Wit" else teamWitSpelers.joinToString(" & ")
    }
    val teamZwartDisplayName = remember(teamZwartSpelers) {
        if (teamZwartSpelers.isEmpty()) "Team Zwart" else teamZwartSpelers.joinToString(" & ")
    }

    if (isGameOver && winnerTeamName != null) {
        val allScores = listOf(
            PlayerScore(playerName = teamWitDisplayName, score = setsWonWit, isWinner = winnerTeamName == "Wit"),
            PlayerScore(playerName = teamZwartDisplayName, score = setsWonZwart, isWinner = winnerTeamName == "Zwart")
        )
        WinnaarScreen(
            gameName = "Crokinole",
            winnerName = if (winnerTeamName == "Wit") teamWitDisplayName else teamZwartDisplayName,
            scores = allScores,
            onFinish = {
                activeGameManager.clearActiveGame()
                onNavigateBack()
            }
        )
        return
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Crokinole", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Terug")
                    }
                },
                actions = {
                    if (isGameStarted) {
                        IconButton(onClick = { showEditScoresDialog = true }) {
                            Icon(Icons.Default.Edit, contentDescription = "Punten wijzigen", tint = AccentOrange)
                        }
                        TextButton(onClick = { showHistorySheet = true }) {
                            Icon(Icons.Default.History, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Rondes (${roundRecords.size})")
                        }
                    }
                }
            )
        }
    ) { padding ->
        if (!isGameStarted) {
            // SETUP
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(16.dp),
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    item {
                        AppCard {
                            Text(
                                text = "Crokinole Spelmodus 🔘",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                FilterChip(
                                    selected = !isTeamMode,
                                    onClick = { isTeamMode = false },
                                    label = { Text("1 tegen 1") },
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier.weight(1f)
                                )
                                FilterChip(
                                    selected = isTeamMode,
                                    onClick = { isTeamMode = true },
                                    label = { Text("2 tegen 2 (Teams)") },
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }
                    }

                    // Spelerselectie Team Wit
                    item {
                        SectionTitle(title = "Team Wit ${if (isTeamMode) "(2 spelers)" else "(1 speler)"}")
                        SavedPlayersQuickChips(
                            selectedPlayers = teamWitSpelers,
                            onTogglePlayer = { name ->
                                val list = teamWitSpelers.toMutableList()
                                if (list.contains(name)) list.remove(name)
                                else if (list.size < (if (isTeamMode) 2 else 1)) list.add(name)
                                teamWitSpelers = list
                            }
                        )
                        if (teamWitSpelers.isNotEmpty()) {
                            Text(
                                text = "Gekozen: ${teamWitSpelers.joinToString(" & ")}",
                                style = MaterialTheme.typography.bodySmall,
                                color = PrimaryBlue,
                                modifier = Modifier.padding(top = 4.dp)
                            )
                        }
                    }

                    // Spelerselectie Team Zwart
                    item {
                        SectionTitle(title = "Team Zwart ${if (isTeamMode) "(2 spelers)" else "(1 speler)"}")
                        SavedPlayersQuickChips(
                            selectedPlayers = teamZwartSpelers,
                            onTogglePlayer = { name ->
                                val list = teamZwartSpelers.toMutableList()
                                if (list.contains(name)) list.remove(name)
                                else if (list.size < (if (isTeamMode) 2 else 1)) list.add(name)
                                teamZwartSpelers = list
                            }
                        )
                        if (teamZwartSpelers.isNotEmpty()) {
                            Text(
                                text = "Gekozen: ${teamZwartSpelers.joinToString(" & ")}",
                                style = MaterialTheme.typography.bodySmall,
                                color = PrimaryBlue,
                                modifier = Modifier.padding(top = 4.dp)
                            )
                        }
                    }
                }

                val requiredPerTeam = if (isTeamMode) 2 else 1
                val canStart = teamWitSpelers.size == requiredPerTeam && teamZwartSpelers.size == requiredPerTeam

                Button(
                    onClick = { isGameStarted = true },
                    enabled = canStart,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text("Start Wedstrijd (Eerste tot 3 sets)", style = MaterialTheme.typography.titleMedium)
                }
            }
        } else {
            // GAMEPLAY
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Header Statuskaart: Sets & Set-punten
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Column(modifier = Modifier.padding(14.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = "Ronde $currentRound • Set $currentSet",
                                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                                    )
                                    Text(
                                        text = "100 pt = Setwinst",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color.Gray
                                    )
                                }

                                Spacer(modifier = Modifier.height(10.dp))

                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceEvenly,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    // Team Wit
                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                        Text(teamWitDisplayName, fontWeight = FontWeight.Bold)
                                        Text(
                                            text = "$setsWonWit sets",
                                            style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold, color = PrimaryBlue)
                                        )
                                        Text("$setPointsWit / 100 pt", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                    }

                                    Text("VS", fontWeight = FontWeight.Bold, color = Color.Gray)

                                    // Team Zwart
                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                        Text(teamZwartDisplayName, fontWeight = FontWeight.Bold)
                                        Text(
                                            text = "$setsWonZwart sets",
                                            style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold, color = AccentOrange)
                                        )
                                        Text("$setPointsZwart / 100 pt", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                    }
                                }
                            }
                        }
                    }

                    // Schakel telwijze knop
                    item {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("Telwijze:", fontWeight = FontWeight.SemiBold)
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                FilterChip(
                                    selected = !isCalculatedMode,
                                    onClick = { isCalculatedMode = false },
                                    label = { Text("Direct (Presets)") },
                                    shape = RoundedCornerShape(10.dp)
                                )
                                FilterChip(
                                    selected = isCalculatedMode,
                                    onClick = { isCalculatedMode = true },
                                    label = { Text("Berekend (Per schijf)") },
                                    shape = RoundedCornerShape(10.dp)
                                )
                            }
                        }
                    }

                    // Score Invoer
                    item {
                        AppCard {
                            Text("Ronde Invoer", fontWeight = FontWeight.Bold)
                            Spacer(modifier = Modifier.height(8.dp))

                            if (!isCalculatedMode) {
                                // Directe presets
                                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Text("Team Wit Score: $roundPointsWit pt", fontWeight = FontWeight.SemiBold, color = PrimaryBlue)
                                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                        listOf(5, 10, 15, 20, 25).forEach { pts ->
                                            FilledTonalButton(
                                                onClick = { roundPointsWit += pts },
                                                modifier = Modifier.weight(1f),
                                                contentPadding = PaddingValues(0.dp)
                                            ) {
                                                Text("+$pts", fontSize = 11.sp)
                                            }
                                        }
                                        FilledTonalButton(
                                            onClick = { roundPointsWit = 0 },
                                            modifier = Modifier.weight(1f),
                                            contentPadding = PaddingValues(0.dp)
                                        ) {
                                            Text("0", fontSize = 11.sp, color = MaterialTheme.colorScheme.error)
                                        }
                                    }

                                    Spacer(modifier = Modifier.height(4.dp))

                                    Text("Team Zwart Score: $roundPointsZwart pt", fontWeight = FontWeight.SemiBold, color = AccentOrange)
                                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                        listOf(5, 10, 15, 20, 25).forEach { pts ->
                                            FilledTonalButton(
                                                onClick = { roundPointsZwart += pts },
                                                modifier = Modifier.weight(1f),
                                                contentPadding = PaddingValues(0.dp)
                                            ) {
                                                Text("+$pts", fontSize = 11.sp)
                                            }
                                        }
                                        FilledTonalButton(
                                            onClick = { roundPointsZwart = 0 },
                                            modifier = Modifier.weight(1f),
                                            contentPadding = PaddingValues(0.dp)
                                        ) {
                                            Text("0", fontSize = 11.sp, color = MaterialTheme.colorScheme.error)
                                        }
                                    }
                                }
                            } else {
                                // Berekende modus (Centrum 20, Binnen 15, Midden 10, Buiten 5)
                                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Text("Team Wit: $effectiveWitScore pt", fontWeight = FontWeight.SemiBold, color = PrimaryBlue)
                                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                        RingStepper(title = "20pt", count = discsWit20, onAdd = { discsWit20++ }, onSub = { if (discsWit20 > 0) discsWit20-- })
                                        RingStepper(title = "15pt", count = discsWit15, onAdd = { discsWit15++ }, onSub = { if (discsWit15 > 0) discsWit15-- })
                                        RingStepper(title = "10pt", count = discsWit10, onAdd = { discsWit10++ }, onSub = { if (discsWit10 > 0) discsWit10-- })
                                        RingStepper(title = "5pt", count = discsWit5, onAdd = { discsWit5++ }, onSub = { if (discsWit5 > 0) discsWit5-- })
                                    }

                                    Spacer(modifier = Modifier.height(6.dp))

                                    Text("Team Zwart: $effectiveZwartScore pt", fontWeight = FontWeight.SemiBold, color = AccentOrange)
                                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                        RingStepper(title = "20pt", count = discsZwart20, onAdd = { discsZwart20++ }, onSub = { if (discsZwart20 > 0) discsZwart20-- })
                                        RingStepper(title = "15pt", count = discsZwart15, onAdd = { discsZwart15++ }, onSub = { if (discsZwart15 > 0) discsZwart15-- })
                                        RingStepper(title = "10pt", count = discsZwart10, onAdd = { discsZwart10++ }, onSub = { if (discsZwart10 > 0) discsZwart10-- })
                                        RingStepper(title = "5pt", count = discsZwart5, onAdd = { discsZwart5++ }, onSub = { if (discsZwart5 > 0) discsZwart5-- })
                                    }
                                }
                            }
                        }
                    }
                }

                // Ronde beëindigen knop met differentieel preview
                val buttonPreviewText = when {
                    differential == 0 -> "Ronde Beëindigen (Gelijkspel: +0 pt)"
                    roundWinnerName == "Wit" -> "Ronde Beëindigen (+${differential} pt voor $teamWitDisplayName)"
                    else -> "Ronde Beëindigen (+${differential} pt voor $teamZwartDisplayName)"
                }

                Button(
                    onClick = {
                        val record = CrokinoleRoundRecord(
                            roundNumber = currentRound,
                            setNumber = currentSet,
                            scoreWit = effectiveWitScore,
                            scoreZwart = effectiveZwartScore,
                            differential = differential,
                            roundWinner = roundWinnerName,
                            setWonInThisRound = false
                        )
                        val newRecords = roundRecords.toMutableList()
                        newRecords.add(record)
                        roundRecords = newRecords

                        if (roundWinnerName == "Wit") {
                            setPointsWit += differential
                        } else if (roundWinnerName == "Zwart") {
                            setPointsZwart += differential
                        }

                        // Check of iemand 100 set-punten bereikt heeft
                        if (setPointsWit >= 100) {
                            setsWonWit += 1
                            setPointsWit = 0
                            setPointsZwart = 0
                            currentSet += 1
                        } else if (setPointsZwart >= 100) {
                            setsWonZwart += 1
                            setPointsWit = 0
                            setPointsZwart = 0
                            currentSet += 1
                        }

                        // Check of een team 3 sets heeft gewonnen
                        if (setsWonWit >= 3 || setsWonZwart >= 3) {
                            val winnaar = if (setsWonWit >= 3) "Wit" else "Zwart"
                            winnerTeamName = winnaar

                            val crokStats = CrokinoleGameStats(
                                totalRounds = currentRound,
                                totalSets = currentSet - 1,
                                rounds = newRecords
                            )

                            val teamInputs = listOf(
                                TeamGameInput(teamName = teamWitDisplayName, playerNames = teamWitSpelers, score = setsWonWit, isWinner = winnaar == "Wit"),
                                TeamGameInput(teamName = teamZwartDisplayName, playerNames = teamZwartSpelers, score = setsWonZwart, isWinner = winnaar == "Zwart")
                            )

                            scoreManager.saveTeamGame(
                                gameName = "Crockinole",
                                teams = teamInputs,
                                crokinoleStats = crokStats
                            )
                            isGameOver = true
                        } else {
                            currentRound += 1
                            roundPointsWit = 0
                            roundPointsZwart = 0
                            discsWit20 = 0
                            discsWit15 = 0
                            discsWit10 = 0
                            discsWit5 = 0
                            discsZwart20 = 0
                            discsZwart15 = 0
                            discsZwart10 = 0
                            discsZwart5 = 0
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 12.dp)
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Icon(Icons.Default.CheckCircle, contentDescription = null)
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(buttonPreviewText, style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold))
                }
            }
        }
    }

    if (showHistorySheet) {
        AlertDialog(
            onDismissRequest = { showHistorySheet = false },
            title = { Text("Rondehistorie Crokinole") },
            text = {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 350.dp)
                ) {
                    if (roundRecords.isEmpty()) {
                        item { Text("Nog geen rondes voltooid.") }
                    } else {
                        items(roundRecords.reversed()) { rec ->
                            AppCard(modifier = Modifier.padding(vertical = 4.dp)) {
                                Text(
                                    text = "Ronde ${rec.roundNumber} (Set ${rec.setNumber})",
                                    fontWeight = FontWeight.Bold,
                                    style = MaterialTheme.typography.labelLarge
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text("Wit: ${rec.scoreWit} pt • Zwart: ${rec.scoreZwart} pt", style = MaterialTheme.typography.bodySmall)
                                Text(
                                    text = "Winnaar: ${rec.roundWinner} (+${rec.differential} pt differentieel)",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = PrimaryBlue
                                )
                            }
                        }
                    }
                }
            },
            confirmButton = {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TextButton(onClick = {
                        showHistorySheet = false
                        showEditScoresDialog = true
                    }) {
                        Icon(Icons.Default.Edit, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Punten wijzigen")
                    }
                    TextButton(onClick = { showHistorySheet = false }) {
                        Text("Sluiten")
                    }
                }
            }
        )
    }

    if (showEditScoresDialog) {
        PuntenWijzigenDialog(
            playerNames = listOf(teamWitDisplayName, teamZwartDisplayName),
            currentScores = listOf(setPointsWit, setPointsZwart),
            isLowestScoreWins = false,
            title = "Setpunten Wijzigen",
            subtitle = "Pas de stand van Wit en Zwart direct aan.",
            onDismiss = { showEditScoresDialog = false },
            onSave = { newScores ->
                setPointsWit = newScores.getOrElse(0) { setPointsWit }
                setPointsZwart = newScores.getOrElse(1) { setPointsZwart }
            }
        )
    }
}

@Composable
fun RingStepper(
    title: String,
    count: Int,
    onAdd: () -> Unit,
    onSub: () -> Unit
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(title, style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold)
        Spacer(modifier = Modifier.height(2.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            FilledTonalButton(
                onClick = onSub,
                modifier = Modifier.size(28.dp),
                contentPadding = PaddingValues(0.dp),
                shape = CircleShape
            ) {
                Text("-", fontSize = 14.sp)
            }
            Text(
                text = "$count",
                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold),
                modifier = Modifier.padding(horizontal = 6.dp)
            )
            FilledTonalButton(
                onClick = onAdd,
                modifier = Modifier.size(28.dp),
                contentPadding = PaddingValues(0.dp),
                shape = CircleShape
            ) {
                Text("+", fontSize = 14.sp)
            }
        }
    }
}
