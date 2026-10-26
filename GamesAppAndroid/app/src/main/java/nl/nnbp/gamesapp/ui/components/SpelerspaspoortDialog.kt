package nl.nnbp.gamesapp.ui.components

import androidx.compose.animation.AnimatedVisibility
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.data.model.PlayerBadge
import nl.nnbp.gamesapp.data.model.PlayerPassportData
import nl.nnbp.gamesapp.data.model.PlayerProfile
import nl.nnbp.gamesapp.data.model.PresetAvatarEmojis
import nl.nnbp.gamesapp.data.model.PresetTableColors
import nl.nnbp.gamesapp.ui.theme.CardBackground
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SurfaceDark

@Composable
fun SpelerspaspoortDialog(
    playerName: String,
    scoreManager: ScoreManager,
    onDismiss: () -> Unit
) {
    var passport by remember(playerName) { mutableStateOf(scoreManager.playerPassport(playerName)) }
    var isEditingProfile by remember { mutableStateOf(false) }
    var selectedColor by remember(passport) { mutableStateOf(passport.profile.colorHex) }
    var selectedEmoji by remember(passport) { mutableStateOf(passport.profile.avatarEmoji) }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 16.dp),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = SurfaceDark)
        ) {
            LazyColumn(
                modifier = Modifier
                    .padding(20.dp)
                    .fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Header met Sluiten knop
                item {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Spelerspaspoort",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = Color.White.copy(alpha = 0.7f)
                        )
                        IconButton(onClick = onDismiss) {
                            Icon(Icons.Default.Close, contentDescription = "Sluiten", tint = Color.White)
                        }
                    }
                }

                // Profiel Hoofdsectie
                item {
                    val playerColor = Color(passport.profile.colorHex)
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Box(
                            modifier = Modifier
                                .size(76.dp)
                                .clip(CircleShape)
                                .background(playerColor)
                                .border(3.dp, Color.White.copy(alpha = 0.2f), CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            if (passport.profile.avatarEmoji != null) {
                                Text(passport.profile.avatarEmoji!!, fontSize = 36.sp)
                            } else {
                                Text(
                                    passport.profile.name.take(1).uppercase(),
                                    color = Color.White,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 32.sp
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        Text(
                            text = passport.profile.name,
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )

                        Spacer(modifier = Modifier.height(4.dp))

                        TextButton(
                            onClick = { isEditingProfile = !isEditingProfile },
                            colors = ButtonDefaults.textButtonColors(contentColor = PrimaryBlue)
                        ) {
                            Icon(
                                if (isEditingProfile) Icons.Default.Close else Icons.Default.Edit,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                if (isEditingProfile) "Annuleren" else "Kleur & Avatar Wijzigen",
                                fontSize = 13.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }

                // Uitklapbare Kleur- & Avatar-kiezer
                if (isEditingProfile) {
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = CardBackground)
                        ) {
                            Column(modifier = Modifier.padding(14.dp)) {
                                Text(
                                    "Kies Tafelkleur:",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.sp,
                                    color = Color.White
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                LazyRow(
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    items(PresetTableColors) { colHex ->
                                        val isSel = colHex == selectedColor
                                        Box(
                                            modifier = Modifier
                                                .size(34.dp)
                                                .clip(CircleShape)
                                                .background(Color(colHex))
                                                .border(
                                                    width = if (isSel) 3.dp else 1.dp,
                                                    color = if (isSel) Color.White else Color.Transparent,
                                                    shape = CircleShape
                                                )
                                                .clickable {
                                                    selectedColor = colHex
                                                },
                                            contentAlignment = Alignment.Center
                                        ) {
                                            if (isSel) {
                                                Icon(
                                                    Icons.Default.Check,
                                                    contentDescription = null,
                                                    tint = Color.White,
                                                    modifier = Modifier.size(18.dp)
                                                )
                                            }
                                        }
                                    }
                                }

                                Spacer(modifier = Modifier.height(14.dp))

                                Text(
                                    "Kies Avatar Emoji (optioneel):",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.sp,
                                    color = Color.White
                                )
                                Spacer(modifier = Modifier.height(8.dp))

                                LazyRow(
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    item {
                                        // Optie Geen emoji
                                        Box(
                                            modifier = Modifier
                                                .size(36.dp)
                                                .clip(RoundedCornerShape(10.dp))
                                                .background(if (selectedEmoji == null) PrimaryBlue.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.05f))
                                                .border(
                                                    width = if (selectedEmoji == null) 2.dp else 1.dp,
                                                    color = if (selectedEmoji == null) PrimaryBlue else Color.White.copy(alpha = 0.1f),
                                                    shape = RoundedCornerShape(10.dp)
                                                )
                                                .clickable { selectedEmoji = null },
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Text("✕", color = Color.White, fontSize = 14.sp)
                                        }
                                    }
                                    items(PresetAvatarEmojis) { emoji ->
                                        val isSel = selectedEmoji == emoji
                                        Box(
                                            modifier = Modifier
                                                .size(36.dp)
                                                .clip(RoundedCornerShape(10.dp))
                                                .background(if (isSel) PrimaryBlue.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.05f))
                                                .border(
                                                    width = if (isSel) 2.dp else 1.dp,
                                                    color = if (isSel) PrimaryBlue else Color.White.copy(alpha = 0.1f),
                                                    shape = RoundedCornerShape(10.dp)
                                                )
                                                .clickable { selectedEmoji = emoji },
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Text(emoji, fontSize = 18.sp)
                                        }
                                    }
                                }

                                Spacer(modifier = Modifier.height(14.dp))

                                Button(
                                    onClick = {
                                        val updated = passport.profile.copy(
                                            colorHex = selectedColor,
                                            avatarEmoji = selectedEmoji
                                        )
                                        scoreManager.savePlayerProfile(updated)
                                        passport = scoreManager.playerPassport(playerName)
                                        isEditingProfile = false
                                    },
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(12.dp),
                                    colors = ButtonDefaults.buttonColors(containerColor = PrimaryBlue)
                                ) {
                                    Text("Opslaan", fontWeight = FontWeight.Bold)
                                }
                            }
                        }
                    }
                }

                // Statistieken Grid
                item {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        StatPillCard(
                            title = "Winstpercentage",
                            value = "${passport.winRate.toInt()}%",
                            subtitle = "${passport.totalWins} uit ${passport.totalGames} gewonnen",
                            modifier = Modifier.weight(1f),
                            accentColor = PrimaryBlue
                        )
                        StatPillCard(
                            title = "Win Streak",
                            value = "${passport.currentStreak} 🔥",
                            subtitle = "Beste: ${passport.bestStreak} op rij",
                            modifier = Modifier.weight(1f),
                            accentColor = Color(0xFFFF9500)
                        )
                    }
                }

                // Spotlight: Angstgegner & Beste Partner
                item {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        // Angstgegner / Aartsvijand
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = CardBackground)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(14.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(40.dp)
                                        .clip(CircleShape)
                                        .background(Color(0xFFE53935).copy(alpha = 0.2f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text("⚔️", fontSize = 20.sp)
                                }
                                Spacer(modifier = Modifier.width(12.dp))
                                Column {
                                    Text(
                                        text = "Aartsvijand (Angstgegner)",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 12.sp,
                                        color = Color(0xFFE53935)
                                    )
                                    if (passport.nemesis != null) {
                                        Text(
                                            text = passport.nemesis!!.first,
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 16.sp,
                                            color = Color.White
                                        )
                                        Text(
                                            text = "Wint ${passport.nemesis!!.second.toInt()}% van jullie onderlinge duels",
                                            fontSize = 11.sp,
                                            color = Color.White.copy(alpha = 0.6f)
                                        )
                                    } else {
                                        Text(
                                            text = "Nog geen aartsvijand 💪",
                                            fontSize = 14.sp,
                                            fontWeight = FontWeight.Medium,
                                            color = Color.White.copy(alpha = 0.8f)
                                        )
                                        Text(
                                            text = "Je domineert al je tegenstanders!",
                                            fontSize = 11.sp,
                                            color = Color.White.copy(alpha = 0.5f)
                                        )
                                    }
                                }
                            }
                        }

                        // Beste Partner
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = CardBackground)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(14.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(40.dp)
                                        .clip(CircleShape)
                                        .background(Color(0xFF43A047).copy(alpha = 0.2f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text("🤝", fontSize = 20.sp)
                                }
                                Spacer(modifier = Modifier.width(12.dp))
                                Column {
                                    Text(
                                        text = "Beste Bondgenoot",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 12.sp,
                                        color = Color(0xFF43A047)
                                    )
                                    if (passport.bestPartner != null) {
                                        Text(
                                            text = passport.bestPartner!!.partnerName,
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 16.sp,
                                            color = Color.White
                                        )
                                        Text(
                                            text = "${passport.bestPartner!!.winsTogether}x gewonnen (${passport.bestPartner!!.winRate.toInt()}% winst)",
                                            fontSize = 11.sp,
                                            color = Color.White.copy(alpha = 0.6f)
                                        )
                                    } else {
                                        Text(
                                            text = "Nog geen teamduo's",
                                            fontSize = 14.sp,
                                            fontWeight = FontWeight.Medium,
                                            color = Color.White.copy(alpha = 0.8f)
                                        )
                                        Text(
                                            text = "Speel 30 Seconds, Cranium of Crokinole 2v2",
                                            fontSize = 11.sp,
                                            color = Color.White.copy(alpha = 0.5f)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                // Favoriet & Beste spel
                item {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Card(
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = CardBackground)
                        ) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                Text(
                                    "🎲 Favoriete Spel",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = Color.White.copy(alpha = 0.6f)
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    passport.favoriteGame?.first ?: "-",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp,
                                    color = Color.White,
                                    maxLines = 1
                                )
                                Text(
                                    passport.favoriteGame?.let { "${it.second}x gespeeld" } ?: "0x gespeeld",
                                    fontSize = 11.sp,
                                    color = Color.White.copy(alpha = 0.5f)
                                )
                            }
                        }

                        Card(
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = CardBackground)
                        ) {
                            Column(modifier = Modifier.padding(12.dp)) {
                                Text(
                                    "🥇 Beste Spel",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = Color.White.copy(alpha = 0.6f)
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    passport.bestGame?.first ?: "-",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp,
                                    color = Color.White,
                                    maxLines = 1
                                )
                                Text(
                                    passport.bestGame?.let { "${it.second.toInt()}% winst" } ?: "0% winst",
                                    fontSize = 11.sp,
                                    color = PrimaryBlue
                                )
                            }
                        }
                    }
                }

                // Badges sectie
                item {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                "Bordspel Badges",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                            val unlockedCount = passport.badges.count { it.isUnlocked }
                            Text(
                                "$unlockedCount / ${passport.badges.size} Vrijgespeeld",
                                fontSize = 12.sp,
                                color = Color.White.copy(alpha = 0.6f),
                                fontWeight = FontWeight.SemiBold
                            )
                        }

                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            passport.badges.forEach { badge ->
                                BadgeRow(badge = badge)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun StatPillCard(
    title: String,
    value: String,
    subtitle: String,
    modifier: Modifier = Modifier,
    accentColor: Color
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = CardBackground)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                title,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.White.copy(alpha = 0.6f)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                value,
                fontWeight = FontWeight.Bold,
                fontSize = 22.sp,
                color = accentColor
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                subtitle,
                fontSize = 10.sp,
                color = Color.White.copy(alpha = 0.5f),
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun BadgeRow(badge: PlayerBadge) {
    val isUnlocked = badge.isUnlocked
    val iconBg = if (isUnlocked) Color(badge.colorHex).copy(alpha = 0.2f) else Color.White.copy(alpha = 0.05f)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(if (isUnlocked) CardBackground else Color.White.copy(alpha = 0.03f))
            .border(
                1.dp,
                if (isUnlocked) Color.White.copy(alpha = 0.08f) else Color.White.copy(alpha = 0.03f),
                RoundedCornerShape(12.dp)
            )
            .padding(10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(38.dp)
                .clip(CircleShape)
                .background(iconBg),
            contentAlignment = Alignment.Center
        ) {
            if (isUnlocked) {
                Text(badge.iconName, fontSize = 18.sp)
            } else {
                Icon(
                    Icons.Default.Lock,
                    contentDescription = "Vergrendeld",
                    tint = Color.White.copy(alpha = 0.3f),
                    modifier = Modifier.size(16.dp)
                )
            }
        }

        Spacer(modifier = Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    badge.title,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                    color = if (isUnlocked) Color.White else Color.White.copy(alpha = 0.4f)
                )
                if (isUnlocked) {
                    Spacer(modifier = Modifier.width(6.dp))
                    Icon(
                        Icons.Default.CheckCircle,
                        contentDescription = "Behaald",
                        tint = Color(0xFF43A047),
                        modifier = Modifier.size(14.dp)
                    )
                }
            }
            Text(
                badge.subtitle,
                fontSize = 11.sp,
                color = if (isUnlocked) Color.White.copy(alpha = 0.6f) else Color.White.copy(alpha = 0.3f)
            )
        }
    }
}
