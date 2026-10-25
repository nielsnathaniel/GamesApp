import SwiftUI

struct FiftyFiftyRondeEntry: Identifiable {
    var id: Int { ronde }
    let ronde: Int
    let starter: String
    let blauwDezeRonde: [Int]
    let geelDezeRonde: [Int]
    let totaleBlauwNaRonde: [Int]
    let totaleGeelNaRonde: [Int]
    let strafpuntenNaRonde: [Int]
}

struct FiftyFiftyGameView: View {
    let spelers: [String]
    let gameMode: FiftyFiftyGameMode
    let gebruikLimiet: Bool
    let limietStrafpunten: Int

    @ObservedObject private var scoreManager = ScoreManager.shared
    @ObservedObject private var activeGameManager = ActiveGameManager.shared

    @State private var huidigeRonde: Int = 1
    @State private var startSpelerIndex: Int = 0

    // Tokens per speler
    @State private var blauweTokens: [Int]
    @State private var geleTokens: [Int]

    // Invoer voor huidige ronde (bij modus 'Rondes & Slagen')
    @State private var rondeBlauw: [Int]
    @State private var rondeGeel: [Int]

    @State private var rondeGeschiedenis: [FiftyFiftyRondeEntry] = []
    @State private var showWinnaarView: Bool = false
    @State private var winnaarPlayer: Player = Player(name: "")
    @State private var toonGeschiedenisSheet: Bool = false
    @State private var showFinishConfirm: Bool = false
    @State private var restoreTargetEntry: FiftyFiftyRondeEntry? = nil
    @State private var showRestoreDialog: Bool = false

    init(
        spelers: [String],
        gameMode: FiftyFiftyGameMode = .rondes,
        gebruikLimiet: Bool = false,
        limietStrafpunten: Int = 15
    ) {
        self.spelers = spelers
        self.gameMode = gameMode
        self.gebruikLimiet = gebruikLimiet
        self.limietStrafpunten = limietStrafpunten

        _blauweTokens = State(initialValue: Array(repeating: 0, count: spelers.count))
        _geleTokens = State(initialValue: Array(repeating: 0, count: spelers.count))
        _rondeBlauw = State(initialValue: Array(repeating: 0, count: spelers.count))
        _rondeGeel = State(initialValue: Array(repeating: 0, count: spelers.count))
    }

    // MARK: - Berekeningen

    /// Bereken strafpunten per speler: 1 blauw en 1 geel heffen elkaar op -> abs(blauw - geel)
    private func strafpunten(voor index: Int) -> Int {
        guard index < blauweTokens.count && index < geleTokens.count else { return 0 }
        let totalBlauw = blauweTokens[index] + (gameMode == .rondes ? rondeBlauw[index] : 0)
        let totalGeel = geleTokens[index] + (gameMode == .rondes ? rondeGeel[index] : 0)
        return abs(totalBlauw - totalGeel)
    }

    private func isFiftyFifty(voor index: Int) -> Bool {
        guard index < blauweTokens.count && index < geleTokens.count else { return false }
        let totalBlauw = blauweTokens[index] + (gameMode == .rondes ? rondeBlauw[index] : 0)
        let totalGeel = geleTokens[index] + (gameMode == .rondes ? rondeGeel[index] : 0)
        return totalBlauw > 0 && totalBlauw == totalGeel
    }

    private var huidigeStarter: String {
        guard !spelers.isEmpty else { return "" }
        let idx = (startSpelerIndex + (huidigeRonde - 1)) % spelers.count
        return spelers[idx]
    }

    private var huidigeLeider: String {
        guard !spelers.isEmpty else { return "" }
        let straflijst = spelers.indices.map { strafpunten(voor: $0) }
        let minScore = straflijst.min() ?? 0
        if let idx = straflijst.firstIndex(of: minScore) {
            return spelers[idx]
        }
        return ""
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header statuskaart
                headerView

                // Startspeler banner
                starterBanner

                // Spelerslijst met live fiches en 50/50 balans
                playersList

                // Actieknoppen
                actionSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Fifty Fifty")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    HapticManager.shared.light()
                    toonGeschiedenisSheet = true
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $toonGeschiedenisSheet) {
            historySheet
        }
        .navigationDestination(isPresented: $showWinnaarView) {
            WinnaarView(
                gameName: "Fifty Fifty",
                winnaar: winnaarPlayer,
                sortedSpelers: sortedSpelersResultaat,
                sortedScores: sortedScoresResultaat,
                isLowestScoreWins: true,
                onReset: resetGame
            )
        }
        .confirmationDialog(
            "Spel Nu Afronden?",
            isPresented: $showFinishConfirm,
            titleVisibility: .visible
        ) {
            Button("Afronden en Winnaar Bekijken") {
                finishGame()
            }
            Button("Verder Spelen", role: .cancel) {}
        } message: {
            Text("De huidige stand wordt opgeslagen en de speler met de minste strafpunten wint.")
        }
        .confirmationDialog(
            "Ronde herstellen?",
            isPresented: $showRestoreDialog,
            titleVisibility: .visible
        ) {
            if let target = restoreTargetEntry {
                Button("Herstel naar Ronde \(target.ronde)", role: .destructive) {
                    restoreToRound(target)
                }
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            if let target = restoreTargetEntry {
                Text("De rondes na ronde \(target.ronde) worden teruggedraaid.")
            }
        }
        .onAppear {
            restoreDraftIfNeeded()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 12) {
            // Ronde indicator
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "circle.lefthalf.filled")
                        .foregroundColor(.blue)
                    Text("Ronde \(huidigeRonde)")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                if gebruikLimiet {
                    Text("Limiet: \(limietStrafpunten) strafpunten")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text(gameMode.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Leider badge
            if !huidigeLeider.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("Koploper")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }

                    Text(huidigeLeider)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Starter Banner

    private var starterBanner: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: "hand.point.right.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Startspeler deze slag:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(huidigeStarter)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Spacer()

            Button(action: {
                HapticManager.shared.light()
                startSpelerIndex = (startSpelerIndex + 1) % spelers.count
                saveDraft()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Wissel")
                }
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Spelers Kaartenlijst

    private var playersList: some View {
        VStack(spacing: 14) {
            ForEach(spelers.indices, id: \.self) { index in
                playerCard(for: index)
            }
        }
        .padding(.horizontal)
    }

    private func playerCard(for index: Int) -> some View {
        let name = spelers[index]
        let straf = strafpunten(voor: index)
        let isPerfect = isFiftyFifty(voor: index)
        let blauwTotaal = blauweTokens[index] + (gameMode == .rondes ? rondeBlauw[index] : 0)
        let geelTotaal = geleTokens[index] + (gameMode == .rondes ? rondeGeel[index] : 0)

        return VStack(spacing: 10) {
            // Spelerheader + Strafpunten badge
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if name == huidigeStarter {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                                .font(.caption2)
                        }
                    }

                    // Balans ondertitel
                    if isPerfect {
                        Text("✨ Perfect 50/50! Alle fiches heffen op")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    } else if blauwTotaal == 0 && geelTotaal == 0 {
                        Text("Nog geen fiches verzameld")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(blauwTotaal) ☀️ blauw vs \(geelTotaal) 🌙 geel")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Strafpunten badge
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(straf)")
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(straf == 0 ? .green : (straf >= limietStrafpunten && gebruikLimiet ? .red : .primary))
                        Text(straf == 1 ? "strafpunt" : "strafpunten")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if isPerfect {
                        Text("0 over")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
            }

            Divider()

            // Twee kolommen: Blauwe Fiches (☀️ Hoog) & Gele Fiches (🌙 Laag)
            HStack(spacing: 12) {
                // Blauw kolom
                tokenControlBox(
                    title: "Blauw (☀️ Hoog)",
                    color: Color.blue,
                    icon: "sun.max.fill",
                    count: gameMode == .rondes ? rondeBlauw[index] : blauweTokens[index],
                    totalCount: blauwTotaal,
                    onMinus: {
                        HapticManager.shared.light()
                        if gameMode == .rondes {
                            if rondeBlauw[index] > 0 { rondeBlauw[index] -= 1 }
                        } else {
                            if blauweTokens[index] > 0 { blauweTokens[index] -= 1 }
                        }
                        saveDraft()
                    },
                    onPlus: {
                        HapticManager.shared.light()
                        if gameMode == .rondes {
                            rondeBlauw[index] += 1
                        } else {
                            blauweTokens[index] += 1
                        }
                        saveDraft()
                    }
                )

                // Geel kolom
                tokenControlBox(
                    title: "Geel (🌙 Laag)",
                    color: Color.yellow,
                    icon: "moon.stars.fill",
                    count: gameMode == .rondes ? rondeGeel[index] : geleTokens[index],
                    totalCount: geelTotaal,
                    onMinus: {
                        HapticManager.shared.light()
                        if gameMode == .rondes {
                            if rondeGeel[index] > 0 { rondeGeel[index] -= 1 }
                        } else {
                            if geleTokens[index] > 0 { geleTokens[index] -= 1 }
                        }
                        saveDraft()
                    },
                    onPlus: {
                        HapticManager.shared.light()
                        if gameMode == .rondes {
                            rondeGeel[index] += 1
                        } else {
                            geleTokens[index] += 1
                        }
                        saveDraft()
                    }
                )
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isPerfect ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private func tokenControlBox(
        title: String,
        color: Color,
        icon: String,
        count: Int,
        totalCount: Int,
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color == .yellow ? .orange : color)
                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                if gameMode == .rondes {
                    Text("Totaal: \(totalCount)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button(action: onMinus) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(count > 0 ? (color == .yellow ? .orange : color) : .gray.opacity(0.3))
                }
                .disabled(count <= 0)

                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.black)
                    .frame(minWidth: 28)

                Button(action: onPlus) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(color == .yellow ? .orange : color)
                }
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(10)
    }

    // MARK: - Actieknoppen

    private var actionSection: some View {
        VStack(spacing: 12) {
            if gameMode == .rondes {
                // Volgende Ronde knop
                Button(action: volgendeRonde) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Voltooi Ronde \(huidigeRonde)")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal)
            }

            // Afronden knop
            Button(action: {
                HapticManager.shared.medium()
                showFinishConfirm = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "flag.checkered")
                    Text("Spel Afronden")
                }
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding(.top, 8)
    }

    // MARK: - Ronde Voltooien & Geschiedenis

    private func volgendeRonde() {
        HapticManager.shared.success()

        // 1. Voeg ronde scores toe aan totalen
        for i in spelers.indices {
            blauweTokens[i] += rondeBlauw[i]
            geleTokens[i] += rondeGeel[i]
        }

        // 2. Sla snapshot op in geschiedenis
        let entry = FiftyFiftyRondeEntry(
            ronde: huidigeRonde,
            starter: huidigeStarter,
            blauwDezeRonde: rondeBlauw,
            geelDezeRonde: rondeGeel,
            totaleBlauwNaRonde: blauweTokens,
            totaleGeelNaRonde: geleTokens,
            strafpuntenNaRonde: spelers.indices.map { strafpunten(voor: $0) }
        )
        rondeGeschiedenis.append(entry)

        // 3. Reset ronde invoervelden
        rondeBlauw = Array(repeating: 0, count: spelers.count)
        rondeGeel = Array(repeating: 0, count: spelers.count)

        // 4. Volgende ronde
        huidigeRonde += 1
        saveDraft()

        // 5. Controleer of limiet is bereikt
        if gebruikLimiet {
            for i in spelers.indices {
                if strafpunten(voor: i) >= limietStrafpunten {
                    finishGame()
                    return
                }
            }
        }
    }

    private func restoreToRound(_ entry: FiftyFiftyRondeEntry) {
        HapticManager.shared.medium()
        withAnimation {
            blauweTokens = entry.totaleBlauwNaRonde
            geleTokens = entry.totaleGeelNaRonde
            rondeBlauw = Array(repeating: 0, count: spelers.count)
            rondeGeel = Array(repeating: 0, count: spelers.count)
            rondeGeschiedenis.removeAll { $0.ronde >= entry.ronde }
            huidigeRonde = entry.ronde
            toonGeschiedenisSheet = false
            saveDraft()
        }
    }

    // MARK: - Spel Afronden

    private func finishGame() {
        HapticManager.shared.celebration()

        // Als er in 'Rondes & Slagen' nog fiches in de huidige ronde stonden, voeg ze toe
        if gameMode == .rondes {
            for i in spelers.indices {
                blauweTokens[i] += rondeBlauw[i]
                geleTokens[i] += rondeGeel[i]
            }
            rondeBlauw = Array(repeating: 0, count: spelers.count)
            rondeGeel = Array(repeating: 0, count: spelers.count)
        }

        // Bereken winnaar (minste strafpunten wint)
        let straflijst = spelers.indices.map { strafpunten(voor: $0) }
        let minScore = straflijst.min() ?? 0
        let winnaarIndex = straflijst.firstIndex(of: minScore) ?? 0
        winnaarPlayer = Player(name: spelers[winnaarIndex])

        // Opslaan in ScoreManager
        let detailedScores: [(name: String, score: Int, juiste: Int, foute: Int)] = spelers.indices.map { i in
            (name: spelers[i], score: straflijst[i], juiste: blauweTokens[i], foute: geleTokens[i])
        }

        scoreManager.saveGame(
            gameName: "Fifty Fifty",
            playerDetailedScores: detailedScores,
            winnerName: winnaarPlayer.name
        )

        activeGameManager.clearActiveGame()
        showWinnaarView = true
    }

    private var sortedSpelersResultaat: [Player] {
        let straflijst = spelers.indices.map { strafpunten(voor: $0) }
        let geordendIndices = spelers.indices.sorted { straflijst[$0] < straflijst[$1] }
        return geordendIndices.map { Player(name: spelers[$0]) }
    }

    private var sortedScoresResultaat: [Int] {
        let straflijst = spelers.indices.map { strafpunten(voor: $0) }
        return straflijst.sorted()
    }

    private func resetGame() {
        blauweTokens = Array(repeating: 0, count: spelers.count)
        geleTokens = Array(repeating: 0, count: spelers.count)
        rondeBlauw = Array(repeating: 0, count: spelers.count)
        rondeGeel = Array(repeating: 0, count: spelers.count)
        rondeGeschiedenis.removeAll()
        huidigeRonde = 1
        startSpelerIndex = 0
        activeGameManager.clearActiveGame()
    }

    // MARK: - Draft / Lopend Spel

    private func saveDraft() {
        let straflijst = spelers.indices.map { "\($0):\(strafpunten(voor: $0))" }.joined(separator: ", ")
        let summary = "\(spelers.count) spelers • Ronde \(huidigeRonde) (\(straflijst))"

        var state: [String: String] = [:]
        state["ronde"] = "\(huidigeRonde)"
        state["startSpelerIndex"] = "\(startSpelerIndex)"
        state["blauweTokens"] = blauweTokens.map { "\($0)" }.joined(separator: ",")
        state["geleTokens"] = geleTokens.map { "\($0)" }.joined(separator: ",")

        activeGameManager.saveActiveGame(
            gameName: "Fifty Fifty",
            playerNames: spelers,
            currentRound: huidigeRonde,
            summary: summary,
            state: state
        )
    }

    private func restoreDraftIfNeeded() {
        guard let draft = activeGameManager.activeSession,
              draft.gameName == "Fifty Fifty",
              draft.playerNames == spelers else { return }

        if let r = draft.stateData["ronde"], let rInt = Int(r) {
            self.huidigeRonde = rInt
        }
        if let s = draft.stateData["startSpelerIndex"], let sInt = Int(s) {
            self.startSpelerIndex = sInt
        }
        if let b = draft.stateData["blauweTokens"] {
            let parts = b.split(separator: ",").compactMap { Int($0) }
            if parts.count == spelers.count {
                self.blauweTokens = parts
            }
        }
        if let g = draft.stateData["geleTokens"] {
            let parts = g.split(separator: ",").compactMap { Int($0) }
            if parts.count == spelers.count {
                self.geleTokens = parts
            }
        }
    }

    // MARK: - Geschiedenis Sheet

    private var historySheet: some View {
        NavigationStack {
            List {
                if rondeGeschiedenis.isEmpty {
                    Text("Nog geen voltooide rondes in dit potje.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Section(
                        header: Text("Voltooide Rondes (\(rondeGeschiedenis.count))"),
                        footer: Text("💡 Tik of houd een ronde ingedrukt om terug te keren naar dat moment.")
                    ) {
                        ForEach(rondeGeschiedenis.reversed()) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                        Text("Ronde \(entry.ronde)")
                                            .font(.headline)
                                    }

                                    Spacer()

                                    Text("Start: \(entry.starter)")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.12))
                                        .clipShape(Capsule())
                                }

                                // Scores tabel
                                VStack(spacing: 4) {
                                    ForEach(spelers.indices, id: \.self) { i in
                                        HStack {
                                            Text(spelers[i])
                                                .font(.caption)
                                                .foregroundColor(.primary)

                                            Spacer()

                                            let b = entry.blauwDezeRonde[safe: i] ?? 0
                                            let g = entry.geelDezeRonde[safe: i] ?? 0
                                            let straf = entry.strafpuntenNaRonde[safe: i] ?? 0

                                            HStack(spacing: 6) {
                                                Text("+\(b)☀️ / +\(g)🌙")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)

                                                Text("\(straf) pnt")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(straf == 0 ? .green : .primary)
                                            }
                                        }
                                    }
                                }
                                .padding(8)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticManager.shared.light()
                                restoreTargetEntry = entry
                                showRestoreDialog = true
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    restoreTargetEntry = entry
                                    showRestoreDialog = true
                                } label: {
                                    Label("Herstel naar Ronde \(entry.ronde)", systemImage: "arrow.counterclockwise")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ronde Geschiedenis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klaar") {
                        toonGeschiedenisSheet = false
                    }
                }
            }
        }
    }
}

// MARK: - Safe Array Indexing Helper
private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationStack {
        FiftyFiftyGameView(spelers: ["Niels", "Lisa", "Mark"])
    }
}
