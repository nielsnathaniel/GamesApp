package nl.nnbp.gamesapp.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.rotate
import kotlinx.coroutines.delay
import kotlin.math.sin
import kotlin.random.Random

private val ConfettiColors = listOf(
    Color(0xFFFFD700), // Goud
    Color(0xFFFFC107), // Amber Goud
    Color(0xFFECEFF1), // Zilver
    Color(0xFFFF5252), // Feestelijk Rood
    Color(0xFF40C4FF), // Koningsblauw
    Color(0xFF69F0AE), // Smaragdgroen
    Color(0xFFE040FB), // Fuchsia / Paars
    Color(0xFFFFAB40)  // Oranje
)

private enum class ConfettiShape { RECT, CIRCLE, RIBBON }

private class ConfettiParticle(
    var x: Float,
    var y: Float,
    var vx: Float,
    var vy: Float,
    val size: Float,
    val color: Color,
    val shape: ConfettiShape,
    var rotation: Float,
    val rotationSpeed: Float,
    val wobbleSpeed: Float,
    var wobble: Float = 0f
)

@Composable
fun ConfettiEffect(
    modifier: Modifier = Modifier,
    particleCount: Int = 70
) {
    var frameTime by remember { mutableLongStateOf(0L) }

    val particles = remember {
        List(particleCount) {
            ConfettiParticle(
                x = Random.nextFloat(),
                y = Random.nextFloat() * -1000f - 50f,
                vx = (Random.nextFloat() - 0.5f) * 2f,
                vy = Random.nextFloat() * 5f + 4f,
                size = Random.nextFloat() * 10f + 8f,
                color = ConfettiColors.random(),
                shape = ConfettiShape.entries.random(),
                rotation = Random.nextFloat() * 360f,
                rotationSpeed = (Random.nextFloat() - 0.5f) * 12f,
                wobbleSpeed = Random.nextFloat() * 0.08f + 0.03f
            )
        }
    }

    LaunchedEffect(Unit) {
        while (true) {
            delay(16)
            frameTime += 16
        }
    }

    Canvas(modifier = modifier.fillMaxSize()) {
        val width = size.width
        val height = size.height

        particles.forEach { p ->
            // Physics update
            p.wobble += p.wobbleSpeed
            val currentX = (p.x * width) + (sin(p.wobble) * 25f)
            p.y += p.vy
            p.rotation += p.rotationSpeed

            // Reset als deeltje onderaan verdwijnt
            if (p.y > height + 50f) {
                p.y = -50f
                p.x = Random.nextFloat()
            }

            val px = currentX
            val py = p.y

            rotate(degrees = p.rotation, pivot = Offset(px, py)) {
                when (p.shape) {
                    ConfettiShape.CIRCLE -> {
                        drawCircle(
                            color = p.color,
                            radius = p.size / 2f,
                            center = Offset(px, py)
                        )
                    }
                    ConfettiShape.RECT -> {
                        drawRect(
                            color = p.color,
                            topLeft = Offset(px - p.size / 2f, py - p.size / 3f),
                            size = Size(p.size, p.size * 0.7f)
                        )
                    }
                    ConfettiShape.RIBBON -> {
                        drawRect(
                            color = p.color,
                            topLeft = Offset(px - p.size / 4f, py - p.size),
                            size = Size(p.size * 0.4f, p.size * 1.8f)
                        )
                    }
                }
            }
        }
    }
}
