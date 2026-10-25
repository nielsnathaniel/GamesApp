import SwiftUI

struct WinnaarTeamEntry: Identifiable {
    var id: UUID = UUID()
    let teamName: String
    let playerNames: [String]
    let score: Int
    let isWinner: Bool
}

struct WinnaarView: View {
    var winnaar: Player
    var sortedSpelers: [Player]
    var sortedScores: [Int]
    var gameName: String = "Nmbr9"
    var isLowestScoreWins: Bool = false
    var juisteBalzakken: [Int]? = nil
    var fouteBalzakken: [Int]? = nil
    var teamEntries: [WinnaarTeamEntry]? = nil

    @State private var isScoreOpgeslagen = false
    @Environment(\.dismiss) private var dismiss
    private let scoreManager = ScoreManager.shared

    init(
        winnaar: Player,
        sortedSpelers: [Player],
        sortedScores: [Int],
        gameName: String = "Nmbr9",
        isLowestScoreWins: Bool = false
    ) {
        self.winnaar = winnaar
        self.sortedSpelers = sortedSpelers
        self.sortedScores = sortedScores
        self.gameName = gameName
        self.isLowestScoreWins = isLowestScoreWins
    }

    init(
        gameName: String,
        winnaar: Player,
        sortedSpelers: [Player],
        sortedScores: [Int],
        isLowestScoreWins: Bool = false,
        juisteBalzakken: [Int]? = nil,
        fouteBalzakken: [Int]? = nil
    ) {
        self.gameName = gameName
        self.winnaar = winnaar
        self.sortedSpelers = sortedSpelers
        self.sortedScores = sortedScores
        self.isLowestScoreWins = isLowestScoreWins
        self.juisteBalzakken = juisteBalzakken
        self.fouteBalzakken = fouteBalzakken
    }

    init(
        gameName: String,
        winnaarNaam: String,
        spelersNamen: [String],
        scores: [Int],
        isLowestScoreWins: Bool = false
    ) {
        self.gameName = gameName
        self.winnaar = Player(name: winnaarNaam)
        self.sortedSpelers = spelersNamen.map { Player(name: $0) }
        self.sortedScores = scores
        self.isLowestScoreWins = isLowestScoreWins
    }

    init(
        gameName: String,
        winningTeamName: String,
        teams: [WinnaarTeamEntry],
        isLowestScoreWins: Bool = false
    ) {
        self.gameName = gameName
        self.winnaar = Player(name: winningTeamName)
        self.sortedSpelers = teams.flatMap { $0.playerNames.map { Player(name: $0) } }
        self.sortedScores = teams.map { $0.score }
        self.isLowestScoreWins = isLowestScoreWins
        self.teamEntries = teams
    }

    private var rankedIndices: [Int] {
        sortedSpelers.indices.sorted { i, j in
            let scoreI = i < sortedScores.count ? sortedScores[i] : 0
            let scoreJ = j < sortedScores.count ? sortedScores[j] : 0
            if isLowestScoreWins {
                return scoreI < scoreJ
            } else {
                return scoreI > scoreJ
            }
        }
    }

    private var rankedTeams: [WinnaarTeamEntry] {
        guard let teams = teamEntries else { return [] }
        return teams.sorted { t1, t2 in
            if isLowestScoreWins {
                return t1.score < t2.score
            } else {
                return t1.score > t2.score
            }
        }
    }

    var body: some View {
        VStack {
            Text(gameName)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 10)

            VStack(spacing: 4) {
                Text(teamEntries != nil ? "Winnend Team:" : "Winnaar:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.black.opacity(0.6))

                Text(winnaar.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                if let teams = teamEntries, let winTeam = teams.first(where: { $0.isWinner }) {
                    Text(winTeam.playerNames.joined(separator: " & "))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.black.opacity(0.8))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.yellow)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
            .padding(.top, 10)

            List {
                if let _ = teamEntries {
                    ForEach(rankedTeams) { team in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(team.teamName)
                                        .font(.headline)
                                    if team.isWinner {
                                        Text("🏆 Winnaar")
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.yellow.opacity(0.3))
                                            .cornerRadius(4)
                                    }
                                }
                                Text(team.playerNames.joined(separator: " & "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            let unit = gameName.localizedCaseInsensitiveContains("crok") ? "sets" : "pt"
                            Text("\(team.score) \(unit)")
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 2)
                    }
                } else {
                    ForEach(rankedIndices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(sortedSpelers[index].name)
                                    .font(.headline)
                                if let j = juisteBalzakken?[safe: index], let f = fouteBalzakken?[safe: index], (j > 0 || f > 0) {
                                    Text("🎯 \(j) Balzak\(j == 1 ? "" : "ken") • ⚠️ \(f) Valse")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if gameName == "Jatten" {
                                if sortedSpelers[index].name == winnaar.name {
                                    Text("🏆 6 dezelfde!")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                } else {
                                    Text("Meegespeeld")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("\(sortedScores[safe: index] ?? 0) punten")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .padding(.top, 16)

            Spacer()

            VStack(spacing: 12) {
                Button(action: {
                    autoSaveScore()
                }) {
                    HStack(spacing: 8) {
                        if isScoreOpgeslagen {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isScoreOpgeslagen ? "Score succesvol opgeslagen!" : "Score opslaan")
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isScoreOpgeslagen ? Color.gray : Color.green)
                    .cornerRadius(10)
                }
                .disabled(isScoreOpgeslagen)

                Button(action: {
                    dismiss()
                }) {
                    Text("Opnieuw")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }

                Button(action: {
                    dismiss()
                }) {
                    Text("Klaar")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            autoSaveScore()
        }
    }

    private func autoSaveScore() {
        guard !isScoreOpgeslagen else { return }
        isScoreOpgeslagen = true
        if let teams = teamEntries {
            scoreManager.saveTeamGame(
                gameName: gameName,
                teams: teams.map { ($0.teamName, $0.playerNames, $0.score, $0.isWinner) }
            )
        } else {
            scoreManager.saveGame(
                gameName: gameName,
                players: sortedSpelers,
                scores: sortedScores,
                winner: winnaar,
                juisteBalzakken: juisteBalzakken,
                fouteBalzakken: fouteBalzakken
            )
        }
    }
}

#Preview {
    WinnaarView(
        winnaar: Player(name: "Speler 1"),
        sortedSpelers: [Player(name: "Speler 1"), Player(name: "Speler 2")],
        sortedScores: [100, 80],
        gameName: "Nmbr9",
        isLowestScoreWins: false
    )
}
