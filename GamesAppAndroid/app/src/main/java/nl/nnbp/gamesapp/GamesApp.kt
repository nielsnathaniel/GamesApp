package nl.nnbp.gamesapp

import android.app.Application
import nl.nnbp.gamesapp.data.ActiveGameManager
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.ui.audio.SoundManager

class GamesApp : Application() {
    override fun onCreate() {
        super.onCreate()
        ScoreManager.initialize(this)
        ActiveGameManager.initialize(this)
        SoundManager.initialize(this)
    }
}
