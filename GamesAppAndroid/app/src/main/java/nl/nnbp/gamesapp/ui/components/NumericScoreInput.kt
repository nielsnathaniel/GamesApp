package nl.nnbp.gamesapp.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import nl.nnbp.gamesapp.ui.theme.PrimaryBlue

@Composable
fun NumericScoreStepper(
    score: Int,
    onScoreChange: (Int) -> Unit,
    modifier: Modifier = Modifier,
    enableLargeStep: Boolean = true
) {
    var showDirectInputDialog by remember { mutableStateOf(false) }
    var textInput by remember { mutableStateOf(score.toString()) }

    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        if (enableLargeStep) {
            FilledTonalButton(
                onClick = { onScoreChange(score - 10) },
                contentPadding = PaddingValues(0.dp),
                modifier = Modifier.size(36.dp),
                shape = CircleShape
            ) {
                Text("-10", fontSize = 11.sp, fontWeight = FontWeight.Bold)
            }
        }

        FilledTonalButton(
            onClick = { onScoreChange(score - 1) },
            contentPadding = PaddingValues(0.dp),
            modifier = Modifier.size(36.dp),
            shape = CircleShape
        ) {
            Text("-1", fontSize = 13.sp, fontWeight = FontWeight.Bold)
        }

        Box(
            modifier = Modifier
                .width(64.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant)
                .clickable {
                    textInput = score.toString()
                    showDirectInputDialog = true
                }
                .padding(vertical = 8.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = score.toString(),
                style = MaterialTheme.typography.titleMedium.copy(fontSize = 18.sp, fontWeight = FontWeight.Bold),
                textAlign = TextAlign.Center
            )
        }

        FilledTonalButton(
            onClick = { onScoreChange(score + 1) },
            contentPadding = PaddingValues(0.dp),
            modifier = Modifier.size(36.dp),
            shape = CircleShape
        ) {
            Text("+1", fontSize = 13.sp, fontWeight = FontWeight.Bold)
        }

        if (enableLargeStep) {
            FilledTonalButton(
                onClick = { onScoreChange(score + 10) },
                contentPadding = PaddingValues(0.dp),
                modifier = Modifier.size(36.dp),
                shape = CircleShape
            ) {
                Text("+10", fontSize = 11.sp, fontWeight = FontWeight.Bold)
            }
        }
    }

    if (showDirectInputDialog) {
        AlertDialog(
            onDismissRequest = { showDirectInputDialog = false },
            title = { Text("Score direct invoeren") },
            text = {
                OutlinedTextField(
                    value = textInput,
                    onValueChange = { textInput = it },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        val parsed = textInput.toIntOrNull()
                        if (parsed != null) {
                            onScoreChange(parsed)
                        }
                        showDirectInputDialog = false
                    }
                ) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDirectInputDialog = false }) {
                    Text("Annuleren")
                }
            }
        )
    }
}
