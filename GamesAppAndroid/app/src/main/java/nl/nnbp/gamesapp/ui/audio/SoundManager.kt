package nl.nnbp.gamesapp.ui.audio

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class SoundManager private constructor(context: Context) {

    private val prefs = context.getSharedPreferences("GamesAppAudioPrefs", Context.MODE_PRIVATE)
    private val scope = CoroutineScope(Dispatchers.Default)

    private var toneGenerator: ToneGenerator? = null

    init {
        try {
            toneGenerator = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 85)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    var isSoundEnabled: Boolean
        get() = prefs.getBoolean("sound_effects_enabled", true)
        set(value) {
            prefs.edit().putBoolean("sound_effects_enabled", value).apply()
        }

    fun playTick() {
        if (!isSoundEnabled) return
        try {
            toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 50)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun playUrgentTick() {
        if (!isSoundEnabled) return
        try {
            toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP2, 90)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun playBuzzer() {
        if (!isSoundEnabled) return
        scope.launch {
            try {
                toneGenerator?.startTone(ToneGenerator.TONE_CDMA_HIGH_L, 350)
                delay(380)
                toneGenerator?.startTone(ToneGenerator.TONE_CDMA_HIGH_L, 450)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun playBalzakSuccess() {
        if (!isSoundEnabled) return
        scope.launch {
            try {
                // Feestelijk stijgend akkoordje
                toneGenerator?.startTone(ToneGenerator.TONE_PROP_PROMPT, 120)
                delay(130)
                toneGenerator?.startTone(ToneGenerator.TONE_PROP_ACK, 180)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun playBalzakFail() {
        if (!isSoundEnabled) return
        scope.launch {
            try {
                toneGenerator?.startTone(ToneGenerator.TONE_SUP_ERROR, 280)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun playFanfare() {
        if (!isSoundEnabled) return
        scope.launch {
            try {
                // Fanfare / overwinningsmelodie
                toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 100)
                delay(120)
                toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 100)
                delay(120)
                toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 100)
                delay(140)
                toneGenerator?.startTone(ToneGenerator.TONE_PROP_ACK, 350)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun playDiceRoll() {
        if (!isSoundEnabled) return
        scope.launch {
            try {
                repeat(4) {
                    toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 30)
                    delay(55)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    companion object {
        @Volatile
        private var INSTANCE: SoundManager? = null

        fun initialize(context: Context): SoundManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: SoundManager(context.applicationContext).also { INSTANCE = it }
            }
        }

        fun getInstance(): SoundManager {
            return INSTANCE ?: throw IllegalStateException("SoundManager must be initialized in Application.onCreate")
        }
    }
}
