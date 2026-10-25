import SwiftUI

struct QuickstopRondeEntry: Identifiable {
    var id: Int { ronde }
    let ronde: Int
    let starter: String
    let scoresDezeRonde: [Int]
    let totalenNaRonde: [Int]
}

struct QuickstopGameView: View {
    let spelers: [String]
    let limietStrafpunten: Int

    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var huidigeRonde: Int = 1
    @State private var rondeScores: [Int]
    @State private var totaleScores: [Int]
    @State private var rondeGeschiedenis: [QuickstopRondeEntry] = []
    @State private var startSpelerIndex: Int = 0

    @State private var showWinnaarView: Bool = false
    @State private var winnaarPlayer: Player = Player(name: "")
    @State private var toonGeschiedenisSheet: Bool = false
    @State private var showFinishConfirm: Bool = false
    @State private var restoreTargetEntry: QuickstopRondeEntry? = nil
    @State private var showRestoreDialog: Bool = false

    // Thema inspiratie generator
    @State private var huidigeThema: String = "Iets wat in de koelkast staat"
    @State private var toonThemaKaart: Bool = true

    private let themas: [String] = [
        "Iets wat in de koelkast staat",
        "Een dier met 4 poten",
        "Iets wat geel is",
        "Een land of bekende stad",
        "Iets wat je op vakantie meeneemt",
        "Een beroep of baan",
        "Iets wat veel lawaai maakt",
        "Een voorwerp in de badkamer",
        "Iets wat kleiner is dan een appel",
        "Een bekende film of serie",
        "Iets wat stinkt",
        "Een sport of hobby",
        "Iets wat zacht is",
        "Een merk of winkel",
        "Iets wat je op school of werk gebruikt",
        "Een groente of fruitsoort",
        "Iets wat van hout is gemaakt",
        "Een kledingstuk of accessoire",
        "Iets wat warm is",
        "Een bekend persoon of personage",
        "Iets wat je in de supermarkt koopt",
        "Een muziekinstrument",
        "Iets wat kan vliegen",
        "Iets wat rond is",
        "Een vervoermiddel"
    ]

    init(spelers: [String], limietStrafpunten: Int = 40) {
        self.spelers = spelers
        self.limietStrafpunten = limietStrafpunten
        _rondeScores = State(initialValue: Array(repeating: 0, count: spelers.count))
        _totaleScores = State(initialValue: Array(repeating: 0, count: spelers.count))
    }

    private var huidigeStarterIndex: Int {
        guard !spelers.isEmpty else { return 0 }
        return (startSpelerIndex + (huidigeRonde - 1)) % spelers.count
    }

    private var huidigeLeider: String {
        guard !spelers.isEmpty else { return "" }
        let minScore = totaleScores.min() ?? 0
        if let idx = totaleScores.firstIndex(of: minScore) {
            return spelers[idx]
        }
        return ""
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                headerView

                // Startspeler / Thema voorlezer banner
                readerBanner

                // Thema generator kaart
                if toonThemaKaart {
                    themeGeneratorCard
                }

                // Spelers Kaartenlijst
                playersList

                // Ronde Voltooien Knop
                finishRoundButton

                // Extra actieknoppen (Geschiedenis & Stop)
                secondaryActionButtons
            }
            .padding(.vertical)
        }
        .navigationTitle("Quickstop")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { toonGeschiedenisSheet = true }) {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
        }
        .sheet(isPresented: $toonGeschiedenisSheet) {
            historySheet
        }
        .navigationDestination(isPresented: $showWinnaarView) {
            WinnaarView(
                gameName: "Quickstop",
                winnaar: winnaarPlayer,
                sortedSpelers: sortedPlayers,
                sortedScores: sortedScores,
                isLowestScoreWins: true,
                onReset: {
                    resetGame()
                }
            )
        }
        .confirmationDialog("Spel beëindigen?", isPresented: $showFinishConfirm, titleVisibility: .visible) {
            Button("Uitslag bekijken (huidige stand)") {
                finalizeGame()
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            Text("De speler met de minste strafpunten (bliksems ⚡️) wint!")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            if UIImage(named: "Quickstop") != nil {
                Image("Quickstop")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: .red.opacity(0.3), radius: 3, x: 0, y: 1)
            } else {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 32))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Ronde \(huidigeRonde)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Einde bij \(limietStrafpunten) strafpunten ⚡️ • Minste wint!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !huidigeLeider.isEmpty {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Leider")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(huidigeLeider)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.12))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // MARK: - Thema Voorlezer Banner

    private var readerBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.wave.2.fill")
                .foregroundColor(.orange)
                .font(.system(size: 16, weight: .bold))

            VStack(alignment: .leading, spacing: 2) {
                Text("Leest eerste thema voor:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(spelers[safe: huidigeStarterIndex] ?? "")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Spacer()

            if huidigeRonde == 1 {
                Button(action: {
                    withAnimation {
                        startSpelerIndex = Int.random(in: 0..<max(1, spelers.count))
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "dice.fill")
                        Text("Kies willekeurig")
                    }
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Thema Kaart Generator

    private var themeGeneratorCard: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Thema Inspiratie", systemImage: "sparkles")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .textCase(.uppercase)

                Spacer()

                Button(action: {
                    withAnimation {
                        if let random = themas.randomElement() {
                            huidigeThema = random
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Nieuw thema")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                }
            }

            Text("\"\(huidigeThema)\"")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Spelers Lijst

    private var playersList: some View {
        VStack(spacing: 12) {
            ForEach(spelers.indices, id: \.self) { idx in
                let total = totaleScores[idx]
                let currentRound = rondeScores[idx]
                let projectedTotal = total + currentRound
                let isWinnerOfRound = currentRound == 0
                let progress = min(1.0, Double(projectedTotal) / Double(limietStrafpunten))
                let isDanger = projectedTotal >= limietStrafpunten

                VStack(spacing: 10) {
                    // Speler Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(spelers[idx])
                                    .font(.headline)

                                if isDanger {
                                    Text("⚠️ LIMIET!")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }

                            Text("Totaal tot nu: \(total) ⚡️  ➔  Na ronde: \(projectedTotal) ⚡️")
                                .font(.caption2)
                                .foregroundColor(isDanger ? .red : .secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(projectedTotal) ⚡️")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(isDanger ? .red : (total == 0 ? .green : .primary))

                            Text("van de \(limietStrafpunten)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Voortgangsbalk richting limiet
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 6)

                            Capsule()
                                .fill(progressColor(for: progress))
                                .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 6)
                                .animation(.spring(), value: progress)
                        }
                    }
                    .frame(height: 6)

                    Divider()

                    // Ronde Strafpunten Invoer
                    HStack(spacing: 6) {
                        // Knop: Kaarten weggespeeld (0 pt)
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            rondeScores[idx] = 0
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                Text("0 pt (Weg!)")
                            }
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 7)
                            .background(isWinnerOfRound ? Color.green : Color.secondary.opacity(0.12))
                            .foregroundColor(isWinnerOfRound ? .white : .primary)
                            .cornerRadius(8)
                        }

                        Spacer()

                        // Steppers
                        Button(action: {
                            if rondeScores[idx] > 0 { rondeScores[idx] -= 1 }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(rondeScores[idx] > 0 ? .red : .secondary.opacity(0.3))
                        }
                        .disabled(rondeScores[idx] <= 0)

                        // Numeriek invoerveld met cijfertoetsenbord
                        NumericScoreInputView(
                            score: $rondeScores[idx],
                            allowNegative: false,
                            range: 0...50,
                            tintColor: .orange,
                            minWidth: 44,
                            height: 32,
                            font: .subheadline
                        )

                        Button(action: {
                            rondeScores[idx] += 1
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                        }

                        Button(action: {
                            rondeScores[idx] += 2
                        }) {
                            Text("+2")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(6)
                        }

                        Button(action: {
                            rondeScores[idx] += 5
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
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isDanger ? Color.red.opacity(0.4) : Color.clear, lineWidth: 1.5)
                )
                .padding(.horizontal)
            }
        }
    }

    private func progressColor(for progress: Double) -> Color {
        if progress >= 1.0 { return .red }
        if progress >= 0.75 { return .orange }
        if progress >= 0.5 { return .yellow }
        return .green
    }

    // MARK: - Ronde Voltooien Knop

    private var finishRoundButton: some View {
        Button(action: {
            completeRound()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("Ronde \(huidigeRonde) Voltooien")
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
        .padding(.top, 4)
    }

    // MARK: - Extra Actieknoppen

    private var secondaryActionButtons: some View {
        HStack(spacing: 12) {
            Button(action: { toonGeschiedenisSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet.clipboard")
                    Text("Geschiedenis (\(rondeGeschiedenis.count))")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(10)
            }

            Button(action: { showFinishConfirm = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "flag.checkered")
                    Text("Spel Beëindigen")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Logica

    private func completeRound() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        var newTotals = totaleScores
        for i in spelers.indices {
            newTotals[i] += rondeScores[i]
        }

        let entry = QuickstopRondeEntry(
            ronde: huidigeRonde,
            starter: spelers[safe: huidigeStarterIndex] ?? "",
            scoresDezeRonde: rondeScores,
            totalenNaRonde: newTotals
        )
        rondeGeschiedenis.append(entry)
        totaleScores = newTotals

        // Controleer of iemand de limiet bereikt heeft
        let isGameFinished = newTotals.contains(where: { $0 >= limietStrafpunten })

        if isGameFinished {
            finalizeGame()
        } else {
            huidigeRonde += 1
            rondeScores = Array(repeating: 0, count: spelers.count)
            // Vernieuw het thema voor de nieuwe ronde
            if let random = themas.randomElement() {
                huidigeThema = random
            }
        }
    }

    private func finalizeGame() {
        guard let lowest = sortedPlayers.first else { return }
        winnaarPlayer = lowest

        let detailed = spelers.indices.map { i in
            (name: spelers[i], score: totaleScores[i])
        }
        scoreManager.saveGame(gameName: "Quickstop", playerScores: detailed, winnerName: lowest.name)
        showWinnaarView = true
    }

    private var sortedPlayers: [Player] {
        let pairs = spelers.indices.map { i in
            (player: Player(name: spelers[i]), score: totaleScores[i])
        }
        // Minste strafpunten wint!
        return pairs.sorted { $0.score < $1.score }.map { $0.player }
    }

    private var sortedScores: [Int] {
        let pairs = spelers.indices.map { i in
            (player: Player(name: spelers[i]), score: totaleScores[i])
        }
        return pairs.sorted { $0.score < $1.score }.map { $0.score }
    }

    // MARK: - Geschiedenis Sheet

    private var historySheet: some View {
        NavigationStack {
            List {
                if rondeGeschiedenis.isEmpty {
                    Text("Er zijn nog geen voltooide rondes.")
                        .foregroundColor(.secondary)
                } else {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.yellow)
                            Text("Houd een ronde ingedrukt om punten te herstellen.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    ForEach(rondeGeschiedenis) { entry in
                        Section(header:
                            HStack {
                                Text("Ronde \(entry.ronde) • Starter: \(entry.starter)")
                                Spacer()
                                Button(action: {
                                    restoreTargetEntry = entry
                                    showRestoreDialog = true
                                }) {
                                    Label("Herstel", systemImage: "arrow.uturn.backward.circle")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        ) {
                            ForEach(spelers.indices, id: \.self) { idx in
                                HStack {
                                    Text(spelers[idx])
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("+\(entry.scoresDezeRonde[safe: idx] ?? 0) ⚡️")
                                        .foregroundColor(entry.scoresDezeRonde[safe: idx] == 0 ? .green : .red)
                                        .font(.caption)
                                    Text("Totaal: \(entry.totalenNaRonde[safe: idx] ?? 0)")
                                        .fontWeight(.bold)
                                        .frame(minWidth: 70, alignment: .trailing)
                                }
                            }
                            .contentShape(Rectangle())
                            .onLongPressGesture {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                restoreTargetEntry = entry
                                showRestoreDialog = true
                            }
                            .contextMenu {
                                Button(role: .destructive, action: {
                                    herstelNaarStartVanRonde(entry)
                                }) {
                                    Label("Herstel naar start van Ronde \(entry.ronde)", systemImage: "arrow.uturn.backward")
                                }
                                Button(action: {
                                    herstelNaarEindeVanRonde(entry)
                                }) {
                                    Label("Herstel naar einde van Ronde \(entry.ronde)", systemImage: "arrow.uturn.forward")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rondegeschiedenis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klaar") { toonGeschiedenisSheet = false }
                }
            }
            .confirmationDialog(
                "Herstel Ronde \(restoreTargetEntry?.ronde ?? 1)?",
                isPresented: $showRestoreDialog,
                titleVisibility: .visible
            ) {
                if let entry = restoreTargetEntry {
                    Button("Herstel naar start van Ronde \(entry.ronde) (Wis deze ronde)", role: .destructive) {
                        herstelNaarStartVanRonde(entry)
                    }
                    Button("Zet stand terug naar na Ronde \(entry.ronde)") {
                        herstelNaarEindeVanRonde(entry)
                    }
                    Button("Annuleren", role: .cancel) {}
                }
            } message: {
                if let entry = restoreTargetEntry {
                    Text("Wil je de scores en rondeteller terugzetten naar ronde \(entry.ronde)?")
                }
            }
        }
    }

    private func herstelNaarStartVanRonde(_ entry: QuickstopRondeEntry) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        var vorigTotaleScores = entry.totalenNaRonde
        for i in vorigTotaleScores.indices {
            vorigTotaleScores[i] -= (entry.scoresDezeRonde[safe: i] ?? 0)
        }
        totaleScores = vorigTotaleScores
        rondeScores = Array(repeating: 0, count: spelers.count)
        huidigeRonde = entry.ronde
        rondeGeschiedenis.removeAll { $0.ronde >= entry.ronde }
        toonGeschiedenisSheet = false
    }

    private func herstelNaarEindeVanRonde(_ entry: QuickstopRondeEntry) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        totaleScores = entry.totalenNaRonde
        rondeScores = Array(repeating: 0, count: spelers.count)
        huidigeRonde = entry.ronde + 1
        rondeGeschiedenis.removeAll { $0.ronde > entry.ronde }
        toonGeschiedenisSheet = false
    }

    private func resetGame() {
        totaleScores = Array(repeating: 0, count: spelers.count)
        rondeScores = Array(repeating: 0, count: spelers.count)
        huidigeRonde = 1
        rondeGeschiedenis = []
        startSpelerIndex = 0
        winnaarPlayer = Player(name: "")
        showWinnaarView = false
    }
}

#Preview {
    NavigationStack {
        QuickstopGameView(spelers: ["Niels", "Lisa", "Tom"], limietStrafpunten: 40)
    }
}
