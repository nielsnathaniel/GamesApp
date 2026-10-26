import SwiftUI

struct SnelleEindscoreGameView: View {
    let gameName: String
    var assetName: String? = nil
    var themeColor: Color = .blue
    var spelers: [String] = []
    var teamEntries: [WinnaarTeamEntry]? = nil
    var isLowestScoreWins: Bool = false
    var scoreUnit: String = "pt"
    var allowNegative: Bool = true
    var initialScore: Int = 0
    var onReset: (() -> Void)? = nil

    @ObservedObject private var scoreManager = ScoreManager.shared
    @Environment(\.dismiss) private var dismiss

    // Scores per speler of team
    @State private var scores: [Int] = []
    // Optioneel voor Balzakken:
    @State private var juisteBalzakken: [Int] = []
    @State private var fouteBalzakken: [Int] = []

    @State private var showWinnaarView: Bool = false
    @State private var winnaarPlayer: Player = Player(name: "")
    @State private var winnaarTeamName: String = ""

    init(
        gameName: String,
        assetName: String? = nil,
        themeColor: Color = .blue,
        spelers: [String] = [],
        teamEntries: [WinnaarTeamEntry]? = nil,
        isLowestScoreWins: Bool = false,
        scoreUnit: String = "pt",
        allowNegative: Bool = true,
        initialScore: Int = 0,
        onReset: (() -> Void)? = nil
    ) {
        self.gameName = gameName
        self.assetName = assetName ?? gameName
        self.themeColor = themeColor
        self.spelers = spelers
        self.teamEntries = teamEntries
        self.isLowestScoreWins = isLowestScoreWins
        self.scoreUnit = scoreUnit
        self.allowNegative = allowNegative
        self.initialScore = initialScore
        self.onReset = onReset

        let count = teamEntries?.count ?? spelers.count
        _scores = State(initialValue: Array(repeating: initialScore, count: count))
        _juisteBalzakken = State(initialValue: Array(repeating: 0, count: count))
        _fouteBalzakken = State(initialValue: Array(repeating: 0, count: count))
    }

    private var itemCount: Int {
        teamEntries?.count ?? spelers.count
    }

    private func itemName(at index: Int) -> String {
        if let teams = teamEntries, index < teams.count {
            return teams[index].teamName
        }
        if index < spelers.count {
            return spelers[index]
        }
        return "Speler \(index + 1)"
    }

    private func teamMembers(at index: Int) -> String? {
        guard let teams = teamEntries, index < teams.count else { return nil }
        let members = teams[index].playerNames.filter { !$0.isEmpty }
        return members.isEmpty ? nil : members.joined(separator: ", ")
    }

    private var rankedIndices: [Int] {
        let indices = Array(0..<itemCount)
        return indices.sorted { i, j in
            let scoreA = scores[safe: i] ?? 0
            let scoreB = scores[safe: j] ?? 0
            if scoreA == scoreB { return i < j }
            return isLowestScoreWins ? scoreA < scoreB : scoreA > scoreB
        }
    }

    private func rankMedal(forItemIndex index: Int) -> String {
        guard let rank = rankedIndices.firstIndex(of: index) else { return "" }
        switch rank {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(rank + 1)."
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Header
                headerCard

                // Instructie banner
                instructionBanner

                // Speler / Team Score Rijtjes
                scoresListSection

                Spacer(minLength: 24)

                // Afrondknop
                submitButton
            }
            .padding(.vertical)
        }
        .navigationTitle("\(gameName) Uitslag")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showWinnaarView) {
            destinationWinnaarView
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        HStack(spacing: 14) {
            let actualAsset = assetName ?? gameName
            if UIImage(named: actualAsset) != nil {
                Image(actualAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: themeColor.opacity(0.3), radius: 5, x: 0, y: 2)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(themeColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: "bolt.fill")
                        .font(.title2)
                        .foregroundColor(themeColor)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(gameName)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Snelle Eindscore")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.2))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }

                HStack(spacing: 6) {
                    Image(systemName: isLowestScoreWins ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        .font(.caption2)
                        .foregroundColor(isLowestScoreWins ? .green : .orange)
                    Text(isLowestScoreWins ? "Laagste score wint (bijv. minste strafpunten)" : "Hoogste score wint")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var instructionBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "keyboard")
                .foregroundColor(themeColor)
                .font(.subheadline)
            Text("Typ direct de eindscore in via het numerieke toetsenbord of gebruik de sneltoetsen (-5, -1, +1, +5).")
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal)
    }

    private var scoresListSection: some View {
        VStack(spacing: 12) {
            ForEach(0..<itemCount, id: \.self) { idx in
                let name = itemName(at: idx)
                let members = teamMembers(at: idx)
                let medal = rankMedal(forItemIndex: idx)

                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        // Medaille / Rang preview
                        Text(medal)
                            .font(.headline)
                            .frame(width: 28, alignment: .center)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            if let members = members {
                                Text(members)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // Knoppenrij voor score
                        HStack(spacing: 6) {
                            Button(action: {
                                HapticManager.shared.light()
                                if idx < scores.count {
                                    scores[idx] -= 5
                                }
                            }) {
                                Text("-5")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 6)
                                    .background(Color.secondary.opacity(0.12))
                                    .cornerRadius(6)
                            }

                            Button(action: {
                                HapticManager.shared.light()
                                if idx < scores.count {
                                    scores[idx] -= 1
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.red)
                            }

                            if idx < scores.count {
                                NumericScoreInputView(
                                    score: $scores[idx],
                                    allowNegative: allowNegative,
                                    range: -999...9999,
                                    tintColor: themeColor,
                                    minWidth: 54,
                                    height: 36
                                )
                            }

                            Button(action: {
                                HapticManager.shared.light()
                                if idx < scores.count {
                                    scores[idx] += 1
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.green)
                            }

                            Button(action: {
                                HapticManager.shared.light()
                                if idx < scores.count {
                                    scores[idx] += 5
                                }
                            }) {
                                Text("+5")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 6)
                                    .background(Color.secondary.opacity(0.12))
                                    .cornerRadius(6)
                            }
                        }
                    }

                    // Optioneel voor Balzakken: Balzak 👑 & Valse Balzak ⚠️ tellers
                    if gameName.caseInsensitiveCompare("Balzakken") == .orderedSame {
                        Divider()
                            .padding(.vertical, 2)

                        HStack(spacing: 16) {
                            // Juiste Balzak
                            HStack(spacing: 6) {
                                Text("👑 Balzakken:")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)

                                Button(action: {
                                    if idx < juisteBalzakken.count && juisteBalzakken[idx] > 0 {
                                        juisteBalzakken[idx] -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Text("\(juisteBalzakken[safe: idx] ?? 0)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(minWidth: 16)

                                Button(action: {
                                    if idx < juisteBalzakken.count {
                                        juisteBalzakken[idx] += 1
                                    }
                                }) {
                                    Image(systemName: "plus.circle")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }

                            Spacer()

                            // Valse Balzak
                            HStack(spacing: 6) {
                                Text("⚠️ Vals:")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)

                                Button(action: {
                                    if idx < fouteBalzakken.count && fouteBalzakken[idx] > 0 {
                                        fouteBalzakken[idx] -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Text("\(fouteBalzakken[safe: idx] ?? 0)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(minWidth: 16)

                                Button(action: {
                                    if idx < fouteBalzakken.count {
                                        fouteBalzakken[idx] += 1
                                    }
                                }) {
                                    Image(systemName: "plus.circle")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
                .padding(.horizontal)
            }
        }
    }

    private var submitButton: some View {
        Button(action: {
            HapticManager.shared.medium()
            bepaalWinnaarEnGaVerder()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                Text("Bekijk Uitslag & Winnaar")
            }
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeColor)
            .cornerRadius(14)
            .shadow(color: themeColor.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .padding(.horizontal)
    }

    // MARK: - Afronden & Winnaar

    private func bepaalWinnaarEnGaVerder() {
        guard !rankedIndices.isEmpty else { return }
        let topIndex = rankedIndices[0]

        if let teams = teamEntries, topIndex < teams.count {
            winnaarTeamName = teams[topIndex].teamName
        } else if topIndex < spelers.count {
            winnaarPlayer = Player(name: spelers[topIndex])
        }

        showWinnaarView = true
    }

    @ViewBuilder
    private var destinationWinnaarView: some View {
        let progression = buildQuickScoreProgression()

        if let teams = teamEntries {
            let sortedTeams = rankedIndices.compactMap { idx -> WinnaarTeamEntry? in
                guard idx < teams.count else { return nil }
                var entry = teams[idx]
                entry.score = scores[safe: idx] ?? 0
                entry.isWinner = (idx == rankedIndices.first)
                return entry
            }

            WinnaarView(
                gameName: gameName,
                winningTeamName: winnaarTeamName.isEmpty ? (sortedTeams.first?.teamName ?? "Winnaar") : winnaarTeamName,
                teams: sortedTeams,
                isLowestScoreWins: isLowestScoreWins,
                scoreProgression: progression,
                onReset: {
                    resetScores()
                    onReset?()
                }
            )
        } else {
            let sortedPlayers = rankedIndices.compactMap { idx -> Player? in
                guard idx < spelers.count else { return nil }
                return Player(name: spelers[idx])
            }
            let sortedScores = rankedIndices.compactMap { idx -> Int? in
                scores[safe: idx] ?? 0
            }

            WinnaarView(
                gameName: gameName,
                winnaar: winnaarPlayer,
                sortedSpelers: sortedPlayers,
                sortedScores: sortedScores,
                isLowestScoreWins: isLowestScoreWins,
                juisteBalzakken: gameName.caseInsensitiveCompare("Balzakken") == .orderedSame ? rankedIndices.map { juisteBalzakken[safe: $0] ?? 0 } : nil,
                fouteBalzakken: gameName.caseInsensitiveCompare("Balzakken") == .orderedSame ? rankedIndices.map { fouteBalzakken[safe: $0] ?? 0 } : nil,
                scoreProgression: progression,
                onReset: {
                    resetScores()
                    onReset?()
                }
            )
        }
    }

    private func buildQuickScoreProgression() -> [RoundScoreDataPoint] {
        var points: [RoundScoreDataPoint] = []
        for idx in 0..<itemCount {
            let name = itemName(at: idx)
            let finalScore = scores[safe: idx] ?? 0
            points.append(RoundScoreDataPoint(roundNumber: 0, roundLabel: "Start", playerName: name, score: 0))
            points.append(RoundScoreDataPoint(roundNumber: 1, roundLabel: "Eindstand", playerName: name, score: finalScore))
        }
        return points
    }

    private func resetScores() {
        scores = Array(repeating: initialScore, count: itemCount)
        juisteBalzakken = Array(repeating: 0, count: itemCount)
        fouteBalzakken = Array(repeating: 0, count: itemCount)
        showWinnaarView = false
    }
}
