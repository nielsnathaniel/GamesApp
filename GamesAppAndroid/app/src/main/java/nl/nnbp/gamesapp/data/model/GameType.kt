package nl.nnbp.gamesapp.data.model

enum class GameType(
    val id: String,
    val displayName: String,
    val isLowestScoreWins: Boolean,
    val minPlayers: Int,
    val maxPlayers: Int,
    val description: String,
    val iconName: String
) {
    NMBR9(
        id = "Nmbr9",
        displayName = "Nmbr9",
        isLowestScoreWins = false,
        minPlayers = 1,
        maxPlayers = 6,
        description = "Puzzel- en cijferspel met lagenvermenigvuldigers",
        iconName = "extension"
    ),
    BEVERBENDE(
        id = "Beverbende",
        displayName = "Beverbende",
        isLowestScoreWins = true,
        minPlayers = 2,
        maxPlayers = 6,
        description = "Tactisch kaartspel waarbij de laagste score wint",
        iconName = "pets"
    ),
    DUIZENDEN(
        id = "Duizenden",
        displayName = "Duizenden",
        isLowestScoreWins = false,
        minPlayers = 2,
        maxPlayers = 6,
        description = "Klassiek kaartspel met melds, slagen en minpunten",
        iconName = "style"
    ),
    CROCKINOLE(
        id = "Crockinole",
        displayName = "Crockinole",
        isLowestScoreWins = false,
        minPlayers = 2,
        maxPlayers = 4,
        description = "Traditioneel schijvenspel met 20-gaten en differentieel verloop",
        iconName = "radio_button_checked"
    ),
    REGENWORMEN(
        id = "Regenwormen",
        displayName = "Regenwormen",
        isLowestScoreWins = false,
        minPlayers = 2,
        maxPlayers = 7,
        description = "Spannend dobbelspel rondom stenen en wormen",
        iconName = "bug_report"
    ),
    JATTEN(
        id = "Jatten",
        displayName = "Jatten",
        isLowestScoreWins = false,
        minPlayers = 2,
        maxPlayers = 6,
        description = "Kaartspel met push-your-luck. Als eerste 6 dezelfde wint!",
        iconName = "pan_tool"
    ),
    BALZAKKEN(
        id = "Balzakken",
        displayName = "Balzakken",
        isLowestScoreWins = true,
        minPlayers = 2,
        maxPlayers = 8,
        description = "Kaartspel met 69 en 99 straffen, Valse Balzak en Balzak!",
        iconName = "sports_baseball"
    ),
    LOVE_LETTER(
        id = "Love Letter",
        displayName = "Love Letter",
        isLowestScoreWins = false,
        minPlayers = 2,
        maxPlayers = 6,
        description = "Deductiekaartspel vol geheimen en tactiek",
        iconName = "favorite"
    ),
    QWIXX(
        id = "Qwixx",
        displayName = "Qwixx",
        isLowestScoreWins = false,
        minPlayers = 2,
        maxPlayers = 5,
        description = "Dobbelspel met 4 kleurrijen en misworpen",
        iconName = "casino"
    ),
    PIG_HOLE(
        id = "Pig Hole",
        displayName = "Pig Hole",
        isLowestScoreWins = true,
        minPlayers = 2,
        maxPlayers = 6,
        description = "Het varkensgat: raak als eerste al je varkentjes kwijt!",
        iconName = "savings"
    ),
    TICKET_TO_RIDE(
        id = "Ticket to Ride",
        displayName = "Ticket to Ride",
        isLowestScoreWins = false,
        minPlayers = 2,
        maxPlayers = 5,
        description = "Bordspel met routes, treinkleuren en bestemmingskaarten",
        iconName = "train"
    ),
    QUICKSTOP(
        id = "Quickstop",
        displayName = "Quickstop",
        isLowestScoreWins = true,
        minPlayers = 2,
        maxPlayers = 7,
        description = "Razendsnel partyspel: roep woorden en ontwijk bliksems",
        iconName = "flash_on"
    ),
    THIRTY_SECONDS(
        id = "30 Seconds",
        displayName = "30 Seconds",
        isLowestScoreWins = false,
        minPlayers = 4,
        maxPlayers = 12,
        description = "Razendsnel partyspel in teams met 30-seconden timer",
        iconName = "timer"
    ),
    CRANIUM(
        id = "Cranium",
        displayName = "Cranium",
        isLowestScoreWins = false,
        minPlayers = 4,
        maxPlayers = 16,
        description = "Vier categorieën creativiteit en breinbrekers voor teams",
        iconName = "psychology"
    ),
    FIFTY_FIFTY(
        id = "Fifty Fifty",
        displayName = "Fifty Fifty",
        isLowestScoreWins = true,
        minPlayers = 2,
        maxPlayers = 6,
        description = "White Goblin kaartspel: ontwijk strafkaarten en de vos!",
        iconName = "layers"
    );

    companion object {
        fun fromId(id: String): GameType? {
            return entries.firstOrNull { it.id.equals(id, ignoreCase = true) }
        }
    }
}
