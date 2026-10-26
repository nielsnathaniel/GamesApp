package nl.nnbp.gamesapp.data.model

data class TeamStat(
    val teamKey: String,
    val displayName: String,
    val playerNames: List<String>,
    val played: Int,
    val won: Int,
    val totalScore: Int
) {
    val winRate: Double
        get() = if (played > 0) (won.toDouble() / played.toDouble()) * 100.0 else 0.0
}

data class PartnerSynergyStat(
    val partnerName: String,
    val gamesTogether: Int,
    val winsTogether: Int,
    val lossesTogether: Int
) {
    val winRate: Double
        get() = if (gamesTogether > 0) (winsTogether.toDouble() / gamesTogether.toDouble()) * 100.0 else 0.0
}

data class HeadToHeadRecord(
    val playerA: String,
    val playerB: String,
    val winsA: Int,
    val winsB: Int,
    val ties: Int,
    val totalGames: Int
) {
    val leaderSummary: String
        get() = when {
            winsA > winsB -> "$playerA leidt ($winsA-$winsB)"
            winsB > winsA -> "$playerB leidt ($winsB-$winsA)"
            else -> "Gelijke stand ($winsA-$winsB)"
        }
}

data class PlayerBadge(
    val title: String,
    val subtitle: String,
    val iconName: String,
    val colorHex: Long,
    val isUnlocked: Boolean = true
)

data class GamePlayerStat(
    val gameName: String,
    val played: Int,
    val won: Int,
    val bestScore: Int?
) {
    val winRate: Double
        get() = if (played > 0) (won.toDouble() / played.toDouble()) * 100.0 else 0.0
}

data class DetailedPlayerStats(
    val playerName: String,
    val totalGames: Int,
    val totalWins: Int,
    val statsPerGame: List<GamePlayerStat>
) {
    val winRate: Double
        get() = if (totalGames > 0) (totalWins.toDouble() / totalGames.toDouble()) * 100.0 else 0.0
}

data class BalzakkenPlayerStat(
    val playerName: String,
    val juisteBalzakken: Int,
    val fouteBalzakken: Int,
    val gamesPlayed: Int
)

data class GameSpecificPlayerStat(
    val playerName: String,
    val gamesPlayed: Int,
    val gamesWon: Int,
    val bestScore: Int?,
    val averageScore: Double?
) {
    val winRate: Double
        get() = if (gamesPlayed > 0) (gamesWon.toDouble() / gamesPlayed.toDouble()) * 100.0 else 0.0
}
