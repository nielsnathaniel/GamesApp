package nl.nnbp.gamesapp.ui.screens.statistics

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.model.GameType
import nl.nnbp.gamesapp.ui.components.AppCard
import nl.nnbp.gamesapp.ui.components.SectionTitle
import nl.nnbp.gamesapp.ui.components.SpelerspaspoortDialog
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.RoyalPurple
import nl.nnbp.gamesapp.ui.theme.SuccessGreen

enum class StatsTab(val title: String) {
    OVERZICHT("Overzicht"),
    SPELERS("Spelers"),
    PER_SPEL("Per Spel"),
    DUOS("Duo's"),
    WIE_WINT("Wie wint?")
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StatisticsScreen(
    onNavigateToSessions: () -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val playedGames by scoreManager.playedGames.collectAsState()
    val savedPlayers by scoreManager.savedPlayerNames.collectAsState()

    var selectedTab by remember { mutableStateOf(StatsTab.OVERZICHT) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Statistieken",
                        style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold)
                    )
                },
                actions = {
                    TextButton(onClick = onNavigateToSessions) {
                        Text("Sessies", style = MaterialTheme.typography.labelLarge)
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Horizontal scrolling segment pills
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                StatsTab.entries.forEach { tab ->
                    val isSelected = selectedTab == tab
                    FilterChip(
                        selected = isSelected,
                        onClick = { selectedTab = tab },
                        label = {
                            Text(
                                text = tab.title,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                            )
                        },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = PrimaryBlue,
                            selectedLabelColor = Color.White
                        ),
                        shape = RoundedCornerShape(20.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(4.dp))

            if (playedGames.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Default.Leaderboard,
                            contentDescription = null,
                            tint = Color.Gray.copy(alpha = 0.5f),
                            modifier = Modifier.size(64.dp)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "Nog geen potjes gespeeld",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Speel een potje om diepgaande statistieken en ranglijsten te ontgrendelen!",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                    }
                }
            } else {
                when (selectedTab) {
                    StatsTab.OVERZICHT -> OverviewTabContent(scoreManager)
                    StatsTab.SPELERS -> PlayersTabContent(scoreManager)
                    StatsTab.PER_SPEL -> PerGameTabContent(scoreManager)
                    StatsTab.DUOS -> DuosTabContent(scoreManager)
                    StatsTab.WIE_WINT -> HeadToHeadTabContent(scoreManager)
                }
            }
        }
    }
}

@Composable
fun OverviewTabContent(scoreManager: ScoreManager) {
    val games by scoreManager.playedGames.collectAsState()
    val players by scoreManager.savedPlayerNames.collectAsState()
    val mostPlayed = remember(games) { scoreManager.mostPlayedGames() }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                StatCard(
                    title = "Totale Potjes",
                    value = games.size.toString(),
                    icon = Icons.Default.SportsEsports,
                    modifier = Modifier.weight(1f)
                )
                StatCard(
                    title = "Spelers",
                    value = players.size.toString(),
                    icon = Icons.Default.People,
                    iconColor = AccentOrange,
                    modifier = Modifier.weight(1f)
                )
            }
        }

        item {
            SectionTitle(title = "Meest Gespeelde Spellen")
            AppCard {
                mostPlayed.forEachIndexed { index, (gameName, count) ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "${index + 1}.",
                                style = MaterialTheme.typography.titleSmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
                                modifier = Modifier.width(24.dp)
                            )
                            Text(
                                text = gameName,
                                style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.SemiBold)
                            )
                        }
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = PrimaryBlue.copy(alpha = 0.12f)
                        ) {
                            Text(
                                text = "$count potjes",
                                style = MaterialTheme.typography.labelSmall.copy(
                                    fontWeight = FontWeight.Bold,
                                    color = PrimaryBlue
                                ),
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                            )
                        }
                    }
                    if (index < mostPlayed.size - 1) {
                        HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))
                    }
                }
            }
        }
    }
}

@Composable
fun PlayersTabContent(scoreManager: ScoreManager) {
    val rankings = remember { scoreManager.overallWinRankings() }
    val playerProfiles by scoreManager.playerProfiles.collectAsState()
    var selectedPlayerPassport by remember { mutableStateOf<String?>(null) }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            SectionTitle(title = "Ranglijst Aller Tijden", trailingText = "Winstpercentage")
        }

        items(rankings) { record ->
            val profile = playerProfiles[record.playerName.trim().lowercase()] ?: nl.nnbp.gamesapp.data.model.PlayerProfile.defaultFor(record.playerName)
            val playerColor = Color(profile.colorHex)

            AppCard(
                modifier = Modifier.clickable { selectedPlayerPassport = record.playerName }
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
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
                                .background(playerColor),
                            contentAlignment = Alignment.Center
                        ) {
                            if (profile.avatarEmoji != null) {
                                Text(profile.avatarEmoji, fontSize = 20.sp)
                            } else {
                                Text(
                                    text = record.playerName.take(1).uppercase(),
                                    style = MaterialTheme.typography.titleMedium.copy(
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White
                                    )
                                )
                            }
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text(
                                text = record.playerName,
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                            )
                            Text(
                                text = "${record.wins}x van de ${record.totalGames} • Tik voor paspoort 🪪",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                            )
                        }
                    }

                    Column(horizontalAlignment = Alignment.End) {
                        Text(
                            text = "${record.winRate.toInt()}%",
                            style = MaterialTheme.typography.titleLarge.copy(
                                fontWeight = FontWeight.Bold,
                                color = if (record.winRate >= 50) SuccessGreen else AccentOrange
                            )
                        )
                        Text(
                            text = "Winrate",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                        )
                    }
                }
            }
        }
    }

    selectedPlayerPassport?.let { playerName ->
        SpelerspaspoortDialog(
            playerName = playerName,
            scoreManager = scoreManager,
            onDismiss = { selectedPlayerPassport = null }
        )
    }
}
}

@Composable
fun PerGameTabContent(scoreManager: ScoreManager) {
    var selectedGameId by remember { mutableStateOf(GameType.entries.first().displayName) }
    val leaderboard = remember(selectedGameId) { scoreManager.gameLeaderboard(selectedGameId) }
    val bestScore = remember(selectedGameId) { scoreManager.bestScoreEver(selectedGameId) }
    val recent = remember(selectedGameId) { scoreManager.recentSessions(selectedGameId, limit = 5) }
    val balzakkenStats = remember(selectedGameId) {
        if (selectedGameId.equals("balzakken", ignoreCase = true)) scoreManager.balzakkenLeaderboard() else emptyList()
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                GameType.entries.forEach { game ->
                    val isSelected = selectedGameId == game.displayName
                    FilterChip(
                        selected = isSelected,
                        onClick = { selectedGameId = game.displayName },
                        label = { Text(game.displayName) },
                        shape = RoundedCornerShape(16.dp)
                    )
                }
            }
        }

        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                StatCard(
                    title = "Beste Score",
                    value = bestScore?.let { "${it.second} (${it.first})" } ?: "-",
                    icon = Icons.Default.EmojiEvents,
                    iconColor = AccentOrange,
                    modifier = Modifier.weight(1f)
                )
                StatCard(
                    title = "Gespeeld",
                    value = "${leaderboard.sumOf { it.gamesPlayed }}",
                    icon = Icons.Default.SportsEsports,
                    modifier = Modifier.weight(1f)
                )
            }
        }

        if (balzakkenStats.isNotEmpty()) {
            item {
                SectionTitle(title = "Balzakken Hall of Fame 👑")
                AppCard {
                    balzakkenStats.forEach { stat ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 6.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(stat.playerName, fontWeight = FontWeight.Bold)
                            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                Text("🎯 ${stat.juisteBalzakken}x Balzak", color = SuccessGreen, style = MaterialTheme.typography.bodySmall)
                                Text("⚠️ ${stat.fouteBalzakken}x Vals", color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }
                }
            }
        }

        item {
            SectionTitle(title = "Ranglijst: $selectedGameId")
            if (leaderboard.isEmpty()) {
                Text(
                    text = "Nog geen potjes geregistreerd voor dit spel.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            } else {
                AppCard {
                    leaderboard.forEachIndexed { idx, stat ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text("${idx + 1}.", modifier = Modifier.width(24.dp), color = Color.Gray)
                                Column {
                                    Text(stat.playerName, fontWeight = FontWeight.Bold)
                                    Text(
                                        "${stat.gamesWon}w / ${stat.gamesPlayed}p • PR: ${stat.bestScore ?: "-"}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                                    )
                                }
                            }
                            Text(
                                "${stat.winRate.toInt()}%",
                                fontWeight = FontWeight.Bold,
                                color = PrimaryBlue
                            )
                        }
                        if (idx < leaderboard.size - 1) {
                            HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun DuosTabContent(scoreManager: ScoreManager) {
    val teamLeaderboard = remember { scoreManager.teamLeaderboard() }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            SectionTitle(title = "Droomteams & Partner Chemie")
        }

        if (teamLeaderboard.isEmpty()) {
            item {
                Text(
                    text = "Speel teamspellen zoals Crokinole 2v2, 30 Seconds of Cranium om duo-statistieken te verzamelen.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
        } else {
            items(teamLeaderboard) { team ->
                AppCard {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(team.displayName, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
                            Text(
                                "${team.won}x gewonnen uit ${team.played} potjes",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                            )
                        }
                        Text(
                            "${team.winRate.toInt()}%",
                            fontWeight = FontWeight.Bold,
                            style = MaterialTheme.typography.titleLarge,
                            color = PrimaryBlue
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun HeadToHeadTabContent(scoreManager: ScoreManager) {
    val rivalries = remember { scoreManager.allRivalries() }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            SectionTitle(title = "Head-to-Head Rivaliteiten")
        }

        if (rivalries.isEmpty()) {
            item {
                Text(
                    text = "Zodra 2 spelers samen een potje spelen, zie je hier wie het vaakst van wie wint!",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
        } else {
            items(rivalries) { record ->
                AppCard {
                    Column(modifier = Modifier.fillMaxWidth()) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "${record.playerA} vs ${record.playerB}",
                                fontWeight = FontWeight.Bold,
                                style = MaterialTheme.typography.titleMedium
                            )
                            Text(
                                text = "${record.winsA} - ${record.winsB}",
                                fontWeight = FontWeight.Bold,
                                style = MaterialTheme.typography.titleMedium,
                                color = PrimaryBlue
                            )
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = record.leaderSummary,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                    }
                }
            }
        }
    }
}
