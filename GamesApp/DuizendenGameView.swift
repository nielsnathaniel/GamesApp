import SwiftUI

struct DuizendenRondeEntry: Identifiable {
    let id: UUID
    let ronde: Int
    let rondeScores: [Int]
    let totalenNaRonde: [Int]

    init(id: UUID = UUID(), ronde: Int, rondeScores: [Int], totalenNaRonde: [Int]) {
        self.id = id
        self.ronde = ronde
        self.rondeScores = rondeScores
        self.totalenNaRonde = totalenNaRonde
    }
}

struct DuizendenGameView: View {
    var spelers: [Player]
    var aantalSpellenKaarten: Int
    var eindscore: Int

    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var huidigeRonde: Int = 1
    @State private var scores: [Int] = []
    @State private var rondeGeschiedenis: [DuizendenRondeEntry] = []
    @State private var toonGeschiedenisSheet: Bool = false
    @State private var restoreTargetEntry: DuizendenRondeEntry? = nil
    @State private var showRestoreDialog: Bool = false

    @State private var showWinnaarView: Bool = false
    @State private var winnaar: Player?
    @State private var expandedPlayerIndex: Int? = nil
    @State private var selectedSection: [Int: String] = [:]
    @State private var tafelScores: [[Int]] = []
    @State private var handScores: [[Int]] = []

    let kaartSymbolen = ["3", "K", "A", "JO", "Q"]

    private func kaartWaarde(voor symbool: String) -> Int {
        switch symbool {
        case "3": return 5
        case "K", "Q": return 10
        case "A": return 20
        case "JO": return 25
        default: return 0
        }
    }

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duizenden")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Ronde \(huidigeRonde) • Doel: \(eindscore) pt")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    toonGeschiedenisSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Geschiedenis")
                    }
                    .font(.footnote)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            List(spelers.indices, id: \.self) { index in
                VStack(alignment: .leading) {
                    Button(action: {
                        withAnimation {
                            expandedPlayerIndex = (expandedPlayerIndex == index) ? nil : index
                        }
                    }) {
                        HStack {
                            Text(spelers[index].name)
                            Spacer()
                            Text("\(scores[safe: index] ?? 0) punten")
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    if expandedPlayerIndex == index {
                        sectionSelector(for: index)
                        if let section = selectedSection[index] {
                            scoreInputView(for: index, section: section)
                        }
                    }
                }
                .padding(.vertical, 5)
            }

            Spacer()

            Button(action: {
                berekenScores()
                checkWinnaar()
            }) {
                Text("Ronde \(huidigeRonde) Voltooien")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .navigationDestination(isPresented: $showWinnaarView) {
                if let winnaar = winnaar {
                    WinnaarView(
                        gameName: "Duizenden",
                        winnaar: winnaar,
                        sortedSpelers: spelers,
                        sortedScores: scores,
                        isLowestScoreWins: false,
                        onReset: {
                            resetGame()
                        }
                    )
                }
            }
        }
        .padding(.bottom)
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
                scores = Array(repeating: 0, count: spelers.count)
            }
            if tafelScores.isEmpty {
                tafelScores = Array(repeating: Array(repeating: 0, count: kaartSymbolen.count), count: spelers.count)
            }
            if handScores.isEmpty {
                handScores = Array(repeating: Array(repeating: 0, count: kaartSymbolen.count), count: spelers.count)
            }
        }
    }

    private func sectionSelector(for index: Int) -> some View {
        HStack {
            Button(action: {
                selectedSection[index] = "Op Tafel"
            }) {
                Text("Op Tafel")
                    .font(.headline)
                    .foregroundColor(selectedSection[index] == "Op Tafel" ? .white : .blue)
                    .padding()
                    .background(selectedSection[index] == "Op Tafel" ? Color.blue : Color.clear)
                    .cornerRadius(10)
            }
            Button(action: {
                selectedSection[index] = "In de Hand"
            }) {
                Text("In de Hand")
                    .font(.headline)
                    .foregroundColor(selectedSection[index] == "In de Hand" ? .white : .blue)
                    .padding()
                    .background(selectedSection[index] == "In de Hand" ? Color.blue : Color.clear)
                    .cornerRadius(10)
            }
        }
        .padding(.vertical)
    }

    private func scoreInputView(for index: Int, section: String) -> some View {
        VStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                ForEach(kaartSymbolen.indices, id: \.self) { i in
                    scoreInputField(for: index, kaartIndex: i, isTafel: section == "Op Tafel")
                }
            }
        }
        .padding()
    }

    private func scoreInputField(for index: Int, kaartIndex: Int, isTafel: Bool) -> some View {
        VStack {
            Text(kaartSymbolen[kaartIndex])
                .font(.caption)
            HStack {
                Button(action: {
                    if isTafel {
                        tafelScores[index][kaartIndex] = max(0, tafelScores[index][kaartIndex] - 1)
                    } else {
                        handScores[index][kaartIndex] = max(0, handScores[index][kaartIndex] - 1)
                    }
                }) {
                    Image(systemName: "minus.circle")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                TextField("0", value: isTafel ? $tafelScores[index][kaartIndex] : $handScores[index][kaartIndex], formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .frame(width: 30)
                    .multilineTextAlignment(.center)
                Button(action: {
                    if isTafel {
                        tafelScores[index][kaartIndex] += 1
                    } else {
                        handScores[index][kaartIndex] += 1
                    }
                }) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
        }
    }

    private func berekenScores() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        var rondeScores: [Int] = []
        for index in spelers.indices {
            var tafelScore = 0
            var handScore = 0
            for i in kaartSymbolen.indices {
                let waarde = kaartWaarde(voor: kaartSymbolen[i])
                tafelScore += (tafelScores[safe: index]?[safe: i] ?? 0) * waarde
                handScore += (handScores[safe: index]?[safe: i] ?? 0) * waarde
            }
            let diff = tafelScore - handScore
            rondeScores.append(diff)
            scores[index] += diff
        }

        rondeGeschiedenis.append(
            DuizendenRondeEntry(
                ronde: huidigeRonde,
                rondeScores: rondeScores,
                totalenNaRonde: scores
            )
        )
        huidigeRonde += 1

        // Reset ingevoerde tafel- en handkaarten voor de volgende ronde
        tafelScores = Array(repeating: Array(repeating: 0, count: kaartSymbolen.count), count: spelers.count)
        handScores = Array(repeating: Array(repeating: 0, count: kaartSymbolen.count), count: spelers.count)
        expandedPlayerIndex = nil
    }

    private func checkWinnaar() {
        if let maxScore = scores.max(), maxScore >= eindscore {
            let winnaars = spelers.indices.filter { scores[$0] == maxScore }
            if winnaars.count == 1 {
                winnaar = spelers[winnaars[0]]
            } else {
                winnaar = spelers[winnaars.max(by: { scores[$0] < scores[$1] }) ?? 0]
            }

            if let w = winnaar {
                let detailed = spelers.indices.map { i in
                    (name: spelers[i].name, score: scores[i])
                }
                scoreManager.saveGame(gameName: "Duizenden", playerScores: detailed, winnerName: w.name)
            }
            showWinnaarView = true
        }
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
                            Text("Houd een ronde ingedrukt om de punten daarnaartoe te herstellen.")
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
                                    Text("\(diff >= 0 ? "+" : "")\(diff) pt")
                                        .font(.caption)
                                        .foregroundColor(diff >= 0 ? .green : .red)
                                    Text("(\(entry.totalenNaRonde[safe: idx] ?? 0) pt)")
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

    private func herstelNaarStartVanRonde(_ entry: DuizendenRondeEntry) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        var vorigTotaleScores = entry.totalenNaRonde
        for i in vorigTotaleScores.indices {
            vorigTotaleScores[i] -= (entry.rondeScores[safe: i] ?? 0)
        }
        scores = vorigTotaleScores
        huidigeRonde = entry.ronde
        rondeGeschiedenis.removeAll { $0.ronde >= entry.ronde }
        toonGeschiedenisSheet = false
    }

    private func herstelNaarEindeVanRonde(_ entry: DuizendenRondeEntry) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        scores = entry.totalenNaRonde
        huidigeRonde = entry.ronde + 1
        rondeGeschiedenis.removeAll { $0.ronde > entry.ronde }
        toonGeschiedenisSheet = false
    }

    private func resetGame() {
        scores = Array(repeating: 0, count: spelers.count)
        tafelScores = Array(repeating: Array(repeating: 0, count: kaartSymbolen.count), count: spelers.count)
        handScores = Array(repeating: Array(repeating: 0, count: kaartSymbolen.count), count: spelers.count)
        huidigeRonde = 1
        rondeGeschiedenis = []
        expandedPlayerIndex = nil
        winnaar = nil
        showWinnaarView = false
    }
}

#Preview {
    DuizendenGameView(spelers: [Player(name: "Speler 1"), Player(name: "Speler 2")], aantalSpellenKaarten: 2, eindscore: 1000)
}
