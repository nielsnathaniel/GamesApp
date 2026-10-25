import Foundation
import SwiftUI

struct PlayerScore: Identifiable, Codable {
    var id: UUID = UUID()
    let playerName: String
    let score: Int
    let isWinner: Bool
    var juisteBalzakken: Int? = 0
    var fouteBalzakken: Int? = 0

    enum CodingKeys: String, CodingKey {
        case id, playerName, score, isWinner, juisteBalzakken, fouteBalzakken
    }

    init(id: UUID = UUID(), playerName: String, score: Int, isWinner: Bool, juisteBalzakken: Int? = 0, fouteBalzakken: Int? = 0) {
        self.id = id
        self.playerName = playerName
        self.score = score
        self.isWinner = isWinner
        self.juisteBalzakken = juisteBalzakken ?? 0
        self.fouteBalzakken = fouteBalzakken ?? 0
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.playerName = try container.decode(String.self, forKey: .playerName)
        self.score = try container.decode(Int.self, forKey: .score)
        self.isWinner = try container.decode(Bool.self, forKey: .isWinner)
        self.juisteBalzakken = try container.decodeIfPresent(Int.self, forKey: .juisteBalzakken) ?? 0
        self.fouteBalzakken = try container.decodeIfPresent(Int.self, forKey: .fouteBalzakken) ?? 0
    }
}

struct GameTeam: Identifiable, Codable {
    var id: UUID = UUID()
    let teamName: String
    let playerNames: [String]
    let score: Int
    let isWinner: Bool

    enum CodingKeys: String, CodingKey {
        case id, teamName, playerNames, score, isWinner
    }

    init(id: UUID = UUID(), teamName: String, playerNames: [String], score: Int, isWinner: Bool) {
        self.id = id
        self.teamName = teamName
        self.playerNames = playerNames
        self.score = score
        self.isWinner = isWinner
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.teamName = try container.decode(String.self, forKey: .teamName)
        self.playerNames = try container.decode([String].self, forKey: .playerNames)
        self.score = try container.decode(Int.self, forKey: .score)
        self.isWinner = try container.decode(Bool.self, forKey: .isWinner)
    }
}

struct PlayedGame: Identifiable, Codable {
    var id: UUID = UUID()
    let date: Date
    let gameName: String
    let scores: [PlayerScore]
    let winner: String
    var teams: [GameTeam]? = nil

    enum CodingKeys: String, CodingKey {
        case id, date, gameName, scores, winner, teams
    }

    init(id: UUID = UUID(), date: Date, gameName: String, scores: [PlayerScore], winner: String, teams: [GameTeam]? = nil) {
        self.id = id
        self.date = date
        self.gameName = gameName
        self.scores = scores
        self.winner = winner
        self.teams = teams
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.date = try container.decode(Date.self, forKey: .date)
        self.gameName = try container.decode(String.self, forKey: .gameName)
        self.scores = try container.decode([PlayerScore].self, forKey: .scores)
        self.winner = try container.decode(String.self, forKey: .winner)
        self.teams = try container.decodeIfPresent([GameTeam].self, forKey: .teams)
    }
}

extension PlayedGame {
    var isTie: Bool {
        return winner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var playerNamesList: [String] {
        if let teams = teams, !teams.isEmpty {
            return teams.flatMap { $0.playerNames }
        }
        return scores.map { $0.playerName }
    }

    var playersDescription: String {
        let names = playerNamesList
        if names.isEmpty { return "" }
        if names.count == 1 { return names[0] }
        if names.count == 2 { return "\(names[0]) & \(names[1])" }
        let head = names.dropLast().joined(separator: ", ")
        return "\(head) & \(names.last!)"
    }

    var sessionTitle: String {
        let players = playersDescription
        if players.isEmpty {
            return "Spelsessie \(gameName)"
        }
        return "Spelsessie \(gameName) met \(players)"
    }
}

struct TeamStat: Identifiable {
    var id: String { teamKey }
    let teamKey: String
    let displayName: String
    let playerNames: [String]
    let played: Int
    let won: Int
    let totalScore: Int
    var winRate: Double {
        played > 0 ? (Double(won) / Double(played)) * 100.0 : 0.0
    }
}

struct PartnerSynergyStat: Identifiable {
    var id: String { partnerName }
    let partnerName: String
    let gamesTogether: Int
    let winsTogether: Int
    let lossesTogether: Int
    var winRate: Double {
        gamesTogether > 0 ? (Double(winsTogether) / Double(gamesTogether)) * 100.0 : 0.0
    }
}

struct Score: Identifiable, Codable {
    var id: UUID = UUID()
    let date: Date
    let gameName: String
    let playerName: String
    let score: Int
    let isWinner: Bool
}

struct HeadToHeadRecord: Identifiable {
    var id: String { "\(playerA)_vs_\(playerB)" }
    let playerA: String
    let playerB: String
    let winsA: Int
    let winsB: Int
    let ties: Int
    let totalGames: Int

    var leaderSummary: String {
        if winsA > winsB {
            return "\(playerA) leidt (\(winsA)-\(winsB))"
        } else if winsB > winsA {
            return "\(playerB) leidt (\(winsB)-\(winsA))"
        } else {
            return "Gelijke stand (\(winsA)-\(winsB))"
        }
    }
}

struct PlayerBadge: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

struct GamePlayerStat: Identifiable {
    var id: String { gameName }
    let gameName: String
    let played: Int
    let won: Int
    let bestScore: Int?
    var winRate: Double {
        played > 0 ? (Double(won) / Double(played)) * 100.0 : 0.0
    }
}

struct DetailedPlayerStats: Identifiable {
    var id: String { playerName }
    let playerName: String
    let totalGames: Int
    let totalWins: Int
    var winRate: Double {
        totalGames > 0 ? (Double(totalWins) / Double(totalGames)) * 100.0 : 0.0
    }
    let statsPerGame: [GamePlayerStat]
}

struct BalzakkenPlayerStat: Identifiable {
    var id: String { playerName }
    let playerName: String
    let juisteBalzakken: Int
    let fouteBalzakken: Int
    let gamesPlayed: Int
}

struct GameSpecificPlayerStat: Identifiable {
    var id: String { playerName }
    let playerName: String
    let gamesPlayed: Int
    let gamesWon: Int
    var winRate: Double {
        gamesPlayed > 0 ? (Double(gamesWon) / Double(gamesPlayed)) * 100.0 : 0.0
    }
    let bestScore: Int?
    let averageScore: Double?
}

class ScoreManager: ObservableObject {
    static let shared = ScoreManager()

    private let scoresKey = "saved_game_scores"
    private let gamesKey = "saved_played_games"
    private let playersKey = "saved_player_names"

    @Published var scores: [Score] = []
    @Published var playedGames: [PlayedGame] = []
    @Published var savedPlayerNames: [String] = []

    init() {
        refresh()
    }

    func refresh() {
        scores = fetchScores()
        playedGames = fetchGames()
        savedPlayerNames = fetchPlayerNames()
    }

    // MARK: - Spelersbeheer (Automatisch opslaan & Hergebruiken)

    /// Geeft het totale aantal gespeelde potjes van een speler terug (voor populariteitssortering)
    func playerPlayCount(for playerName: String) -> Int {
        let gamesSource = playedGames.isEmpty ? fetchGames() : playedGames
        let target = playerName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !target.isEmpty else { return 0 }

        var count = 0
        for game in gamesSource {
            let inScores = game.scores.contains { $0.playerName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == target }
            let inTeams = game.teams?.contains { team in
                team.playerNames.contains { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == target }
            } ?? false

            if inScores || inTeams {
                count += 1
            }
        }
        return count
    }

    /// Sorteert spelers op populariteit: spelers die het vaakst spelen staan vooraan.
    /// Bij een gelijke stand aan gespeelde potjes wordt alfabetisch gesorteerd.
    func sortPlayersByPopularity(_ names: [String]) -> [String] {
        let gamesSource = playedGames.isEmpty ? fetchGames() : playedGames

        var countMap: [String: Int] = [:]
        for game in gamesSource {
            var countedForGame = Set<String>()
            for s in game.scores {
                let norm = s.playerName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if !norm.isEmpty { countedForGame.insert(norm) }
            }
            if let teams = game.teams {
                for team in teams {
                    for p in team.playerNames {
                        let norm = p.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        if !norm.isEmpty { countedForGame.insert(norm) }
                    }
                }
            }
            for norm in countedForGame {
                countMap[norm, default: 0] += 1
            }
        }

        return names.sorted { a, b in
            let countA = countMap[a.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] ?? 0
            let countB = countMap[b.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] ?? 0

            if countA != countB {
                return countA > countB
            }
            return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
        }
    }

    func fetchPlayerNames() -> [String] {
        if let data = UserDefaults.standard.stringArray(forKey: playersKey) {
            return sortPlayersByPopularity(data)
        }

        // Alleen bij allereerste keer (geen UserDefaults key): migreer vanuit bestaande potjes & scores
        var namesSet = Set<String>()
        for game in playedGames {
            for s in game.scores {
                let trimmed = s.playerName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    namesSet.insert(trimmed)
                }
            }
        }

        for score in scores {
            let trimmed = score.playerName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                namesSet.insert(trimmed)
            }
        }

        let sorted = sortPlayersByPopularity(Array(namesSet))
        UserDefaults.standard.set(sorted, forKey: playersKey)
        return sorted
    }

    func savePlayerName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var current = fetchPlayerNames()
        if !current.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            current.append(trimmed)
            persistPlayerNames(current)
        }
    }

    func savePlayerNames<S: Sequence>(_ names: S) where S.Element == String {
        for n in names {
            savePlayerName(n)
        }
    }

    func savePlayerNames(players: [Player]) {
        for p in players {
            savePlayerName(p.name)
        }
    }

    private func persistPlayerNames(_ names: [String]) {
        let sorted = sortPlayersByPopularity(names)
        UserDefaults.standard.set(sorted, forKey: playersKey)
        self.savedPlayerNames = sorted
        DataBackupManager.shared.scheduleAutoSyncToiCloud()
    }

    // MARK: - Scores & Gespeelde Potjes ophalen

    func fetchScores() -> [Score] {
        guard let data = UserDefaults.standard.data(forKey: scoresKey) else {
            return []
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Score].self, from: data)
        } catch {
            print("Fout bij laden van scores: \(error)")
            return []
        }
    }

    func fetchGames() -> [PlayedGame] {
        guard let data = UserDefaults.standard.data(forKey: gamesKey) else {
            return []
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([PlayedGame].self, from: data)
        } catch {
            print("Fout bij laden van gespeelde potjes: \(error)")
            return []
        }
    }

    // MARK: - Scores & Spellen Opslaan

    func saveScore(for player: Player, score: Int, gameName: String, isWinner: Bool = false) {
        saveScore(playerName: player.name, score: score, gameName: gameName, isWinner: isWinner)
    }

    func saveScore(playerName: String, score: Int, gameName: String, isWinner: Bool = false) {
        let trimmed = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        savePlayerName(trimmed)

        var existing = fetchScores()
        let newScore = Score(
            date: Date(),
            gameName: gameName,
            playerName: trimmed,
            score: score,
            isWinner: isWinner
        )
        existing.append(newScore)
        persistScores(existing)
    }

    func saveGame(
        gameName: String,
        players: [Player],
        scores: [Int],
        winner: Player?,
        juisteBalzakken: [Int]? = nil,
        fouteBalzakken: [Int]? = nil
    ) {
        let paired: [(name: String, score: Int, juiste: Int, foute: Int)] = players.indices.map { i in
            let name = players[i].name
            let sc = i < scores.count ? scores[i] : 0
            let j = juisteBalzakken?[safe: i] ?? 0
            let f = fouteBalzakken?[safe: i] ?? 0
            return (name, sc, j, f)
        }
        saveGame(gameName: gameName, playerDetailedScores: paired, winnerName: winner?.name ?? "")
    }

    func saveGame(gameName: String, playerScores: [(player: Player, score: Int)], winner: Player?) {
        let paired = playerScores.map { ($0.player.name, $0.score, 0, 0) }
        saveGame(gameName: gameName, playerDetailedScores: paired, winnerName: winner?.name ?? "")
    }

    func saveGame(gameName: String, playerScores: [(name: String, score: Int)], winnerName: String) {
        let detailed = playerScores.map { ($0.name, $0.score, 0, 0) }
        saveGame(gameName: gameName, playerDetailedScores: detailed, winnerName: winnerName)
    }

    // MARK: - Team Helpers

    static func isDefaultTeamName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty { return true }
        if trimmed.hasPrefix("team ") { return true }
        let defaults: Set<String> = [
            "de breinen", "de bollebozen", "de genieën", "de creatievelingen",
            "team 1", "team 2", "team 3", "team 4",
            "team wit", "team zwart", "team oranje", "team blauw", "team groen", "team paars", "team rood"
        ]
        return defaults.contains(trimmed)
    }

    static func effectiveTeamDisplayName(teamName: String, playerNames: [String]) -> String {
        let trimmed = teamName.trimmingCharacters(in: .whitespacesAndNewlines)
        let playersStr = playerNames.joined(separator: " & ")
        if trimmed.isEmpty || isDefaultTeamName(trimmed) {
            return playersStr.isEmpty ? trimmed : playersStr
        }
        return trimmed
    }

    func saveGame(
        gameName: String,
        playerDetailedScores: [(name: String, score: Int, juiste: Int, foute: Int)],
        winnerName: String
    ) {
        let now = Date()
        var existingGames = fetchGames()
        var existingScores = fetchScores()

        // Voorkom dubbele opslag binnen 5 seconden (bijv. auto-save + knop indrukken)
        if let last = existingGames.last,
           last.gameName.caseInsensitiveCompare(gameName) == .orderedSame,
           abs(now.timeIntervalSince(last.date)) < 5.0 {
            let lastSummary = last.scores.map { "\($0.playerName):\($0.score)" }.sorted()
            let newSummary = playerDetailedScores.map { "\($0.name.trimmingCharacters(in: .whitespacesAndNewlines)):\($0.score)" }.sorted()
            if lastSummary == newSummary {
                return
            }
        }

        let trimmedWinner = winnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedWinner.isEmpty {
            savePlayerName(trimmedWinner)
        }

        let entries: [PlayerScore] = playerDetailedScores.map { item in
            let trimmed = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            savePlayerName(trimmed)
            let isWinner = !trimmedWinner.isEmpty && trimmed.caseInsensitiveCompare(trimmedWinner) == .orderedSame
            return PlayerScore(
                playerName: trimmed,
                score: item.score,
                isWinner: isWinner,
                juisteBalzakken: item.juiste,
                fouteBalzakken: item.foute
            )
        }

        let game = PlayedGame(
            date: now,
            gameName: gameName,
            scores: entries,
            winner: trimmedWinner
        )
        existingGames.append(game)
        persistGames(existingGames)

        for item in entries {
            let scoreEntry = Score(
                date: now,
                gameName: gameName,
                playerName: item.playerName,
                score: item.score,
                isWinner: item.isWinner
            )
            existingScores.append(scoreEntry)
        }
        persistScores(existingScores)
    }

    func saveTeamGame(
        gameName: String,
        teams: [(teamName: String, playerNames: [String], score: Int, isWinner: Bool)]
    ) {
        let now = Date()
        var existingGames = fetchGames()
        var existingScores = fetchScores()

        // Voorkom dubbele opslag binnen 5 seconden
        if let last = existingGames.last,
           last.gameName.caseInsensitiveCompare(gameName) == .orderedSame,
           abs(now.timeIntervalSince(last.date)) < 5.0 {
            let lastSummary = last.scores.map { "\($0.playerName):\($0.score)" }.sorted()
            let newSummary = teams.flatMap { t in t.playerNames.map { "\($0.trimmingCharacters(in: .whitespacesAndNewlines)):\(t.score)" } }.sorted()
            if lastSummary == newSummary {
                return
            }
        }

        let winningTeam = teams.first(where: { $0.isWinner })
        let cleanWinningPlayers = winningTeam?.playerNames.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty } ?? []
        let cleanTeamName = winningTeam?.teamName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        var gameTeams: [GameTeam] = []
        var playerScores: [PlayerScore] = []

        for t in teams {
            let cleanCurrentTeamName = t.teamName.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanPlayers = t.playerNames.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }

            let effectiveName = cleanCurrentTeamName.isEmpty ? cleanPlayers.joined(separator: " & ") : cleanCurrentTeamName
            let teamEntry = GameTeam(
                teamName: effectiveName,
                playerNames: cleanPlayers,
                score: t.score,
                isWinner: t.isWinner
            )
            gameTeams.append(teamEntry)

            for pName in cleanPlayers {
                savePlayerName(pName)

                let ps = PlayerScore(
                    playerName: pName,
                    score: t.score,
                    isWinner: t.isWinner
                )
                playerScores.append(ps)

                let scoreEntry = Score(
                    date: now,
                    gameName: gameName,
                    playerName: pName,
                    score: t.score,
                    isWinner: t.isWinner
                )
                existingScores.append(scoreEntry)
            }
        }

        // Bepaal een duidelijke winnaartitel
        let effectiveWinnerName: String
        let playersJoined = cleanWinningPlayers.joined(separator: " & ")
        if cleanTeamName.isEmpty || ScoreManager.isDefaultTeamName(cleanTeamName) {
            effectiveWinnerName = playersJoined.isEmpty ? cleanTeamName : playersJoined
        } else {
            effectiveWinnerName = playersJoined.isEmpty ? cleanTeamName : "\(cleanTeamName) (\(playersJoined))"
        }

        let defaultWinner = gameTeams.first(where: { $0.isWinner })?.teamName ?? ""
        let game = PlayedGame(
            date: now,
            gameName: gameName,
            scores: playerScores,
            winner: effectiveWinnerName.isEmpty ? defaultWinner : effectiveWinnerName,
            teams: gameTeams
        )
        existingGames.append(game)
        persistGames(existingGames)
        persistScores(existingScores)
    }

    func deleteGame(id: UUID) {
        var games = fetchGames()
        if let toDelete = games.first(where: { $0.id == id }) {
            deleteScoresForGame(toDelete)
        }
        games.removeAll { $0.id == id }
        DataBackupManager.shared.recordDeletedGameIds([id])
        persistGames(games)
        refresh()
    }

    private func deleteScoresForGame(_ game: PlayedGame) {
        var existingScores = fetchScores()
        let gameDate = game.date
        let gameName = game.gameName
        let pNames = Set(game.scores.map { $0.playerName.lowercased() })

        existingScores.removeAll { sc in
            sc.gameName.caseInsensitiveCompare(gameName) == .orderedSame &&
            abs(sc.date.timeIntervalSince(gameDate)) < 5.0 &&
            pNames.contains(sc.playerName.lowercased())
        }
        persistScores(existingScores)
    }

    func deleteGames(ids: Set<UUID>) {
        var games = fetchGames()
        var existingScores = fetchScores()

        for game in games where ids.contains(game.id) {
            let gameDate = game.date
            let gameName = game.gameName
            let pNames = Set(game.scores.map { $0.playerName.lowercased() })

            existingScores.removeAll { sc in
                sc.gameName.caseInsensitiveCompare(gameName) == .orderedSame &&
                abs(sc.date.timeIntervalSince(gameDate)) < 5.0 &&
                pNames.contains(sc.playerName.lowercased())
            }
        }

        games.removeAll { ids.contains($0.id) }
        DataBackupManager.shared.recordDeletedGameIds(ids)
        persistGames(games)
        persistScores(existingScores)
        refresh()
    }

    func deleteGames(on day: Date) {
        let calendar = Calendar.current
        let idsToDelete = Set(playedGames.filter { calendar.isDate($0.date, inSameDayAs: day) }.map { $0.id })
        deleteGames(ids: idsToDelete)
    }

    func deleteGames(forGame gameName: String) {
        let idsToDelete = Set(playedGames.filter { $0.gameName.caseInsensitiveCompare(gameName) == .orderedSame }.map { $0.id })
        deleteGames(ids: idsToDelete)
    }

    func deleteGamesBeforeYesterday() {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return }
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        let idsToDelete = Set(playedGames.filter { $0.date < startOfYesterday }.map { $0.id })
        deleteGames(ids: idsToDelete)
    }

    func deletePlayer(name: String) {
        var current = fetchPlayerNames()
        current.removeAll { $0.caseInsensitiveCompare(name) == .orderedSame }
        persistPlayerNames(current)
    }

    func clearAllPlayers() {
        UserDefaults.standard.set([String](), forKey: playersKey)
        self.savedPlayerNames = []
        DataBackupManager.shared.scheduleAutoSyncToiCloud()
    }

    func clearAllScores() {
        clearHistory()
    }

    func clearHistory() {
        let allIds = playedGames.map { $0.id }
        DataBackupManager.shared.recordDeletedGameIds(allIds)
        UserDefaults.standard.removeObject(forKey: scoresKey)
        UserDefaults.standard.removeObject(forKey: gamesKey)
        UserDefaults.standard.removeObject(forKey: playersKey)
        scores = []
        playedGames = []
        savedPlayerNames = []
        DataBackupManager.shared.scheduleAutoSyncToiCloud()
    }

    func saveAllPlayerNames(_ names: [String]) {
        persistPlayerNames(names)
    }

    func saveAllGames(_ games: [PlayedGame]) {
        persistGames(games)
    }

    func saveAllScores(_ scores: [Score]) {
        persistScores(scores)
    }

    private func persistScores(_ scores: [Score]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(scores)
            UserDefaults.standard.set(data, forKey: scoresKey)
            self.scores = scores
            DataBackupManager.shared.scheduleAutoSyncToiCloud()
        } catch {
            print("Fout bij opslaan van scores: \(error)")
        }
    }

    private func persistGames(_ games: [PlayedGame]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(games)
            UserDefaults.standard.set(data, forKey: gamesKey)
            self.playedGames = games
            self.savedPlayerNames = fetchPlayerNames()
            DataBackupManager.shared.scheduleAutoSyncToiCloud()
        } catch {
            print("Fout bij opslaan van gespeelde potjes: \(error)")
        }
    }

    // MARK: - Statistieken Berekeningen

    /// Geeft aan of bij een spel de laagste score wint
    func isLowestScoreWins(for gameName: String) -> Bool {
        let name = gameName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return name == "beverbende" || name == "balzakken" || name == "pig hole" || name == "pighole" || name == "quickstop" || name == "quick stop"
    }

    /// Meest gespeelde spellen met aantal potjes
    func mostPlayedGames() -> [(gameName: String, count: Int)] {
        let grouped = Dictionary(grouping: playedGames, by: { $0.gameName })
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Winnaar Bepaling

    /// Bepaalt betrouwbaar of een speler een potje heeft gewonnen (werkt voor individuele en teamspellen)
    func didPlayerWin(game: PlayedGame, playerName: String) -> Bool {
        let cleanName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return false }

        // 1. Directe controle op de isWinner vlag in de individuele score
        if let ps = game.scores.first(where: { $0.playerName.caseInsensitiveCompare(cleanName) == .orderedSame }) {
            if ps.isWinner { return true }
        }

        // 2. Controle in de teamstructuur (voor 30 Seconds, Cranium, Crokinole)
        if let teams = game.teams, !teams.isEmpty {
            for team in teams {
                let hasPlayer = team.playerNames.contains(where: { $0.caseInsensitiveCompare(cleanName) == .orderedSame })
                if !hasPlayer { continue }

                if team.isWinner {
                    return true
                }

                // Fallback: Als team.isWinner niet gezet was, maar game.winner matcht de teamnaam of alle teamleden
                if !game.isTie && !game.winner.isEmpty {
                    if team.teamName.caseInsensitiveCompare(game.winner) == .orderedSame ||
                       game.winner.localizedCaseInsensitiveContains(team.teamName) {
                        return true
                    }
                    let cleanWinner = game.winner.lowercased()
                    let allTeamPlayersInWinner = !team.playerNames.isEmpty && team.playerNames.allSatisfy { p in
                        let tr = p.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        return !tr.isEmpty && cleanWinner.contains(tr)
                    }
                    if allTeamPlayersInWinner {
                        return true
                    }
                }
            }
        }

        // 3. Controle op game.winner string (voor individuele spellen of samengestelde titels)
        if !game.isTie && !game.winner.isEmpty {
            let w = game.winner.trimmingCharacters(in: .whitespacesAndNewlines)
            if w.caseInsensitiveCompare(cleanName) == .orderedSame {
                return true
            }

            // Controleer of de spelernaam voorkomt in een duo-titel zoals "Jan & Piet" of "Team Oranje (Jan & Piet)"
            let separators = CharacterSet(charactersIn: "&+,/()")
            let parts = w.components(separatedBy: separators).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.contains(where: { $0.caseInsensitiveCompare(cleanName) == .orderedSame }) {
                return true
            }
        }

        return false
    }

    /// Wie heeft wat het vaakst gewonnen per spel
    func mostWinsPerGame() -> [(gameName: String, winnerName: String, wins: Int)] {
        let groupedByGame = Dictionary(grouping: playedGames, by: { $0.gameName })
        var results: [(gameName: String, winnerName: String, wins: Int)] = []

        for (game, games) in groupedByGame {
            let leaderboard = gameLeaderboard(for: game)
            guard let top = leaderboard.first, top.gamesWon > 0 else {
                let validWinners = games.map { $0.winner }.filter { !$0.isEmpty }
                if let topWinner = Dictionary(grouping: validWinners, by: { $0 }).mapValues({ $0.count }).max(by: { $0.value < $1.value }) {
                    results.append((gameName: game, winnerName: topWinner.key, wins: topWinner.value))
                }
                continue
            }

            let topWinners = leaderboard.filter { $0.gamesWon == top.gamesWon }
            let winnerTitle: String
            if topWinners.count == 2 {
                winnerTitle = "\(topWinners[0].playerName) & \(topWinners[1].playerName)"
            } else if topWinners.count == 1 {
                winnerTitle = topWinners[0].playerName
            } else {
                winnerTitle = topWinners.map { $0.playerName }.joined(separator: ", ")
            }

            results.append((gameName: game, winnerName: winnerTitle, wins: top.gamesWon))
        }

        return results.sorted { $0.gameName < $1.gameName }
    }

    /// Totaal ranking op basis van aantal overwinningen
    func overallWinRankings() -> [(playerName: String, wins: Int, totalGames: Int, winRate: Double)] {
        let players = fetchPlayerNames()
        var results: [(playerName: String, wins: Int, totalGames: Int, winRate: Double)] = []

        for player in players {
            var totalGames = 0
            var wins = 0

            for game in playedGames {
                if game.playerNamesList.contains(where: { $0.caseInsensitiveCompare(player) == .orderedSame }) {
                    totalGames += 1
                    if didPlayerWin(game: game, playerName: player) {
                        wins += 1
                    }
                }
            }

            if totalGames > 0 {
                let rate = (Double(wins) / Double(totalGames)) * 100.0
                results.append((playerName: player, wins: wins, totalGames: totalGames, winRate: rate))
            }
        }

        return results.sorted {
            if $0.wins != $1.wins {
                return $0.wins > $1.wins
            } else {
                return $0.winRate > $1.winRate
            }
        }
    }

    /// Gedetailleerde statistieken voor een individuele speler
    func detailedStats(for playerName: String) -> DetailedPlayerStats {
        let playerGames = playedGames.filter { game in
            game.playerNamesList.contains { $0.caseInsensitiveCompare(playerName) == .orderedSame }
        }

        let totalGames = playerGames.count
        let totalWins = playerGames.filter { didPlayerWin(game: $0, playerName: playerName) }.count

        // Uitsplitsing per spel
        let grouped = Dictionary(grouping: playerGames, by: { $0.gameName })
        var statsPerGame: [GamePlayerStat] = []

        for (gameName, gList) in grouped {
            let played = gList.count
            let won = gList.filter { didPlayerWin(game: $0, playerName: playerName) }.count

            // Beste score bepalen
            let playerScoresInGame = gList.compactMap { g -> Int? in
                if let sc = g.scores.first(where: { $0.playerName.caseInsensitiveCompare(playerName) == .orderedSame })?.score {
                    return sc
                }
                if let t = g.teams?.first(where: { $0.playerNames.contains(where: { $0.caseInsensitiveCompare(playerName) == .orderedSame }) }) {
                    return t.score
                }
                return nil
            }

            let bestScore: Int?
            if isLowestScoreWins(for: gameName) {
                bestScore = playerScoresInGame.min()
            } else {
                bestScore = playerScoresInGame.max()
            }

            statsPerGame.append(GamePlayerStat(
                gameName: gameName,
                played: played,
                won: won,
                bestScore: bestScore
            ))
        }

        statsPerGame.sort { $0.played > $1.played }

        return DetailedPlayerStats(
            playerName: playerName,
            totalGames: totalGames,
            totalWins: totalWins,
            statsPerGame: statsPerGame
        )
    }

    /// Head-to-Head: Wie wint het vaakst van wie (totaal of per specifiek spel)
    func headToHead(playerA: String, playerB: String, gameFilter: String? = nil) -> HeadToHeadRecord {
        var relevantGames = playedGames.filter { game in
            let hasA = game.scores.contains { $0.playerName.caseInsensitiveCompare(playerA) == .orderedSame }
            let hasB = game.scores.contains { $0.playerName.caseInsensitiveCompare(playerB) == .orderedSame }
            return hasA && hasB
        }

        if let filter = gameFilter, !filter.isEmpty, filter != "Alle Spellen" {
            relevantGames = relevantGames.filter { matchesGameName($0.gameName, filter) }
        }

        var winsA = 0
        var winsB = 0
        var ties = 0

        for game in relevantGames {
            let lowestWins = isLowestScoreWins(for: game.gameName)

            // Als het een teamspel is, controleer of ze in hetzelfde team zaten of tegen elkaar speelden
            if let teams = game.teams, !teams.isEmpty {
                let teamA = teams.first { $0.playerNames.contains { $0.caseInsensitiveCompare(playerA) == .orderedSame } }
                let teamB = teams.first { $0.playerNames.contains { $0.caseInsensitiveCompare(playerB) == .orderedSame } }

                if let tA = teamA, let tB = teamB {
                    if tA.teamName == tB.teamName && tA.playerNames == tB.playerNames {
                        // Ze waren teamgenoten in hetzelfde team; tellen niet als rivalen tegen elkaar
                        continue
                    }

                    let aWon = didPlayerWin(game: game, playerName: playerA)
                    let bWon = didPlayerWin(game: game, playerName: playerB)

                    if aWon && !bWon {
                        winsA += 1
                    } else if bWon && !aWon {
                        winsB += 1
                    } else if tA.score == tB.score {
                        ties += 1
                    } else if lowestWins {
                        if tA.score < tB.score { winsA += 1 } else { winsB += 1 }
                    } else {
                        if tA.score > tB.score { winsA += 1 } else { winsB += 1 }
                    }
                    continue
                }
            }

            guard let scoreA = game.scores.first(where: { $0.playerName.caseInsensitiveCompare(playerA) == .orderedSame })?.score,
                  let scoreB = game.scores.first(where: { $0.playerName.caseInsensitiveCompare(playerB) == .orderedSame })?.score else {
                continue
            }

            if scoreA == scoreB {
                ties += 1
            } else if lowestWins {
                if scoreA < scoreB { winsA += 1 } else { winsB += 1 }
            } else {
                if scoreA > scoreB { winsA += 1 } else { winsB += 1 }
            }
        }

        return HeadToHeadRecord(
            playerA: playerA,
            playerB: playerB,
            winsA: winsA,
            winsB: winsB,
            ties: ties,
            totalGames: winsA + winsB + ties
        )
    }

    /// Geeft alle rivaliteiten terug van spelersparen die samen hebben gespeeld
    func allRivalries(gameFilter: String? = nil) -> [HeadToHeadRecord] {
        let players = fetchPlayerNames()
        guard players.count >= 2 else { return [] }

        var records: [HeadToHeadRecord] = []

        for i in 0..<players.count {
            for j in (i + 1)..<players.count {
                let rec = headToHead(playerA: players[i], playerB: players[j], gameFilter: gameFilter)
                if rec.totalGames > 0 {
                    records.append(rec)
                }
            }
        }

        // Sorteer op meest gespeelde onderlinge potjes
        return records.sorted { $0.totalGames > $1.totalGames }
    }

    /// Berekent de huidige en beste win-streak (opeenvolgende overwinningen) voor een speler
    func playerWinStreak(for playerName: String) -> (current: Int, best: Int) {
        let nameLower = playerName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !nameLower.isEmpty else { return (0, 0) }

        // Sorteer alle relevante potjes op datum (oplopend)
        let relevantGames = playedGames.filter { game in
            game.playerNamesList.contains { $0.lowercased() == nameLower }
        }.sorted { $0.date < $1.date }

        var currentStreak = 0
        var bestStreak = 0

        for game in relevantGames {
            let won = didPlayerWin(game: game, playerName: playerName)

            if won {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        return (currentStreak, bestStreak)
    }

    /// Geeft behaalde badges en achievements terug voor een speler
    func playerBadges(for playerName: String) -> [PlayerBadge] {
        var badges: [PlayerBadge] = []
        let stats = detailedStats(for: playerName)
        let streaks = playerWinStreak(for: playerName)

        // 1. Winstreeks Badges
        if streaks.current >= 3 {
            badges.append(PlayerBadge(
                title: "On Fire! 🔥",
                subtitle: "\(streaks.current)x op rij gewonnen",
                icon: "flame.fill",
                color: .orange
            ))
        } else if streaks.best >= 3 {
            badges.append(PlayerBadge(
                title: "Streak Master",
                subtitle: "Record van \(streaks.best)x op rij gewonnen",
                icon: "bolt.fill",
                color: .yellow
            ))
        }

        // 2. Ervaring / Gespeelde potjes
        if stats.totalGames >= 25 {
            badges.append(PlayerBadge(
                title: "Bordspel Grootmeester",
                subtitle: "\(stats.totalGames) potjes gespeeld",
                icon: "crown.fill",
                color: .purple
            ))
        } else if stats.totalGames >= 10 {
            badges.append(PlayerBadge(
                title: "Tafel Veteraan",
                subtitle: "\(stats.totalGames) potjes gespeeld",
                icon: "shield.fill",
                color: .blue
            ))
        }

        // 3. Winpercentage
        if stats.totalGames >= 5 && stats.winRate >= 60.0 {
            badges.append(PlayerBadge(
                title: "Scherpschutter",
                subtitle: "\(Int(stats.winRate.rounded()))% winrate (\(stats.totalWins) zeges)",
                icon: "target",
                color: .green
            ))
        }

        // 4. Specifieke spelprestaties
        for g in stats.statsPerGame {
            let gName = g.gameName.lowercased()
            if gName == "balzakken" && g.won >= 3 {
                badges.append(PlayerBadge(
                    title: "Balzakken Koning",
                    subtitle: "\(g.won)x gewonnen in Balzakken",
                    icon: "flame.fill",
                    color: .red
                ))
            } else if (gName.contains("ticket to ride")) && g.won >= 2 {
                badges.append(PlayerBadge(
                    title: "Spoorweg Tycoon",
                    subtitle: "\(g.won)x gewonnen in Ticket to Ride",
                    icon: "tram.fill",
                    color: .blue
                ))
            } else if (gName.contains("30 seconds") || gName.contains("cranium")) && g.won >= 3 {
                badges.append(PlayerBadge(
                    title: "Partyspel Pro",
                    subtitle: "\(g.won) overwinningen in partygames",
                    icon: "party.popper.fill",
                    color: .pink
                ))
            }
        }

        return badges
    }

    /// Geeft statistieken terug voor Balzakken (juiste en foute balzakken per speler)
    func balzakkenLeaderboard() -> [BalzakkenPlayerStat] {
        var map: [String: (juiste: Int, foute: Int, games: Int)] = [:]

        for game in playedGames where game.gameName.lowercased() == "balzakken" {
            for score in game.scores {
                let name = score.playerName
                let cur = map[name] ?? (juiste: 0, foute: 0, games: 0)
                map[name] = (
                    juiste: cur.juiste + (score.juisteBalzakken ?? 0),
                    foute: cur.foute + (score.fouteBalzakken ?? 0),
                    games: cur.games + 1
                )
            }
        }

        return map.map { name, val in
            BalzakkenPlayerStat(
                playerName: name,
                juisteBalzakken: val.juiste,
                fouteBalzakken: val.foute,
                gamesPlayed: val.games
            )
        }.sorted {
            if $0.juisteBalzakken != $1.juisteBalzakken {
                return $0.juisteBalzakken > $1.juisteBalzakken
            }
            return $0.fouteBalzakken < $1.fouteBalzakken
        }
    }

    // MARK: - Statistieken per Spel

    func matchesGameName(_ a: String, _ b: String) -> Bool {
        let la = a.lowercased().replacingOccurrences(of: " ", with: "")
        let lb = b.lowercased().replacingOccurrences(of: " ", with: "")
        if la == lb { return true }
        if (la.contains("crok") || la.contains("crokinole")) && (lb.contains("crok") || lb.contains("crokinole")) {
            return true
        }
        return false
    }

    /// Ranglijst van spelers voor één specifiek spel
    func gameLeaderboard(for gameName: String) -> [GameSpecificPlayerStat] {
        let isLowestWins = isLowestScoreWins(for: gameName)
        let matchingGames = playedGames.filter { matchesGameName($0.gameName, gameName) }

        var playerMap: [String: (played: Int, won: Int, scores: [Int])] = [:]

        for game in matchingGames {
            var playerEntries: [(name: String, score: Int)] = []
            if !game.scores.isEmpty {
                for sc in game.scores {
                    playerEntries.append((sc.playerName, sc.score))
                }
            } else if let teams = game.teams {
                for t in teams {
                    for p in t.playerNames {
                        playerEntries.append((p, t.score))
                    }
                }
            }

            for entry in playerEntries {
                let pName = entry.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !pName.isEmpty else { continue }
                var current = playerMap[pName] ?? (played: 0, won: 0, scores: [])
                current.played += 1
                if didPlayerWin(game: game, playerName: pName) {
                    current.won += 1
                }
                current.scores.append(entry.score)
                playerMap[pName] = current
            }
        }

        return playerMap.map { (name, data) in
            let best: Int? = isLowestWins ? data.scores.min() : data.scores.max()
            let avg: Double? = data.scores.isEmpty ? nil : Double(data.scores.reduce(0, +)) / Double(data.scores.count)
            return GameSpecificPlayerStat(
                playerName: name,
                gamesPlayed: data.played,
                gamesWon: data.won,
                bestScore: best,
                averageScore: avg
            )
        }.sorted {
            if $0.gamesWon != $1.gamesWon {
                return $0.gamesWon > $1.gamesWon
            }
            if $0.winRate != $1.winRate {
                return $0.winRate > $1.winRate
            }
            return $0.gamesPlayed > $1.gamesPlayed
        }
    }

    /// Beste score ooit voor een specifiek spel
    func bestScoreEver(for gameName: String) -> (playerName: String, score: Int)? {
        let isLowestWins = isLowestScoreWins(for: gameName)
        var allCandidates: [(playerName: String, score: Int)] = []

        for sc in scores where matchesGameName(sc.gameName, gameName) {
            allCandidates.append((sc.playerName, sc.score))
        }

        if allCandidates.isEmpty {
            for g in playedGames where matchesGameName(g.gameName, gameName) {
                for sc in g.scores {
                    allCandidates.append((sc.playerName, sc.score))
                }
            }
        }

        guard !allCandidates.isEmpty else { return nil }

        if isLowestWins {
            return allCandidates.min(by: { $0.score < $1.score })
        } else {
            return allCandidates.max(by: { $0.score < $1.score })
        }
    }

    /// Recente spelsessies van een specifiek spel
    func recentSessions(for gameName: String, limit: Int = 10) -> [PlayedGame] {
        return playedGames
            .filter { matchesGameName($0.gameName, gameName) }
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Team & Partner Statistieken

    func teamLeaderboard(gameFilter: String? = nil) -> [TeamStat] {
        var teamMap: [String: (displayName: String, playerNames: [String], played: Int, won: Int, totalScore: Int)] = [:]

        var relevantGames = playedGames.filter { $0.teams != nil && !($0.teams!.isEmpty) }
        if let filter = gameFilter, !filter.isEmpty, filter != "Alle Spellen" {
            relevantGames = relevantGames.filter { matchesGameName($0.gameName, filter) }
        }

        for game in relevantGames {
            guard let teams = game.teams else { continue }
            for team in teams {
                let sortedPlayers = team.playerNames.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
                guard sortedPlayers.count >= 2 else { continue }
                let teamKey = sortedPlayers.joined(separator: " & ")
                let effectiveName = ScoreManager.effectiveTeamDisplayName(teamName: team.teamName, playerNames: sortedPlayers)

                let teamWon: Bool = {
                    if team.isWinner { return true }
                    if game.isTie || game.winner.isEmpty { return false }
                    if team.teamName.caseInsensitiveCompare(game.winner) == .orderedSame { return true }
                    let cleanWinner = game.winner.lowercased()
                    let allTeamPlayersInWinner = !team.playerNames.isEmpty && team.playerNames.allSatisfy { p in
                        let tr = p.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        return !tr.isEmpty && cleanWinner.contains(tr)
                    }
                    if allTeamPlayersInWinner { return true }
                    return false
                }()

                let current = teamMap[teamKey] ?? (
                    displayName: effectiveName,
                    playerNames: sortedPlayers,
                    played: 0,
                    won: 0,
                    totalScore: 0
                )
                teamMap[teamKey] = (
                    displayName: current.displayName,
                    playerNames: sortedPlayers,
                    played: current.played + 1,
                    won: current.won + (teamWon ? 1 : 0),
                    totalScore: current.totalScore + team.score
                )
            }
        }

        return teamMap.map { key, val in
            TeamStat(
                teamKey: key,
                displayName: val.displayName,
                playerNames: val.playerNames,
                played: val.played,
                won: val.won,
                totalScore: val.totalScore
            )
        }.sorted {
            if $0.won != $1.won {
                return $0.won > $1.won
            }
            if $0.winRate != $1.winRate {
                return $0.winRate > $1.winRate
            }
            return $0.played > $1.played
        }
    }

    func bestPartners(for playerName: String) -> [PartnerSynergyStat] {
        var partnerMap: [String: (games: Int, wins: Int, losses: Int)] = [:]

        for game in playedGames {
            guard let teams = game.teams else { continue }
            for team in teams {
                let hasPlayer = team.playerNames.contains { $0.caseInsensitiveCompare(playerName) == .orderedSame }
                guard hasPlayer && team.playerNames.count >= 2 else { continue }

                let teamWon: Bool = {
                    if team.isWinner { return true }
                    if game.isTie || game.winner.isEmpty { return false }
                    if team.teamName.caseInsensitiveCompare(game.winner) == .orderedSame { return true }
                    let cleanWinner = game.winner.lowercased()
                    let allTeamPlayersInWinner = !team.playerNames.isEmpty && team.playerNames.allSatisfy { p in
                        let tr = p.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        return !tr.isEmpty && cleanWinner.contains(tr)
                    }
                    if allTeamPlayersInWinner { return true }
                    return false
                }()

                for partner in team.playerNames {
                    guard partner.caseInsensitiveCompare(playerName) != .orderedSame else { continue }
                    let cur = partnerMap[partner] ?? (games: 0, wins: 0, losses: 0)
                    partnerMap[partner] = (
                        games: cur.games + 1,
                        wins: cur.wins + (teamWon ? 1 : 0),
                        losses: cur.losses + (teamWon ? 0 : 1)
                    )
                }
            }
        }

        return partnerMap.map { partner, data in
            PartnerSynergyStat(
                partnerName: partner,
                gamesTogether: data.games,
                winsTogether: data.wins,
                lossesTogether: data.losses
            )
        }.sorted {
            if $0.winRate != $1.winRate {
                return $0.winRate > $1.winRate
            }
            return $0.gamesTogether > $1.gamesTogether
        }
    }

    func allPlayersWithTeamHistory() -> [String] {
        var set = Set<String>()
        for game in playedGames {
            guard let teams = game.teams else { continue }
            for team in teams where team.playerNames.count >= 2 {
                for p in team.playerNames {
                    set.insert(p)
                }
            }
        }
        return set.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    func bestOverallDuo() -> TeamStat? {
        return teamLeaderboard().first
    }
}
