import SwiftUI

struct WinnaarTeamEntry: Identifiable {
    var id: UUID = UUID()
    let teamName: String
    let playerNames: [String]
    var score: Int
    var isWinner: Bool
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
    var scoreProgression: [RoundScoreDataPoint]? = nil
    var crokinoleStats: CrokinoleGameStats? = nil
    var onReset: (() -> Void)? = nil

    @State private var isScoreOpgeslagen = false
    @State private var showStatsSheet = false
    @Environment(\.dismiss) private var dismiss
    private let scoreManager = ScoreManager.shared

    init(
        winnaar: Player,
        sortedSpelers: [Player],
        sortedScores: [Int],
        gameName: String = "Nmbr9",
        isLowestScoreWins: Bool = false,
        scoreProgression: [RoundScoreDataPoint]? = nil,
        crokinoleStats: CrokinoleGameStats? = nil,
        onReset: (() -> Void)? = nil
    ) {
        self.winnaar = winnaar
        self.sortedSpelers = sortedSpelers
        self.sortedScores = sortedScores
        self.gameName = gameName
        self.isLowestScoreWins = isLowestScoreWins
        self.scoreProgression = scoreProgression
        self.crokinoleStats = crokinoleStats
        self.onReset = onReset
    }

    init(
        gameName: String,
        winnaar: Player,
        sortedSpelers: [Player],
        sortedScores: [Int],
        isLowestScoreWins: Bool = false,
        juisteBalzakken: [Int]? = nil,
        fouteBalzakken: [Int]? = nil,
        scoreProgression: [RoundScoreDataPoint]? = nil,
        crokinoleStats: CrokinoleGameStats? = nil,
        onReset: (() -> Void)? = nil
    ) {
        self.gameName = gameName
        self.winnaar = winnaar
        self.sortedSpelers = sortedSpelers
        self.sortedScores = sortedScores
        self.isLowestScoreWins = isLowestScoreWins
        self.juisteBalzakken = juisteBalzakken
        self.fouteBalzakken = fouteBalzakken
        self.scoreProgression = scoreProgression
        self.crokinoleStats = crokinoleStats
        self.onReset = onReset
    }

    init(
        gameName: String,
        winnaarNaam: String,
        spelersNamen: [String],
        scores: [Int],
        isLowestScoreWins: Bool = false,
        scoreProgression: [RoundScoreDataPoint]? = nil,
        crokinoleStats: CrokinoleGameStats? = nil,
        onReset: (() -> Void)? = nil
    ) {
        self.gameName = gameName
        self.winnaar = Player(name: winnaarNaam)
        self.sortedSpelers = spelersNamen.map { Player(name: $0) }
        self.sortedScores = scores
        self.isLowestScoreWins = isLowestScoreWins
        self.scoreProgression = scoreProgression
        self.crokinoleStats = crokinoleStats
        self.onReset = onReset
    }

    init(
        gameName: String,
        winningTeamName: String,
        teams: [WinnaarTeamEntry],
        isLowestScoreWins: Bool = false,
        scoreProgression: [RoundScoreDataPoint]? = nil,
        crokinoleStats: CrokinoleGameStats? = nil,
        onReset: (() -> Void)? = nil
    ) {
        self.gameName = gameName
        self.winnaar = Player(name: winningTeamName)
        self.sortedSpelers = teams.flatMap { $0.playerNames.map { Player(name: $0) } }
        self.sortedScores = teams.flatMap { t in t.playerNames.map { _ in t.score } }
        self.isLowestScoreWins = isLowestScoreWins
        self.teamEntries = teams
        self.scoreProgression = scoreProgression
        self.crokinoleStats = crokinoleStats
        self.onReset = onReset
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
            if t1.isWinner != t2.isWinner {
                return t1.isWinner
            }
            if isLowestScoreWins {
                return t1.score < t2.score
            } else {
                return t1.score > t2.score
            }
        }
    }

    private var winnerScoreValue: Int? {
        if let first = rankedIndices.first {
            return sortedScores[safe: first]
        }
        return nil
    }

    private func scoreUnit(for score: Int) -> String {
        if gameName == "Regenwormen" {
            return score == 1 ? "worm" : "wormen"
        }
        if gameName.localizedCaseInsensitiveContains("crok") {
            return "sets"
        }
        return score == 1 ? "punt" : "punten"
    }

    private func rankMedal(_ rank: Int) -> String {
        switch rank {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(rank + 1)."
        }
    }

    private var effectiveProgression: [RoundScoreDataPoint] {
        if let points = scoreProgression, !points.isEmpty {
            return points
        }
        var points: [RoundScoreDataPoint] = []
        for (idx, speler) in sortedSpelers.enumerated() {
            let score = sortedScores[safe: idx] ?? 0
            points.append(RoundScoreDataPoint(round: 0, playerName: speler.name, cumulativeScore: 0))
            points.append(RoundScoreDataPoint(round: 1, playerName: speler.name, cumulativeScore: score))
        }
        return points
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Spelnaam subtiel bovenaan
                Text(gameName)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                // Feestelijke Winnaar Card
                winnerBanner

                // Score automatisch opgeslagen badge
                savedStatusBadge

                // Eindstand uitslagenlijst
                rankingsSection

                // Crokinole Highlights (indien beschikbaar)
                if let crok = crokinoleStats {
                    crokinoleHighlightsView(crok)
                }

                // Scoreverloop grafiek (PROMINENT & DUIDELIJK)
                scoreProgressionSection

                // Drie keuzeknoppen
                actionButtons
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showStatsSheet) {
            StatisticsView(isSheet: true, initialSegment: .perSpel, initialGame: gameName)
        }
        .onAppear {
            autoSaveScore()
            HapticManager.shared.celebration()
        }
    }

    // MARK: - Subviews

    private var winnerBanner: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text("🏆")
                    .font(.title2)
                Text(teamEntries != nil ? "WINNEND TEAM" : "WINNAAR")
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundColor(.black.opacity(0.65))
                    .tracking(1.0)
            }

            Text(winnaar.name)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)

            if let teams = teamEntries, let winTeam = teams.first(where: { $0.isWinner }) {
                Text(winTeam.playerNames.joined(separator: " & "))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black.opacity(0.8))
            } else if let winnerScore = winnerScoreValue {
                Text("\(winnerScore) \(scoreUnit(for: winnerScore))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black.opacity(0.85))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.yellow, Color.orange.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(18)
        .shadow(color: Color.orange.opacity(0.35), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }

    private var savedStatusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.subheadline)
            Text("Score automatisch opgeslagen in statistieken")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.green.opacity(0.12))
        .clipShape(Capsule())
    }

    private var rankingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "list.number")
                    .foregroundColor(.blue)
                Text("Eindstand")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                if teamEntries != nil {
                    ForEach(Array(rankedTeams.enumerated()), id: \.element.id) { idx, team in
                        HStack(spacing: 12) {
                            Text(rankMedal(idx))
                                .font(.title3)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(team.teamName)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    if team.isWinner {
                                        Text("WINNAAR")
                                            .font(.system(size: 9, weight: .black))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.yellow)
                                            .foregroundColor(.black)
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(team.playerNames.joined(separator: " & "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            let unit = gameName.localizedCaseInsensitiveContains("crok") ? "sets" : "pt"
                            Text("\(team.score) \(unit)")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)

                        if idx < rankedTeams.count - 1 {
                            Divider()
                                .padding(.leading, 58)
                        }
                    }
                } else {
                    ForEach(Array(rankedIndices.enumerated()), id: \.offset) { rankIdx, playerIdx in
                        let speler = sortedSpelers[playerIdx]
                        let score = sortedScores[safe: playerIdx] ?? 0

                        HStack(spacing: 12) {
                            Text(rankMedal(rankIdx))
                                .font(.title3)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(speler.name)
                                    .font(.headline)
                                    .fontWeight(.bold)

                                if let j = juisteBalzakken?[safe: playerIdx], let f = fouteBalzakken?[safe: playerIdx], (j > 0 || f > 0) {
                                    Text("🎯 \(j) Balzak\(j == 1 ? "" : "ken") • ⚠️ \(f) Valse")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            if gameName == "Jatten" {
                                if speler.name == winnaar.name {
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
                                HStack(spacing: 4) {
                                    Text("\(score)")
                                        .font(.headline)
                                        .fontWeight(.heavy)
                                        .foregroundColor(.primary)
                                    Text(scoreUnit(for: score))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)

                        if rankIdx < rankedIndices.count - 1 {
                            Divider()
                                .padding(.leading, 58)
                        }
                    }
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }

    private var scoreProgressionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScoreProgressionChartView(
                title: "\(gameName) Scoreverloop",
                dataPoints: effectiveProgression,
                playerNames: sortedSpelers.map { $0.name },
                chartHeight: 220
            )
        }
        .padding(.horizontal)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Knop 1: Opnieuw spelen
            Button(action: {
                autoSaveScore()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onReset?()
                dismiss()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.title3)
                    Text("Opnieuw spelen")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(14)
                .shadow(color: Color.blue.opacity(0.25), radius: 6, x: 0, y: 3)
            }

            // Knop 2: Statistieken zien
            Button(action: {
                autoSaveScore()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showStatsSheet = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.title3)
                    Text("Statistieken zien")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.purple)
                .cornerRadius(14)
                .shadow(color: Color.purple.opacity(0.25), radius: 6, x: 0, y: 3)
            }

            // Knop 3: Klaar (navigeert terug naar het spellenoverzicht)
            Button(action: {
                autoSaveScore()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onReset?()
                ActiveGameManager.shared.clearActiveGame()
                NavigationUtil.popToRoot()
                dismiss()
            }) {
                Text("Klaar")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red)
                    .cornerRadius(14)
                    .shadow(color: Color.red.opacity(0.25), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 20)
    }

    private func crokinoleHighlightsView(_ crok: CrokinoleGameStats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "circle.circle.fill")
                    .foregroundColor(.blue)
                Text("Crokinole Wedstrijd-Highlights")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HOOGSTE IN 1 RONDE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.orange)
                    Text("\(crok.maxRoundScore) pt")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    Text("\(crok.maxRoundScorePlayer) • R\(crok.maxRoundScoreRound)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))

                VStack(alignment: .leading, spacing: 4) {
                    Text("HOOGSTE IN 1 SET")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.yellow.opacity(0.95))
                    Text("\(crok.maxSetScore) pt")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    Text("\(crok.maxSetScorePlayer)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.12))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(.horizontal)
    }

    private func autoSaveScore() {
        guard !isScoreOpgeslagen else { return }
        isScoreOpgeslagen = true
        if let teams = teamEntries {
            scoreManager.saveTeamGame(
                gameName: gameName,
                teams: teams.map { ($0.teamName, $0.playerNames, $0.score, $0.isWinner) },
                scoreProgression: effectiveProgression,
                crokinoleStats: crokinoleStats
            )
        } else {
            scoreManager.saveGame(
                gameName: gameName,
                players: sortedSpelers,
                scores: sortedScores,
                winner: winnaar,
                juisteBalzakken: juisteBalzakken,
                fouteBalzakken: fouteBalzakken,
                scoreProgression: effectiveProgression,
                crokinoleStats: crokinoleStats
            )
        }
    }
}

// MARK: - Navigation Utility to Pop Back to Root (Spellenoverzicht)

enum NavigationUtil {
    static func popToRoot() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? windowScene.windows.first?.rootViewController else {
            return
        }
        findNavigationController(from: rootVC)?.popToRootViewController(animated: true)
    }

    private static func findNavigationController(from vc: UIViewController) -> UINavigationController? {
        if let nav = vc as? UINavigationController {
            return nav
        }
        if let tab = vc as? UITabBarController {
            tab.selectedIndex = 0
            if let selected = tab.selectedViewController {
                return findNavigationController(from: selected)
            }
        }
        for child in vc.children {
            if let nav = findNavigationController(from: child) {
                return nav
            }
        }
        return nil
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
