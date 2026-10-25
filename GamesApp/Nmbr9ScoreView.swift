import SwiftUI

struct Nmbr9RondeEntry: Identifiable {
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

struct Nmbr9ScoreView: View {
    var spelers: [Player]

    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var scores: [[Int]] = []
    @State private var totaleScores: [Int] = []
    @State private var huidigeRonde: Int = 1
    @State private var rondeGeschiedenis: [Nmbr9RondeEntry] = []
    @State private var toonGeschiedenisSheet: Bool = false
    @State private var restoreTargetEntry: Nmbr9RondeEntry? = nil
    @State private var showRestoreDialog: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showWinnaarView: Bool = false
    @State private var winnaar: Player?
    @State private var showRandomNumberView: Bool = false
    @State private var randomNumbers: [Int] = []
    @State private var currentRandomIndex: Int = 0

    var body: some View {
        NavigationStack {
            VStack {
                Text("Ronde \(huidigeRonde)")
                    .font(.title2)
                    .padding()

                ScrollView {
                    VStack {
                        ForEach(spelers.indices, id: \.self) { index in
                            VStack(alignment: .leading) {
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

                                HStack(spacing: 20) {
                                    ForEach(0..<4, id: \.self) { cardIndex in
                                        VStack {
                                            Button(action: {
                                                if index < scores.count, cardIndex < scores[index].count {
                                                    scores[index][cardIndex] = (scores[index][cardIndex] + 1) % 10
                                                }
                                            }) {
                                                Image(systemName: "triangle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.blue)
                                            }

                                            Text("\(scores[index][cardIndex])")
                                                .font(.title)
                                                .frame(width: 40, height: 40)
                                                .background(Color.gray.opacity(0.2))
                                                .cornerRadius(5)

                                            Button(action: {
                                                if index < scores.count, cardIndex < scores[index].count {
                                                    scores[index][cardIndex] = (scores[index][cardIndex] - 1 + 10) % 10
                                                }
                                            }) {
                                                Image(systemName: "triangle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.red)
                                                    .rotationEffect(.degrees(180))
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
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
                        .background(Color.orange)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .sheet(isPresented: $showRandomNumberView) {
                    RandomNumberScreen(randomNumbers: $randomNumbers, currentRandomIndex: $currentRandomIndex)
                }

                Button(action: {
                    if validateScores() {
                        berekenScores()
                        resetRandomNumbers() // Reset de random nummers
                        if huidigeRonde < 4 { // Aantal rondes kan worden aangepast
                            naarVolgendeRonde()
                        } else {
                            bepaalWinnaar()
                            showWinnaarView = true
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
                            gameName: "Nmbr9",
                            winnaar: winnaar,
                            sortedSpelers: spelers,
                            sortedScores: totaleScores,
                            isLowestScoreWins: false,
                            scoreProgression: nmbr9ScoreProgression,
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
                    Button(action: {
                        toonGeschiedenisSheet = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $toonGeschiedenisSheet) {
                historySheetView
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
            .onAppear {
                if scores.isEmpty {
                    scores = Array(repeating: Array(repeating: 0, count: 4), count: spelers.count)
                }
                if totaleScores.isEmpty {
                    totaleScores = Array(repeating: 0, count: spelers.count)
                }
                resetRandomNumbers()
            }
        }
    }

    private func validateScores() -> Bool {
        for index in spelers.indices {
            for cardIndex in 0..<4 {
                if index >= scores.count || cardIndex >= scores[index].count {
                    alertMessage = "\(spelers[index].name) mist scores voor deze ronde"
                    return false
                }
            }
        }
        return true
    }

    private func berekenScores() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        var rondeScores: [Int] = []
        for index in spelers.indices {
            var r = 0
            if index < scores.count {
                r = scores[index].reduce(0, +)
                if index < totaleScores.count {
                    totaleScores[index] += r
                }
            }
            rondeScores.append(r)
        }

        rondeGeschiedenis.append(
            Nmbr9RondeEntry(
                ronde: huidigeRonde,
                rondeScores: rondeScores,
                totaleScoresNaRonde: totaleScores
            )
        )
    }

    private func naarVolgendeRonde() {
        huidigeRonde += 1
        scores = Array(repeating: Array(repeating: 0, count: 4), count: spelers.count)
    }

    private func bepaalWinnaar() {
        if let maxScore = totaleScores.max(),
           let winnaarIndex = totaleScores.firstIndex(of: maxScore) {
            winnaar = spelers[winnaarIndex]
        } else {
            winnaar = spelers.first
        }

        if let w = winnaar {
            let detailed = spelers.indices.map { i in
                (name: spelers[i].name, score: totaleScores[safe: i] ?? 0)
            }
            scoreManager.saveGame(gameName: "Nmbr9", playerScores: detailed, winnerName: w.name)
        }
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
                    Button("Klaar") {
                        toonGeschiedenisSheet = false
                    }
                }
            }
        }
    }

    private func herstelNaarStartVanRonde(_ entry: Nmbr9RondeEntry) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        guard let idx = rondeGeschiedenis.firstIndex(where: { $0.id == entry.id }) else { return }
        let kept = Array(rondeGeschiedenis.prefix(idx))

        if let prev = kept.last {
            totaleScores = prev.totaleScoresNaRonde
        } else {
            totaleScores = Array(repeating: 0, count: spelers.count)
        }
        scores = Array(repeating: Array(repeating: 0, count: 4), count: spelers.count)
        huidigeRonde = entry.ronde
        rondeGeschiedenis = kept
        toonGeschiedenisSheet = false
    }

    private func herstelNaarEindeVanRonde(_ entry: Nmbr9RondeEntry) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        guard let idx = rondeGeschiedenis.firstIndex(where: { $0.id == entry.id }) else { return }
        let kept = Array(rondeGeschiedenis.prefix(idx + 1))

        totaleScores = entry.totaleScoresNaRonde
        scores = Array(repeating: Array(repeating: 0, count: 4), count: spelers.count)
        huidigeRonde = entry.ronde + 1
        rondeGeschiedenis = kept
        toonGeschiedenisSheet = false
    }

    private func resetGame() {
        scores = Array(repeating: Array(repeating: 0, count: 4), count: spelers.count)
        totaleScores = Array(repeating: 0, count: spelers.count)
        huidigeRonde = 1
        rondeGeschiedenis = []
        resetRandomNumbers()
        winnaar = nil
        showWinnaarView = false
    }

    private var nmbr9ScoreProgression: [RoundScoreDataPoint] {
        var points: [RoundScoreDataPoint] = []
        for p in spelers {
            points.append(RoundScoreDataPoint(roundNumber: 0, roundLabel: "Start", playerName: p.name, score: 0))
        }
        for entry in rondeGeschiedenis {
            for (idx, p) in spelers.enumerated() {
                let score = entry.totaleScoresNaRonde[safe: idx] ?? 0
                points.append(RoundScoreDataPoint(
                    roundNumber: entry.ronde,
                    roundLabel: "Niveau \(entry.ronde)",
                    playerName: p.name,
                    score: score
                ))
            }
        }
        return points
    }
}

#Preview {
    Nmbr9ScoreView(spelers: [Player(name: "Speler 1"), Player(name: "Speler 2")])
}
