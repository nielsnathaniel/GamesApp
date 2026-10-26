import SwiftUI

struct CurrentGameRondeEntry: Identifiable {
    let id: UUID
    let ronde: Int
    let rondeScores: [Int]
    let totaleScoresNaRonde: [Int]

    init(id: UUID = UUID(), ronde: Int, rondeScores: [Int], totaleScoresNaRonde: [Int]) {
        self.id = id
        self.ronde = ronde
        self.rondeScores = rondeScores
        self.totaleScoresNaRonde = totaleScoresNaRonde
    }
}

struct CurrentGameView: View {
    var gameName: String
    var imageName: String
    var spelers: [Player]
    var rekenversie: Rekenversie
    var speelwijze: Speelwijze
    var aantalRondes: Int
    var totaleScore: Int

    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var huidigeRonde: Int = 1
    @State private var scores: [Int] = []
    @State private var laagScores: [[Int]] = []
    @State private var totaleScores: [Int] = []
    @State private var isExpanded: [Bool] = []
    @State private var rondeGeschiedenis: [CurrentGameRondeEntry] = []
    @State private var toonGeschiedenisSheet: Bool = false
    @State private var restoreTargetEntry: CurrentGameRondeEntry? = nil
    @State private var showRestoreDialog: Bool = false
    @State private var showPuntenWijzigenSheet: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showWinnaarView: Bool = false
    @State private var winnaar: Player?
    @State private var showRandomNumberView: Bool = false
    @State private var randomNumbers: [Int] = []
    @State private var currentRandomIndex: Int = 0

    private func laagTitel(voor laag: Int) -> String {
        switch laag {
        case 0: return "Begane grond (x0)"
        case 1: return "Laag 1 (x1)"
        case 2: return "Laag 2 (x2)"
        case 3: return "Laag 3 (x3)"
        case 4: return "Laag 4 (x4)"
        default: return "Laag \(laag)"
        }
    }

    var body: some View {
        VStack {
            HStack {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.trailing, 10)
                
                Text(gameName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)

            if speelwijze == .aantalRondes {
                Text("Ronde \(huidigeRonde) van \(aantalRondes)")
                    .font(.title2)
                    .padding()
            } else {
                Text("Ronde \(huidigeRonde)")
                    .font(.title2)
                    .padding()
            }

            Spacer()

            ScrollView {
                VStack {
                    ForEach(spelers.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Button(action: {
                                if index < isExpanded.count {
                                    isExpanded[index].toggle()
                                }
                            }) {
                                HStack {
                                    Text(spelers[index].name)
                                        .font(.headline)
                                    Spacer()
                                    if index < totaleScores.count {
                                        Text("Totale score: \(totaleScores[index])")
                                            .font(.subheadline)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                            }
                            .padding(.vertical, 5)

                            if index < isExpanded.count && isExpanded[index] {
                                TabView {
                                    ForEach(0..<5, id: \.self) { laag in
                                        VStack {
                                            Text(laagTitel(voor: laag))
                                                .font(.headline)
                                            HStack {
                                                Button(action: {
                                                    if index < laagScores.count, laag < laagScores[index].count, laagScores[index][laag] > 0 {
                                                        laagScores[index][laag] -= 1
                                                    }
                                                }) {
                                                    Image(systemName: "minus.circle")
                                                        .font(.title)
                                                        .foregroundColor((index < laagScores.count && laag < laagScores[index].count && laagScores[index][laag] > 0) ? .red : .gray)
                                                }
                                                .disabled(!(index < laagScores.count && laag < laagScores[index].count && laagScores[index][laag] > 0))

                                                if index < laagScores.count && laag < laagScores[index].count {
                                                    Text("\(laagScores[index][laag])")
                                                        .font(.title2)
                                                        .frame(width: 40)
                                                }

                                                Button(action: {
                                                    if index < laagScores.count, laag < laagScores[index].count {
                                                        laagScores[index][laag] += 1
                                                    }
                                                }) {
                                                    Image(systemName: "plus.circle")
                                                        .font(.title)
                                                        .foregroundColor(.green)
                                                }
                                            }
                                        }
                                        .padding()
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                                .frame(height: 150)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }

            Spacer()

            Button(action: {
                showRandomNumberView = true
            }) {
                Text("Kaartjes")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .sheet(isPresented: $showRandomNumberView) {
                RandomNumberScreen(randomNumbers: $randomNumbers, currentRandomIndex: $currentRandomIndex)
            }

            Button(action: {
                if validateScores() {
                    berekenScores()
                    if speelwijze == .totScore {
                        if let winnaar = checkWinnaar() {
                            self.winnaar = winnaar
                            showWinnaarView = true
                        } else {
                            naarVolgendeRonde()
                        }
                    } else if huidigeRonde == aantalRondes {
                        self.winnaar = bepaalWinnaar()
                        showWinnaarView = true
                    } else {
                        naarVolgendeRonde()
                    }
                } else {
                    showAlert = true
                }
            }) {
                Text("Bereken Scores")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Invoerfout"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .navigationDestination(isPresented: $showWinnaarView) {
                if let winnaar = winnaar {
                    WinnaarView(
                        gameName: gameName,
                        winnaar: winnaar,
                        sortedSpelers: spelers,
                        sortedScores: totaleScores,
                        isLowestScoreWins: false,
                        onReset: {
                            resetGame()
                        }
                    )
                }
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    Button(action: {
                        showPuntenWijzigenSheet = true
                    }) {
                        Image(systemName: "pencil.circle")
                    }
                    Button(action: {
                        toonGeschiedenisSheet = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
        }
        .sheet(isPresented: $toonGeschiedenisSheet) {
            historySheetView
        }
        .sheet(isPresented: $showPuntenWijzigenSheet) {
            PuntenWijzigenSheet(
                players: spelers,
                huidigeScores: totaleScores,
                titel: "\(gameName) Stand Wijzigen",
                isLowestScoreWins: false
            ) { nieuweScores in
                var rondeDiffs: [Int] = []
                for i in spelers.indices {
                    let oldScore = totaleScores[safe: i] ?? 0
                    let newScore = nieuweScores[safe: i] ?? oldScore
                    rondeDiffs.append(newScore - oldScore)
                }
                totaleScores = nieuweScores
                let entry = CurrentGameRondeEntry(
                    id: UUID(),
                    ronde: huidigeRonde,
                    rondeScores: rondeDiffs,
                    totaleScoresNaRonde: nieuweScores
                )
                rondeGeschiedenis.append(entry)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        .confirmationDialog(
            "Herstel Ronde \(restoreTargetEntry?.ronde ?? 1)?",
            isPresented: $showRestoreDialog,
            titleVisibility: .visible
        ) {
            if let entry = restoreTargetEntry {
                Button("✏️ Punten direct wijzigen...") {
                    openPuntenWijzigenVanuitGeschiedenis()
                }
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
                Text("Wil je de scores en rondeteller terugzetten naar ronde \(entry.ronde)? Of pas de stand direct aan.")
            }
        }
        .onAppear {
            if scores.isEmpty {
                scores = Array(repeating: 0, count: spelers.count)
            }
            if laagScores.isEmpty {
                laagScores = Array(repeating: Array(repeating: 0, count: 5), count: spelers.count)
            }
            if totaleScores.isEmpty {
                totaleScores = Array(repeating: 0, count: spelers.count)
            }
            if isExpanded.isEmpty {
                isExpanded = Array(repeating: false, count: spelers.count)
            }
            resetRandomNumbers()
        }
    }

    private func validateScores() -> Bool {
        // Niet-gebouwde lagen mogen 0 zijn en blokkeren het afronden van het spel niet
        return true
    }

    private func berekenScores() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        for index in spelers.indices {
            var rondeScore = 0
            for laag in 0..<5 {
                let factor = laag // Begane grond = x0, Laag 1 = x1, Laag 2 = x2, Laag 3 = x3, Laag 4 = x4
                if index < laagScores.count && laag < laagScores[index].count {
                    rondeScore += laagScores[index][laag] * factor
                }
            }
            if index < scores.count {
                scores[index] = rondeScore
                totaleScores[index] += rondeScore
            }
        }

        rondeGeschiedenis.append(
            CurrentGameRondeEntry(
                ronde: huidigeRonde,
                rondeScores: scores,
                totaleScoresNaRonde: totaleScores
            )
        )
    }

    private func naarVolgendeRonde() {
        huidigeRonde += 1
        laagScores = Array(repeating: Array(repeating: 0, count: 5), count: spelers.count)
    }

    private func checkWinnaar() -> Player? {
        let winnaars = spelers.enumerated().filter { $0.offset < totaleScores.count && totaleScores[$0.offset] >= totaleScore }
        if winnaars.count > 0 {
            let winner = winnaars.max(by: { $0.offset < totaleScores.count && totaleScores[$0.offset] < totaleScores[$1.offset] })?.element
            if let w = winner {
                let detailed = spelers.indices.map { i in
                    (name: spelers[i].name, score: totaleScores[safe: i] ?? 0)
                }
                scoreManager.saveGame(gameName: gameName, playerScores: detailed, winnerName: w.name)
            }
            return winner
        }
        return nil
    }

    private func bepaalWinnaar() -> Player {
        let winner = spelers.enumerated().max(by: { $0.offset < totaleScores.count && totaleScores[$0.offset] < totaleScores[$1.offset] })!.element
        let detailed = spelers.indices.map { i in
            (name: spelers[i].name, score: totaleScores[safe: i] ?? 0)
        }
        scoreManager.saveGame(gameName: gameName, playerScores: detailed, winnerName: winner.name)
        return winner
    }

    private func resetRandomNumbers() {
        randomNumbers = (0...9).flatMap { Array(repeating: $0, count: 2) }.shuffled()
        currentRandomIndex = 0
    }

    // MARK: - Geschiedenis & Herstel Weergave

    private var historySheetView: some View {
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
                            Text("Houd een ronde ingedrukt om de stand daarnaartoe te herstellen.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    ForEach(rondeGeschiedenis) { entry in
                        Section(header:
                            HStack {
                                Text("Ronde \(entry.ronde)")
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
                                    Text(spelers[idx].name)
                                        .font(.subheadline)
                                    Spacer()
                                    let diff = entry.rondeScores[safe: idx] ?? 0
                                    Text("+\(diff) pt")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text("(\(entry.totaleScoresNaRonde[safe: idx] ?? 0) pt)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
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
                                Button(action: {
                                    openPuntenWijzigenVanuitGeschiedenis()
                                }) {
                                    Label("Punten direct wijzigen", systemImage: "pencil.line")
                                }
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        openPuntenWijzigenVanuitGeschiedenis()
                    }) {
                        Label("Punten wijzigen", systemImage: "pencil.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klaar") {
                        toonGeschiedenisSheet = false
                    }
                }
            }
        }
    }

    private func openPuntenWijzigenVanuitGeschiedenis() {
        toonGeschiedenisSheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showPuntenWijzigenSheet = true
        }
    }

    private func herstelNaarStartVanRonde(_ entry: CurrentGameRondeEntry) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        guard let idx = rondeGeschiedenis.firstIndex(where: { $0.id == entry.id }) else { return }
        let kept = Array(rondeGeschiedenis.prefix(idx))

        if let prev = kept.last {
            totaleScores = prev.totaleScoresNaRonde
        } else {
            totaleScores = Array(repeating: 0, count: spelers.count)
        }
        scores = Array(repeating: 0, count: spelers.count)
        laagScores = Array(repeating: Array(repeating: 0, count: 5), count: spelers.count)
        huidigeRonde = entry.ronde
        rondeGeschiedenis = kept
        toonGeschiedenisSheet = false
    }

    private func herstelNaarEindeVanRonde(_ entry: CurrentGameRondeEntry) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        guard let idx = rondeGeschiedenis.firstIndex(where: { $0.id == entry.id }) else { return }
        let kept = Array(rondeGeschiedenis.prefix(idx + 1))

        totaleScores = entry.totaleScoresNaRonde
        scores = Array(repeating: 0, count: spelers.count)
        laagScores = Array(repeating: Array(repeating: 0, count: 5), count: spelers.count)
        huidigeRonde = entry.ronde + 1
        rondeGeschiedenis = kept
        toonGeschiedenisSheet = false
    }

    private func resetGame() {
        scores = Array(repeating: 0, count: spelers.count)
        laagScores = Array(repeating: Array(repeating: 0, count: 5), count: spelers.count)
        totaleScores = Array(repeating: 0, count: spelers.count)
        isExpanded = Array(repeating: false, count: spelers.count)
        huidigeRonde = 1
        rondeGeschiedenis = []
        resetRandomNumbers()
        winnaar = nil
        showWinnaarView = false
    }
}

#Preview {
    CurrentGameView(gameName: "Nmbr9", imageName: "Nmbr9", spelers: [Player(name: "Speler 1"), Player(name: "Speler 2")], rekenversie: .totaalwaardePerLaag, speelwijze: .totScore, aantalRondes: 4, totaleScore: 150)
}
