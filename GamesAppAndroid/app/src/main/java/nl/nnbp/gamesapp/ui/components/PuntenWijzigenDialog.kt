package nl.nnbp.gamesapp.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.ui.theme.AccentOrange
import nl.nnbp.gamesapp.ui.theme.CardBackgroundDark
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue
import nl.nnbp.gamesapp.ui.theme.SuccessGreen
import nl.nnbp.gamesapp.ui.theme.SurfaceDark

@Composable
fun PuntenWijzigenDialog(
    playerNames: List<String>,
    currentScores: List<Int>,
    title: String = "Punten Wijzigen",
    subtitle: String = "Pas de stand direct aan door een getal in te typen of de knoppen te gebruiken.",
    isLowestScoreWins: Boolean = false,
    onDismiss: () -> Unit,
    onSave: (List<Int>) -> Unit
) {
    val scoreManager = remember { ScoreManager.getInstance() }
    val focusManager = LocalFocusManager.current

    var modifiedScores by remember(currentScores) {
        mutableStateOf(currentScores.toMutableList())
    }
    var scoreTexts by remember(currentScores) {
        mutableStateOf(currentScores.map { it.toString() }.toMutableList())
    }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 16.dp),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = SurfaceDark)
        ) {
            Column(
                modifier = Modifier
                    .padding(20.dp)
                    .fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(AccentOrange.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Edit,
                                contentDescription = null,
                                tint = AccentOrange,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                        Column {
                            Text(
                                text = title,
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                            Text(
                                text = "Direct scores aanpassen",
                                style = MaterialTheme.typography.bodySmall,
                                color = Color.White.copy(alpha = 0.6f)
                            )
                        }
                    }
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Sluiten", tint = Color.White)
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Spelers lijst
                LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f, fill = false)
                        .heightIn(max = 380.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    itemsIndexed(playerNames) { idx, name ->
                        val profile = scoreManager.getPlayerProfile(name)
                        val playerColor = Color(profile.colorHex)
                        val original = currentScores.getOrElse(idx) { 0 }
                        val current = modifiedScores.getOrElse(idx) { original }
                        val diff = current - original
                        val currentText = scoreTexts.getOrElse(idx) { original.toString() }

                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = CardBackgroundDark)
                        ) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp)
                            ) {
                                // Regel 1: Avatar, Naam en Verschil
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                                    ) {
                                        Box(
                                            modifier = Modifier
                                                .size(36.dp)
                                                .clip(CircleShape)
                                                .background(playerColor),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            if (profile.avatarEmoji != null) {
                                                Text(profile.avatarEmoji, fontSize = 18.sp)
                                            } else {
                                                Text(
                                                    name.take(1).uppercase(),
                                                    color = Color.White,
                                                    fontWeight = FontWeight.Bold,
                                                    fontSize = 15.sp
                                                )
                                            }
                                        }

                                        Column {
                                            Text(
                                                text = name,
                                                fontWeight = FontWeight.Bold,
                                                color = Color.White,
                                                fontSize = 16.sp
                                            )
                                            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                                Text(
                                                    text = "Oud: $original",
                                                    style = MaterialTheme.typography.bodySmall,
                                                    color = Color.White.copy(alpha = 0.5f)
                                                )
                                                if (diff != 0) {
                                                    val isPositiveGood = !isLowestScoreWins
                                                    val isGood = if (isPositiveGood) diff > 0 else diff < 0
                                                    val diffColor = if (isGood) SuccessGreen else AccentOrange
                                                    Text(
                                                        text = if (diff > 0) "(+$diff)" else "($diff)",
                                                        style = MaterialTheme.typography.bodySmall,
                                                        fontWeight = FontWeight.Bold,
                                                        color = diffColor
                                                    )
                                                }
                                            }
                                        }
                                    }

                                    // Score invoerveld
                                    OutlinedTextField(
                                        value = currentText,
                                        onValueChange = { newText ->
                                            val newTexts = scoreTexts.toMutableList()
                                            if (idx < newTexts.size) {
                                                newTexts[idx] = newText
                                                scoreTexts = newTexts
                                                newText.toIntOrNull()?.let { parsed ->
                                                    val newScores = modifiedScores.toMutableList()
                                                    if (idx < newScores.size) {
                                                        newScores[idx] = parsed
                                                        modifiedScores = newScores
                                                    }
                                                }
                                            }
                                        },
                                        keyboardOptions = KeyboardOptions(
                                            keyboardType = KeyboardType.Number,
                                            imeAction = ImeAction.Done
                                        ),
                                        keyboardActions = KeyboardActions(
                                            onDone = { focusManager.clearFocus() }
                                        ),
                                        singleLine = true,
                                        textStyle = LocalTextStyle.current.copy(
                                            fontSize = 18.sp,
                                            fontWeight = FontWeight.Bold,
                                            textAlign = TextAlign.Center,
                                            color = Color.White
                                        ),
                                        modifier = Modifier.width(90.dp),
                                        shape = RoundedCornerShape(10.dp)
                                    )
                                }

                                Spacer(modifier = Modifier.height(10.dp))

                                // Regel 2: Snelle +/- stelknoppen
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.End,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    val stepModifier = Modifier
                                        .size(width = 46.dp, height = 34.dp)
                                        .padding(horizontal = 2.dp)

                                    val applyDelta: (Int) -> Unit = { delta ->
                                        val cur = scoreTexts.getOrNull(idx)?.toIntOrNull()
                                            ?: modifiedScores.getOrElse(idx) { original }
                                        val updated = cur + delta
                                        val newScores = modifiedScores.toMutableList()
                                        if (idx < newScores.size) newScores[idx] = updated
                                        modifiedScores = newScores

                                        val newTexts = scoreTexts.toMutableList()
                                        if (idx < newTexts.size) newTexts[idx] = updated.toString()
                                        scoreTexts = newTexts
                                    }

                                    FilledTonalButton(
                                        onClick = { applyDelta(-10) },
                                        contentPadding = PaddingValues(0.dp),
                                        modifier = stepModifier,
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text("-10", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                    }

                                    FilledTonalButton(
                                        onClick = { applyDelta(-1) },
                                        contentPadding = PaddingValues(0.dp),
                                        modifier = stepModifier,
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text("-1", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                                    }

                                    FilledTonalButton(
                                        onClick = { applyDelta(1) },
                                        contentPadding = PaddingValues(0.dp),
                                        modifier = stepModifier,
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text("+1", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                                    }

                                    FilledTonalButton(
                                        onClick = { applyDelta(10) },
                                        contentPadding = PaddingValues(0.dp),
                                        modifier = stepModifier,
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text("+10", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Herstelknop
                TextButton(
                    onClick = {
                        focusManager.clearFocus()
                        modifiedScores = currentScores.toMutableList()
                        scoreTexts = currentScores.map { it.toString() }.toMutableList()
                    }
                ) {
                    Icon(
                        imageVector = Icons.Default.Refresh,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = Color.White.copy(alpha = 0.7f)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        "Herstel naar originele waarden",
                        color = Color.White.copy(alpha = 0.7f),
                        fontSize = 13.sp
                    )
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Actieknoppen
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text("Annuleren", color = Color.White)
                    }

                    Button(
                        onClick = {
                            focusManager.clearFocus()
                            val finalScores = playerNames.indices.map { i ->
                                scoreTexts.getOrNull(i)?.toIntOrNull()
                                    ?: modifiedScores.getOrElse(i) { currentScores.getOrElse(i) { 0 } }
                            }
                            onSave(finalScores)
                            onDismiss()
                        },
                        modifier = Modifier
                            .weight(1.3f)
                            .height(48.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = AccentOrange),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text("Wijzigingen Opslaan", fontWeight = FontWeight.Bold, color = Color.White)
                    }
                }
            }
        }
    }
}
