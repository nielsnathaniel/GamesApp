package nl.nnbp.gamesapp.ui.screens.games.cranium

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import nl.nnbp.gamesapp.data.ActiveGameManager
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.TeamGameInput
import nl.nnbp.gamesapp.data.model.PlayerScore
import nl.nnbp.gamesapp.ui.audio.SoundManager
import nl.nnbp.gamesapp.ui.components.AppCard
import nl.nnbp.gamesapp.ui.components.InhaalslagBanner
import nl.nnbp.gamesapp.ui.components.PuntenWijzigenDialog
import nl.nnbp.gamesapp.ui.components.SavedPlayersQuickChips
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.components.WieHeeftGelijkDialog
import nl.nnbp.gamesapp.ui.screens.winner.WinnaarScreen
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.RoyalPurple
import nl.nnbp.gamesapp.ui.theme.SuccessGreen
import nl.nnbp.gamesapp.ui.theme.WarningRed

enum class CraniumCat(val displayName: String, val subtitle: String, val color: Color) {
    DATA_HEAD("Data Head", "Trivia, weetjes & feiten", Color(0xFFFDD835)),
    CREATIVE_CAT("Creative Cat", "Tekenen, kleien & creatief", Color(0xFF1E88E5)),
    WORD_WORM("Word Worm", "Woorden, anagrammen & spelling", Color(0xFFE53935)),
    STAR_PERFORMER("Star Performer", "Uitbeelden, zingen & typetjes", Color(0xFF43A047)),
    CLUB_CRANIUM("Club Cranium", "Alle teams strijden mee!", RoyalPurple)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CraniumScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }
    val soundManager = remember { SoundManager.getInstance() }

    var isGameStarted by remember { mutableStateOf(false) }

    var team1Players by remember { mutableStateOf(mutableListOf<String>()) }
    var team2Players by remember { mutableStateOf(mutableListOf<String>()) }

    var teamScores by remember { mutableStateOf(mutableListOf(0, 0)) }
    var activeTeamIndex by remember { mutableIntStateOf(0) }
    var turnsPlayedPerTeam by remember { mutableStateOf(mutableListOf(0, 0)) }

    // Completed categories per team
    var team1Categories by remember { mutableStateOf(mutableSetOf<CraniumCat>()) }
    var team2Categories by remember { mutableStateOf(mutableSetOf<CraniumCat>()) }

    // Timer
    var remainingSeconds by remember { mutableIntStateOf(60) }
    var isTimerRunning by remember { mutableStateOf(false) }
    var showDisputeDialog by remember { mutableStateOf(false) }
    var showEditScoresDialog by remember { mutableStateOf(false) }

    var selectedCategory by remember { mutableStateOf(CraniumCat.DATA_HEAD) }
    var isSuccess by remember { mutableStateOf(true) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerTeamName by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(isTimerRunning) {
        while (isTimerRunning && remainingSeconds > 0) {
            delay(1000)
            remainingSeconds -= 1
            if (remainingSeconds in 1..5) {
                soundManager.playUrgentTick()
            }
        }
        if (remainingSeconds == 0 && isTimerRunning) {
            isTimerRunning = false
            soundManager.playBuzzer()
        }
    }

    val team1Name = remember(team1Players) {
        if (team1Players.isEmpty()) "Team 1" else team1Players.joinToString(" & ")
    }
    val team2Name = remember(team2Players) {
        if (team2Players.isEmpty()) "Team 2" else team2Players.joinToString(" & ")
    }

    if (isGameOver && winnerTeamName != null) {
        val allScores = listOf(
            PlayerScore(playerName = team1Name, score = teamScores[0], isWinner = winnerTeamName == team1Name),
            PlayerScore(playerName = team2Name, score = teamScores[1], isWinner = winnerTeamName == team2Name)
        )
        WinnaarScreen(
            gameName = "Cranium",
            winnerName = winnerTeamName!!,
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
                title = { Text("Cranium", fontWeight = FontWeight.Bold) },
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
                    }
                    IconButton(onClick = { showDisputeDialog = true }) {
                        Text("⚖️", fontSize = 18.sp)
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
                                text = "Spelregels Cranium 🧠",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Uitgebreid partyspel voor teams. Bevat de 4 iconische categorieën (Data Head, Creative Cat, Word Worm, Star Performer) en Club Cranium. Verzamel categorie-badges en bereik als eerste de finish!",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                            )
                        }
                    }

                    item {
                        SectionTitle(title = "Team 1 (minimaal 2 spelers)")
                        SavedPlayersQuickChips(
                            selectedPlayers = team1Players,
                            onTogglePlayer = { name ->
                                val list = team1Players.toMutableList()
                                if (list.contains(name)) list.remove(name) else list.add(name)
                                team1Players = list
                            }
                        )
                        if (team1Players.isNotEmpty()) {
                            Text("Team 1: ${team1Players.joinToString(" & ")}", color = PrimaryBlue, style = MaterialTheme.typography.bodySmall)
                        }
                    }

                    item {
                        SectionTitle(title = "Team 2 (minimaal 2 spelers)")
                        SavedPlayersQuickChips(
                            selectedPlayers = team2Players,
                            onTogglePlayer = { name ->
                                val list = team2Players.toMutableList()
                                if (list.contains(name)) list.remove(name) else list.add(name)
                                team2Players = list
                            }
                        )
                        if (team2Players.isNotEmpty()) {
                            Text("Team 2: ${team2Players.joinToString(" & ")}", color = AccentOrange, style = MaterialTheme.typography.bodySmall)
                        }
                    }
                }

                Button(
                    onClick = {
                        teamScores = mutableListOf(0, 0)
                        turnsPlayedPerTeam = mutableListOf(0, 0)
                        isGameStarted = true
                    },
                    enabled = team1Players.size >= 2 && team2Players.size >= 2,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Text("Start Cranium", style = MaterialTheme.typography.titleMedium)
                }
            }
        } else {
            // GAMEPLAY
            val activeTeamName = if (activeTeamIndex == 0) team1Name else team2Name
            val activePlayers = if (activeTeamIndex == 0) team1Players else team2Players
            val turnsPlayed = turnsPlayedPerTeam[activeTeamIndex]
            val performer = if (activePlayers.isNotEmpty()) activePlayers[turnsPlayed % activePlayers.size] else ""
            val activeTeamCats = if (activeTeamIndex == 0) team1Categories else team2Categories

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
                    item {
                        InhaalslagBanner(
                            playerNames = listOf(team1Name, team2Name),
                            scores = teamScores,
                            lowestWins = false
                        )
                    }

                    // Score & Badges bord
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Column(modifier = Modifier.padding(14.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceEvenly
                                ) {
                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                        Text(team1Name, fontWeight = FontWeight.Bold, color = PrimaryBlue)
                                        Text("${teamScores[0]} pt", style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold))
                                        Text("Badges: ${team1Categories.size}/4", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                    }
                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                        Text(team2Name, fontWeight = FontWeight.Bold, color = AccentOrange)
                                        Text("${teamScores[1]} pt", style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold))
                                        Text("Badges: ${team2Categories.size}/4", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                    }
                                }
                            }
                        }
                    }

                    // 60s Timer Kaart
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = if (remainingSeconds <= 10 && remainingSeconds > 0) WarningRed.copy(alpha = 0.15f) else MaterialTheme.colorScheme.surfaceVariant
                            )
                        ) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(14.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(
                                    text = "$remainingSeconds",
                                    style = MaterialTheme.typography.headlineLarge.copy(
                                        fontSize = 44.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (remainingSeconds <= 10) WarningRed else PrimaryBlue
                                    )
                                )
                                Text("seconden resterend", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                                Spacer(modifier = Modifier.height(10.dp))

                                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                    Button(
                                        onClick = { isTimerRunning = !isTimerRunning },
                                        colors = ButtonDefaults.buttonColors(containerColor = if (isTimerRunning) WarningRed else SuccessGreen),
                                        shape = RoundedCornerShape(10.dp)
                                    ) {
                                        Icon(if (isTimerRunning) Icons.Default.Pause else Icons.Default.PlayArrow, contentDescription = null)
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text(if (isTimerRunning) "Pauzeer" else "Start Timer")
                                    }
                                    OutlinedButton(
                                        onClick = {
                                            isTimerRunning = false
                                            remainingSeconds = 60
                                        },
                                        shape = RoundedCornerShape(10.dp)
                                    ) {
                                        Text("Reset")
                                    }
                                }
                            }
                        }
                    }

                    // Categorie selectie & Uitvoerder
                    item {
                        AppCard {
                            Text("Aan de beurt: $activeTeamName", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                            Text("🎭 Uitvoerder: $performer", fontWeight = FontWeight.SemiBold, color = PrimaryBlue)

                            Spacer(modifier = Modifier.height(10.dp))
                            Text("Kies categorie:", fontWeight = FontWeight.SemiBold)

                            Column(verticalArrangement = Arrangement.spacedBy(6.dp), modifier = Modifier.padding(top = 4.dp)) {
                                CraniumCat.entries.forEach { cat ->
                                    FilterChip(
                                        selected = selectedCategory == cat,
                                        onClick = { selectedCategory = cat },
                                        label = {
                                            Row(verticalAlignment = Alignment.CenterVertically) {
                                                Text(cat.displayName, fontWeight = FontWeight.Bold)
                                                Spacer(modifier = Modifier.width(6.dp))
                                                Text("(${cat.subtitle})", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                            }
                                        },
                                        shape = RoundedCornerShape(10.dp),
                                        modifier = Modifier.fillMaxWidth()
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(12.dp))
                            HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))
                            Spacer(modifier = Modifier.height(10.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("Opdracht geslaagd?", fontWeight = FontWeight.SemiBold)
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    FilterChip(
                                        selected = isSuccess,
                                        onClick = { isSuccess = true },
                                        label = { Text("✅ Geslaagd (+1 pt)") }
                                    )
                                    FilterChip(
                                        selected = !isSuccess,
                                        onClick = { isSuccess = false },
                                        label = { Text("❌ Mislukt (+0 pt)") }
                                    )
                                }
                            }
                        }
                    }
                }

                Button(
                    onClick = {
                        val newScores = teamScores.toMutableList()
                        if (isSuccess) {
                            newScores[activeTeamIndex] += 1
                            if (activeTeamIndex == 0 && selectedCategory != CraniumCat.CLUB_CRANIUM) {
                                team1Categories = (team1Categories + selectedCategory).toMutableSet()
                            } else if (activeTeamIndex == 1 && selectedCategory != CraniumCat.CLUB_CRANIUM) {
                                team2Categories = (team2Categories + selectedCategory).toMutableSet()
                            }
                        }
                        teamScores = newScores

                        val turns = turnsPlayedPerTeam.toMutableList()
                        turns[activeTeamIndex] += 1
                        turnsPlayedPerTeam = turns

                        // Check of een team gewonnen heeft (bijv. alle 4 badges + minstens 10 pt of directe afronding)
                        val team1Won = team1Categories.size >= 4 && newScores[0] >= 10
                        val team2Won = team2Categories.size >= 4 && newScores[1] >= 10

                        if (team1Won || team2Won) {
                            winnerTeamName = if (team1Won) team1Name else team2Name
                            val teamInputs = listOf(
                                TeamGameInput(teamName = team1Name, playerNames = team1Players, score = newScores[0], isWinner = winnerTeamName == team1Name),
                                TeamGameInput(teamName = team2Name, playerNames = team2Players, score = newScores[1], isWinner = winnerTeamName == team2Name)
                            )
                            scoreManager.saveTeamGame(
                                gameName = "Cranium",
                                teams = teamInputs
                            )
                            isGameOver = true
                        } else {
                            activeTeamIndex = (activeTeamIndex + 1) % 2
                            remainingSeconds = 60
                            isTimerRunning = false
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 12.dp)
                        .height(52.dp),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Icon(Icons.Default.CheckCircle, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Beurt Afronden", style = MaterialTheme.typography.titleMedium)
                }
            }
        }
    }

    if (showDisputeDialog) {
        WieHeeftGelijkDialog(
            initialGameFilter = "Cranium",
            onDismiss = { showDisputeDialog = false }
        )
    }

    if (showEditScoresDialog) {
        PuntenWijzigenDialog(
            playerNames = listOf(team1Name, team2Name),
            currentScores = teamScores,
            isLowestScoreWins = false,
            onDismiss = { showEditScoresDialog = false },
            onSave = { newScores ->
                teamScores = newScores.toMutableList()
            }
        )
    }
}
