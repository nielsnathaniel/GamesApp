package nl.nnbp.gamesapp.data

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import nl.nnbp.gamesapp.data.model.ActiveGameSession

class ActiveGameManager private constructor(context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences("GamesAppPrefs", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true; isLenient = true; encodeDefaults = true }
    private val storageKey = "gamesapp_active_game_draft"

    private val _activeSession = MutableStateFlow<ActiveGameSession?>(null)
    val activeSession: StateFlow<ActiveGameSession?> = _activeSession.asStateFlow()

    init {
        _activeSession.value = loadFromDisk()
    }

    val hasActiveSession: Boolean
        get() = _activeSession.value != null

    fun saveActiveGame(
        gameName: String,
        playerNames: List<String>,
        currentRound: Int,
        summary: String,
        state: Map<String, String> = emptyMap()
    ) {
        val current = _activeSession.value
        val startedAt = if (current?.gameName == gameName) current.timestamp else System.currentTimeMillis()

        val session = ActiveGameSession(
            gameName = gameName,
            timestamp = startedAt,
            playerNames = playerNames,
            currentRound = currentRound,
            summary = summary,
            stateData = state
        )

        _activeSession.value = session
        persistToDisk(session)
    }

    fun clearActiveGame() {
        _activeSession.value = null
        prefs.edit().remove(storageKey).apply()
    }

    private fun persistToDisk(session: ActiveGameSession) {
        try {
            val str = json.encodeToString(session)
            prefs.edit().putString(storageKey, str).apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun loadFromDisk(): ActiveGameSession? {
        val raw = prefs.getString(storageKey, null) ?: return null
        return try {
            json.decodeFromString<ActiveGameSession>(raw)
        } catch (e: Exception) {
            null
        }
    }

    companion object {
        @Volatile
        private var INSTANCE: ActiveGameManager? = null

        fun initialize(context: Context): ActiveGameManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: ActiveGameManager(context.applicationContext).also { INSTANCE = it }
            }
        }

        fun getInstance(): ActiveGameManager {
            return INSTANCE ?: throw IllegalStateException("ActiveGameManager must be initialized in Application.onCreate")
        }
    }
}
