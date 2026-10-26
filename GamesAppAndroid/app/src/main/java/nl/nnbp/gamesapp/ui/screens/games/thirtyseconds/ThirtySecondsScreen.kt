package nl.nnbp.gamesapp.ui.screens.games.thirtyseconds

import androidx.compose.foundation.background
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
import nl.nnbp.gamesapp.ui.theme.SuccessGreen
import nl.nnbp.gamesapp.ui.theme.WarningRed

data class TeamSetup(
    val name: String,
    val players: List<String>,
    val color: Color
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ThirtySecondsScreen(
    onNavigateBack: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val activeGameManager = remember { ActiveGameManager.getInstance() }
    val soundManager = remember { SoundManager.getInstance() }

    var isGameStarted by remember { mutableStateOf(false) }
    var targetScore by remember { mutableIntStateOf(35) }

    // 2 tot 4 teams
    var team1Players by remember { mutableStateOf(mutableListOf<String>()) }
    var team2Players by remember { mutableStateOf(mutableListOf<String>()) }

    var teamScores by remember { mutableStateOf(mutableListOf(0, 0)) }
    var activeTeamIndex by remember { mutableIntStateOf(0) }
    var turnsPlayedPerTeam by remember { mutableStateOf(mutableListOf(0, 0)) }

    // Timer state
    var remainingSeconds by remember { mutableIntStateOf(30) }
    var isTimerRunning by remember { mutableStateOf(false) }
    var showDisputeDialog by remember { mutableStateOf(false) }
    var showEditScoresDialog by remember { mutableStateOf(false) }

    // Beurt-invoer
    var diceRoll by remember { mutableIntStateOf(0) }
    var correctCount by remember { mutableIntStateOf(0) }

    var isGameOver by remember { mutableStateOf(false) }
    var winnerTeamName by remember { mutableStateOf<String?>(null) }

    val stepsEarned = remember(correctCount, diceRoll) {
        maxOf(0, correctCount - diceRoll)
    }

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
            gameName = "30 Seconds",
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
                title = { Text("30 Seconds", fontWeight = FontWeight.Bold) },
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
                                text = "Spelregels 30 Seconds ⏱️",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Omschrijf 5 begrippen in 30 seconden. Gooi de dobbelsteen (0, 1 of 2 strafpunten). Aantal verdiende stappen = goede antwoorden minus dobbelsteenworp. Eerste team op $targetScore stappen wint!",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                            )
                        }
                    }

                    item {
                        AppCard {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("Doelscore stappen:", fontWeight = FontWeight.SemiBold)
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    listOf(30, 35, 40).forEach { pts ->
                                        FilterChip(
                                            selected = targetScore == pts,
                                            onClick = { targetScore = pts },
                                            label = { Text("$pts stappen") },
                                            shape = RoundedCornerShape(10.dp)
                                        )
                                    }
                                }
                            }
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
                    Text("Start Spel (Doel: $targetScore)", style = MaterialTheme.typography.titleMedium)
                }
            }
        } else {
            // GAMEPLAY
            val activeTeamName = if (activeTeamIndex == 0) team1Name else team2Name
            val activePlayers = if (activeTeamIndex == 0) team1Players else team2Players
            val turnsPlayed = turnsPlayedPerTeam[activeTeamIndex]
            val describer = if (activePlayers.isNotEmpty()) activePlayers[turnsPlayed % activePlayers.size] else ""
            val guessers = activePlayers.filter { it != describer }

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

                    // Scorebord Tegel
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                        ) {
                            Column(modifier = Modifier.padding(14.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text("Stand (Doel: $targetScore stappen)", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                                }
                                Spacer(modifier = Modifier.height(8.dp))
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceEvenly
                                ) {
                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                        Text(team1Name, fontWeight = FontWeight.Bold, color = PrimaryBlue)
                                        Text("${teamScores[0]}", style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold, color = PrimaryBlue))
                                    }
                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                        Text(team2Name, fontWeight = FontWeight.Bold, color = AccentOrange)
                                        Text("${teamScores[1]}", style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold, color = AccentOrange))
                                    }
                                }
                            }
                        }
                    }

                    // Timer Kaart
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = if (remainingSeconds <= 5 && remainingSeconds > 0) WarningRed.copy(alpha = 0.15f) else MaterialTheme.colorScheme.surfaceVariant
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
                                        fontSize = 48.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (remainingSeconds <= 5) WarningRed else PrimaryBlue
                                    )
                                )
                                Text("seconden resterend", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                                Spacer(modifier = Modifier.height(10.dp))

                                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                    Button(
                                        onClick = {
                                            isTimerRunning = !isTimerRunning
                                        },
                                        colors = ButtonDefaults.buttonColors(
                                            containerColor = if (isTimerRunning) WarningRed else SuccessGreen
                                        ),
                                        shape = RoundedCornerShape(10.dp)
                                    ) {
                                        Icon(if (isTimerRunning) Icons.Default.Pause else Icons.Default.PlayArrow, contentDescription = null)
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text(if (isTimerRunning) "Pauzeer" else "Start Timer")
                                    }

                                    OutlinedButton(
                                        onClick = {
                                            isTimerRunning = false
                                            remainingSeconds = 30
                                        },
                                        shape = RoundedCornerShape(10.dp)
                                    ) {
                                        Text("Reset")
                                    }
                                }
                            }
                        }
                    }

                    // Beurt Details
                    item {
                        AppCard {
                            Text("Aan de beurt: $activeTeamName", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                            Spacer(modifier = Modifier.height(4.dp))
                            Text("🗣️ Omschrijver: $describer", fontWeight = FontWeight.SemiBold, color = PrimaryBlue)
                            Text("👥 Rader(s): ${guessers.joinToString(", ")}", style = MaterialTheme.typography.bodySmall, color = Color.Gray)

                            Spacer(modifier = Modifier.height(12.dp))
                            HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))
                            Spacer(modifier = Modifier.height(10.dp))

                            // Dobbelsteen (0, 1 of 2)
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("🎲 Dobbelsteenworp:", fontWeight = FontWeight.SemiBold)
                                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                    listOf(0, 1, 2).forEach { roll ->
                                        FilterChip(
                                            selected = diceRoll == roll,
                                            onClick = {
                                                diceRoll = roll
                                                soundManager.playDiceRoll()
                                            },
                                            label = { Text("$roll") },
                                            shape = RoundedCornerShape(8.dp)
                                        )
                                    }
                                }
                            }

                            Spacer(modifier = Modifier.height(8.dp))

                            // Goede antwoorden (0..5)
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text("✅ Goed geraden:", fontWeight = FontWeight.SemiBold)
                                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                    (0..5).forEach { cnt ->
                                        FilterChip(
                                            selected = correctCount == cnt,
                                            onClick = { correctCount = cnt },
                                            label = { Text("$cnt") },
                                            shape = RoundedCornerShape(8.dp)
                                        )
                                    }
                                }
                            }

                            Spacer(modifier = Modifier.height(10.dp))

                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = SuccessGreen.copy(alpha = 0.12f),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier.padding(10.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("Verdiende stappen:", fontWeight = FontWeight.Bold, color = SuccessGreen)
                                    Text("+$stepsEarned stappen", fontWeight = FontWeight.Bold, color = SuccessGreen, style = MaterialTheme.typography.titleMedium)
                                }
                            }
                        }
                    }
                }

                Button(
                    onClick = {
                        val newScores = teamScores.toMutableList()
                        newScores[activeTeamIndex] += stepsEarned
                        teamScores = newScores

                        val turns = turnsPlayedPerTeam.toMutableList()
                        turns[activeTeamIndex] += 1
                        turnsPlayedPerTeam = turns

                        if (newScores[activeTeamIndex] >= targetScore) {
                            winnerTeamName = activeTeamName
                            val teamInputs = listOf(
                                TeamGameInput(teamName = team1Name, playerNames = team1Players, score = newScores[0], isWinner = winnerTeamName == team1Name),
                                TeamGameInput(teamName = team2Name, playerNames = team2Players, score = newScores[1], isWinner = winnerTeamName == team2Name)
                            )
                            scoreManager.saveTeamGame(
                                gameName = "30 Seconds",
                                teams = teamInputs
                            )
                            isGameOver = true
                        } else {
                            activeTeamIndex = (activeTeamIndex + 1) % 2
                            remainingSeconds = 30
                            isTimerRunning = false
                            diceRoll = 0
                            correctCount = 0
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
                    Text("Beurt Beëindigen (+$stepsEarned)", style = MaterialTheme.typography.titleMedium)
                }
            }
        }
    }

    if (showDisputeDialog) {
        WieHeeftGelijkDialog(
            initialGameFilter = "30 Seconds",
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
