import Foundation

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

struct PlayedGame: Identifiable, Codable {
    var id: UUID = UUID()
    let date: Date
    let gameName: String
    let scores: [PlayerScore]
    let winner: String
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

    func fetchPlayerNames() -> [String] {
        var namesSet = Set<String>()

        // 1. Opgeslagen namen uit UserDefaults
        if let data = UserDefaults.standard.stringArray(forKey: playersKey) {
            for name in data {
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    namesSet.insert(trimmed)
                }
            }
        }

        // 2. Namen uit reeds gespeelde potjes en scores
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

        return namesSet.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
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
        let sorted = names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        UserDefaults.standard.set(sorted, forKey: playersKey)
        self.savedPlayerNames = sorted
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

    func saveGame(
        gameName: String,
        playerDetailedScores: [(name: String, score: Int, juiste: Int, foute: Int)],
        winnerName: String
    ) {
        let now = Date()
        var existingGames = fetchGames()
        var existingScores = fetchScores()

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

    func deleteGame(id: UUID) {
        var games = fetchGames()
        games.removeAll { $0.id == id }
        persistGames(games)
    }

    func deletePlayer(name: String) {
        var current = fetchPlayerNames()
        current.removeAll { $0.caseInsensitiveCompare(name) == .orderedSame }
        persistPlayerNames(current)
    }

    func clearAllPlayers() {
        UserDefaults.standard.removeObject(forKey: playersKey)
        self.savedPlayerNames = []
    }

    func clearAllScores() {
        clearHistory()
    }

    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: scoresKey)
        UserDefaults.standard.removeObject(forKey: gamesKey)
        UserDefaults.standard.removeObject(forKey: playersKey)
        scores = []
        playedGames = []
        savedPlayerNames = []
    }

    private func persistScores(_ scores: [Score]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(scores)
            UserDefaults.standard.set(data, forKey: scoresKey)
            self.scores = scores
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
        } catch {
            print("Fout bij opslaan van gespeelde potjes: \(error)")
        }
    }

    // MARK: - Statistieken Berekeningen

    /// Geeft aan of bij een spel de laagste score wint
    func isLowestScoreWins(for gameName: String) -> Bool {
        return gameName == "Beverbende" || gameName == "Balzakken"
    }

    /// Meest gespeelde spellen met aantal potjes
    func mostPlayedGames() -> [(gameName: String, count: Int)] {
        let grouped = Dictionary(grouping: playedGames, by: { $0.gameName })
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    /// Wie heeft wat het vaakst gewonnen per spel
    func mostWinsPerGame() -> [(gameName: String, winnerName: String, wins: Int)] {
        let groupedByGame = Dictionary(grouping: playedGames, by: { $0.gameName })
        var results: [(gameName: String, winnerName: String, wins: Int)] = []

        for (game, games) in groupedByGame {
            let validWinners = games.map { $0.winner }.filter { !$0.isEmpty }
            guard !validWinners.isEmpty else { continue }
            let winnerCounts = Dictionary(grouping: validWinners, by: { $0 }).mapValues { $0.count }
            if let top = winnerCounts.max(by: { $0.value < $1.value }) {
                results.append((gameName: game, winnerName: top.key, wins: top.value))
            }
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
                if game.scores.contains(where: { $0.playerName.caseInsensitiveCompare(player) == .orderedSame }) {
                    totalGames += 1
                    if game.winner.caseInsensitiveCompare(player) == .orderedSame {
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
            game.scores.contains { $0.playerName.caseInsensitiveCompare(playerName) == .orderedSame }
        }

        let totalGames = playerGames.count
        let totalWins = playerGames.filter { $0.winner.caseInsensitiveCompare(playerName) == .orderedSame }.count

        // Uitsplitsing per spel
        let grouped = Dictionary(grouping: playerGames, by: { $0.gameName })
        var statsPerGame: [GamePlayerStat] = []

        for (gameName, gList) in grouped {
            let played = gList.count
            let won = gList.filter { $0.winner.caseInsensitiveCompare(playerName) == .orderedSame }.count

            // Beste score bepalen
            let playerScoresInGame = gList.compactMap { g in
                g.scores.first { $0.playerName.caseInsensitiveCompare(playerName) == .orderedSame }?.score
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
            relevantGames = relevantGames.filter { $0.gameName == filter }
        }

        var winsA = 0
        var winsB = 0
        var ties = 0

        for game in relevantGames {
            guard let scoreA = game.scores.first(where: { $0.playerName.caseInsensitiveCompare(playerA) == .orderedSame })?.score,
                  let scoreB = game.scores.first(where: { $0.playerName.caseInsensitiveCompare(playerB) == .orderedSame })?.score else {
                continue
            }

            let lowestWins = isLowestScoreWins(for: game.gameName)

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
}
