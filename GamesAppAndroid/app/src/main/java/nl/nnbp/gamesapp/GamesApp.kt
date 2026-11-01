package nl.nnbp.gamesapp

import android.app.Application
import nl.nnbp.gamesapp.data.ActiveGameManager
import nl.nnbp.gamesapp.data.ScoreManager
import nl.nnbp.gamesapp.ui.audio.SoundManager

class GamesApp : Application() {
    override fun onCreate() {
        super.onCreate()
        try {
            ScoreManager.initialize(this)
        } catch (e: Throwable) {
            e.printStackTrace()
        }
        try {
            ActiveGameManager.initialize(this)
        } catch (e: Throwable) {
            e.printStackTrace()
        }
        try {
            SoundManager.initialize(this)
        } catch (e: Throwable) {
            e.printStackTrace()
        }
    }
}
