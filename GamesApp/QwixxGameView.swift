import SwiftUI

struct QwixxPlayerScore {
    var red: Int = 0        // 0..12
    var yellow: Int = 0     // 0..12
    var green: Int = 0      // 0..12
    var blue: Int = 0       // 0..12
    var misworpen: Int = 0  // 0..4
    var directScore: Int = 0

    static func points(for crosses: Int) -> Int {
        guard crosses > 0 else { return 0 }
        return (crosses * (crosses + 1)) / 2
    }

    func calculatedTotal() -> Int {
        let r = Self.points(for: red)
        let y = Self.points(for: yellow)
        let g = Self.points(for: green)
        let b = Self.points(for: blue)
        let mis = misworpen * 5
        return r + y + g + b - mis
    }
}

struct QwixxGameView: View {
    let spelers: [String]
    let initialMode: QwixxSetupView.QwixxScoreMode

    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var currentMode: QwixxSetupView.QwixxScoreMode
    @State private var playerScores: [QwixxPlayerScore]
    @State private var selectedPlayerIndex: Int = 0
    @State private var showWinnaarView: Bool = false
    @State private var winnaarPlayer: Player = Player(name: "")

    init(spelers: [String], initialMode: QwixxSetupView.QwixxScoreMode) {
        self.spelers = spelers
        self.initialMode = initialMode
        _currentMode = State(initialValue: initialMode)
        _playerScores = State(initialValue: Array(repeating: QwixxPlayerScore(), count: spelers.count))
    }

    private func effectiveScore(for index: Int) -> Int {
        guard let p = playerScores[safe: index] else { return 0 }
        return currentMode == .formulier ? p.calculatedTotal() : p.directScore
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                headerView

                // Modus Wisselaar
                modeSwitchBar

                if currentMode == .formulier {
                    // Formulier weergave met spelers selector
                    formModeView
                } else {
                    // Directe score weergave
                    directModeView
                }

                Spacer(minLength: 20)

                // Spel Voltooien knop
                finishButton
            }
            .padding(.vertical)
        }
        .navigationTitle("Qwixx")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showWinnaarView) {
            WinnaarView(
                gameName: "Qwixx",
                winnaar: winnaarPlayer,
                sortedSpelers: sortedPlayers,
                sortedScores: sortedScores,
                isLowestScoreWins: false
            )
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            if UIImage(named: "Qwixx") != nil {
                Image("Qwixx")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: .orange.opacity(0.3), radius: 3, x: 0, y: 1)
            } else {
                Image(systemName: "dice.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 32))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Qwixx Score")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(currentMode == .formulier ? "Scoreformulier per speler" : "Directe totaalscores")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // MARK: - Modus Wisselaar

    private var modeSwitchBar: some View {
        Picker("Telmodus", selection: $currentMode) {
            ForEach(QwixxSetupView.QwixxScoreMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    // MARK: - Formulier Weergave

    private var formModeView: some View {
        VStack(spacing: 16) {
            // Speler Selector Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(spelers.indices, id: \.self) { idx in
                        let isSelected = selectedPlayerIndex == idx
                        let total = effectiveScore(for: idx)

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation { selectedPlayerIndex = idx }
                        }) {
                            VStack(spacing: 4) {
                                Text(spelers[idx])
                                    .font(.subheadline)
                                    .fontWeight(isSelected ? .bold : .medium)

                                Text("\(total) pt")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(isSelected ? .white : .orange)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.orange : Color(UIColor.secondarySystemGroupedBackground))
                            .foregroundColor(isSelected ? .white : .primary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.orange : Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            // Actieve Speler Formulier Kaart
            if let activePlayer = spelers[safe: selectedPlayerIndex] {
                VStack(spacing: 14) {
                    // Speler Titel & Totaal
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Scoreblad van \(activePlayer)")
                                .font(.headline)
                            Text("Kruisjes per kleurrij (1x=1pt, 2x=3pt, ..., 12x=78pt)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(playerScores[selectedPlayerIndex].calculatedTotal()) pt")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("Totaal")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // 4 Kleuren Rijen
                    colorRowView(title: "Rood (2 ➔ 12)", color: .red, crosses: $playerScores[selectedPlayerIndex].red)
                    colorRowView(title: "Geel (2 ➔ 12)", color: .yellow, crosses: $playerScores[selectedPlayerIndex].yellow, isDarkText: true)
                    colorRowView(title: "Groen (12 ➔ 2)", color: .green, crosses: $playerScores[selectedPlayerIndex].green)
                    colorRowView(title: "Blauw (12 ➔ 2)", color: .blue, crosses: $playerScores[selectedPlayerIndex].blue)

                    // Misworpen Rij (-5 pt per stuk)
                    misworpenRowView(misworpen: $playerScores[selectedPlayerIndex].misworpen)

                    // Subtotaal Overzicht
                    scoreBreakdownBanner(p: playerScores[selectedPlayerIndex])
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Kleurrij Component

    private func colorRowView(title: String, color: Color, crosses: Binding<Int>, isDarkText: Bool = false) -> some View {
        let pts = QwixxPlayerScore.points(for: crosses.wrappedValue)

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 34, height: 34)
                Text("\(crosses.wrappedValue)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isDarkText ? .black : .white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(crosses.wrappedValue == 0 ? "0 kruisjes (0 pt)" : "\(crosses.wrappedValue) kruisjes = +\(pts) pt")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Stepper knoppen
            HStack(spacing: 8) {
                Button(action: {
                    if crosses.wrappedValue > 0 { crosses.wrappedValue -= 1 }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(crosses.wrappedValue > 0 ? color : .secondary.opacity(0.3))
                }
                .disabled(crosses.wrappedValue <= 0)

                Text("\(crosses.wrappedValue)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(minWidth: 24)

                Button(action: {
                    if crosses.wrappedValue < 12 { crosses.wrappedValue += 1 }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(crosses.wrappedValue < 12 ? color : .secondary.opacity(0.3))
                }
                .disabled(crosses.wrappedValue >= 12)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Misworpen Rij

    private func misworpenRowView(misworpen: Binding<Int>) -> some View {
        let penalty = misworpen.wrappedValue * 5

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 34, height: 34)
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.red)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Mislukte worpen")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(misworpen.wrappedValue == 0 ? "Geen misworpen (0 pt)" : "\(misworpen.wrappedValue)x = -\(penalty) pt")
                    .font(.caption2)
                    .foregroundColor(misworpen.wrappedValue > 0 ? .red : .secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: {
                    if misworpen.wrappedValue > 0 { misworpen.wrappedValue -= 1 }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(misworpen.wrappedValue > 0 ? .red : .secondary.opacity(0.3))
                }
                .disabled(misworpen.wrappedValue <= 0)

                Text("\(misworpen.wrappedValue)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(minWidth: 24)

                Button(action: {
                    if misworpen.wrappedValue < 4 { misworpen.wrappedValue += 1 }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(misworpen.wrappedValue < 4 ? .red : .secondary.opacity(0.3))
                }
                .disabled(misworpen.wrappedValue >= 4)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Subtotaal Banner

    private func scoreBreakdownBanner(p: QwixxPlayerScore) -> some View {
        let r = QwixxPlayerScore.points(for: p.red)
        let y = QwixxPlayerScore.points(for: p.yellow)
        let g = QwixxPlayerScore.points(for: p.green)
        let b = QwixxPlayerScore.points(for: p.blue)
        let m = p.misworpen * 5

        return HStack(spacing: 6) {
            Text("\(r)").foregroundColor(.red).fontWeight(.bold)
            Text("+").foregroundColor(.secondary)
            Text("\(y)").foregroundColor(.orange).fontWeight(.bold)
            Text("+").foregroundColor(.secondary)
            Text("\(g)").foregroundColor(.green).fontWeight(.bold)
            Text("+").foregroundColor(.secondary)
            Text("\(b)").foregroundColor(.blue).fontWeight(.bold)
            Text("-").foregroundColor(.secondary)
            Text("\(m)").foregroundColor(.red).fontWeight(.bold)
            Text("=").foregroundColor(.secondary)
            Text("\(p.calculatedTotal()) pt").foregroundColor(.primary).fontWeight(.bold)
        }
        .font(.caption)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(10)
    }

    // MARK: - Directe Score Weergave

    private var directModeView: some View {
        VStack(spacing: 12) {
            ForEach(spelers.indices, id: \.self) { idx in
                HStack(spacing: 14) {
                    Text(spelers[idx])
                        .font(.headline)

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: {
                            if playerScores[idx].directScore >= 5 {
                                playerScores[idx].directScore -= 5
                            }
                        }) {
                            Text("-5")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(6)
                        }

                        Button(action: {
                            if playerScores[idx].directScore > 0 {
                                playerScores[idx].directScore -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                        }

                        Text("\(playerScores[idx].directScore)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(minWidth: 40)

                        Button(action: {
                            playerScores[idx].directScore += 1
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        }

                        Button(action: {
                            playerScores[idx].directScore += 5
                        }) {
                            Text("+5")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Voltooien Knop

    private var finishButton: some View {
        Button(action: {
            finalizeGame()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                Text("Spel Voltooien & Uitslag Bekijken")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .cornerRadius(14)
            .shadow(color: Color.orange.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .padding(.horizontal)
    }

    private func finalizeGame() {
        guard let highest = sortedPlayers.first else { return }
        winnaarPlayer = highest

        let detailed = spelers.indices.map { i in
            (name: spelers[i], score: effectiveScore(for: i))
        }
        scoreManager.saveGame(gameName: "Qwixx", playerScores: detailed, winnerName: highest.name)
        showWinnaarView = true
    }

    private var sortedPlayers: [Player] {
        let pairs = spelers.indices.map { i in
            (player: Player(name: spelers[i]), score: effectiveScore(for: i))
        }
        return pairs.sorted { $0.score > $1.score }.map { $0.player }
    }

    private var sortedScores: [Int] {
        let pairs = spelers.indices.map { i in
            (player: Player(name: spelers[i]), score: effectiveScore(for: i))
        }
        return pairs.sorted { $0.score > $1.score }.map { $0.score }
    }
}

#Preview {
    NavigationStack {
        QwixxGameView(spelers: ["Niels", "Lisa", "Tom"], initialMode: .formulier)
    }
}
