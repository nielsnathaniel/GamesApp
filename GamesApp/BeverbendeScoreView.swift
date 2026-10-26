import SwiftUI

struct BeverbendeScoreView: View {
    var aantalRondes: Int
    var spelers: [Player]

    @State private var huidigeRonde: Int = 1
    @State private var scores: [[Int]] = []
    @State private var totaleScores: [Int] = []
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showWinnaarView: Bool = false
    @State private var winnaar: Player?
    @State private var isExpanded: [Bool] = []
    @State private var startSpelerIndex: Int = 0
    @State private var toonGeschiedenisSheet: Bool = false
    @State private var restoreTargetEntry: BeverbendeRondeEntry? = nil
    @State private var showRestoreDialog: Bool = false
    @State private var rondeGeschiedenis: [BeverbendeRondeEntry] = []

    struct BeverbendeRondeEntry: Identifiable {
        var id: Int { ronde }
        let ronde: Int
        let starter: String
        let rondeScores: [Int]
        let totalen: [Int]
    }

    var huidigeStarterIndex: Int {
        guard !spelers.isEmpty else { return 0 }
        return (startSpelerIndex + (huidigeRonde - 1)) % spelers.count
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header met ronde
            HStack {
                Text("Ronde \(huidigeRonde) van \(aantalRondes)")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    toonGeschiedenisSheet = true
                }) {
                    Label("Geschiedenis", systemImage: "clock.arrow.circlepath")
                        .font(.footnote)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)

            // Wie mag beginnen
            HStack(spacing: 8) {
                Image(systemName: "dice.fill")
                    .foregroundColor(.blue)
                Text("Begint deze ronde:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(spelers[safe: huidigeStarterIndex]?.name ?? "")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                if huidigeRonde == 1 {
                    Button("Herhussel") {
                        withAnimation {
                            startSpelerIndex = Int.random(in: 0..<max(1, spelers.count))
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)

            // Live Inhaalslag & Spanning Indicator (vanaf ronde 2)
            if huidigeRonde > 1 && totaleScores.count == spelers.count {
                let pairs = zip(spelers.map { $0.name }, totaleScores).map { (name: $0.0, score: $0.1) }
                LiveGameLeadIndicatorView(playerScores: pairs, isLowestScoreWins: true)
                    .padding(.horizontal)
            }

            ScrollView {
                VStack {
                    ForEach(spelers.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Button(action: {
                                if index < isExpanded.count {
                                    withAnimation {
                                        isExpanded[index].toggle()
                                    }
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(spelers[index].name)
                                                .font(.headline)
                                            if index == huidigeStarterIndex {
                                                Text("Begint")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.green)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(6)
                                            }
                                        }
                                    }
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
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }

            Spacer()

            Button(action: {
                if validateScores() {
                    berekenScores()
                    if huidigeRonde < aantalRondes {
                        naarVolgendeRonde()
                    } else {
                        bepaalWinnaar()
                        showWinnaarView = true
                    }
                } else {
                    showAlert = true
                }
            }) {
                Text("Volgende Ronde")
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
                        gameName: "Beverbende",
                        winnaar: winnaar,
                        sortedSpelers: spelers,
                        sortedScores: totaleScores,
                        isLowestScoreWins: true,
                        scoreProgression: beverbendeScoreProgression,
                        onReset: {
                            resetGame()
                        }
                    )
                }
            }
        }
        .padding()
        .onAppear {
            if scores.isEmpty {
                scores = Array(repeating: Array(repeating: 0, count: 4), count: spelers.count)
                totaleScores = Array(repeating: 0, count: spelers.count)
                isExpanded = Array(repeating: false, count: spelers.count)
                if !spelers.isEmpty {
                    startSpelerIndex = Int.random(in: 0..<spelers.count)
                }
            }
        }
        .sheet(isPresented: $toonGeschiedenisSheet) {
            NavigationStack {
                List {
                    if rondeGeschiedenis.isEmpty {
                        Text("Nog geen rondes voltooid.")
                            .foregroundColor(.secondary)
                    } else {
                        Section {
                            HStack(spacing: 8) {
                                Image(systemName: "hand.tap.fill")
                                    .foregroundColor(.yellow)
                                Text("Houd een ronde ingedrukt om de punten te herstellen.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }

                        ForEach(rondeGeschiedenis.reversed()) { entry in
                            Section(header:
                                HStack {
                                    Text("Ronde \(entry.ronde) • Begonnen door \(entry.starter)")
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
                                ForEach(spelers.indices, id: \.self) { sIdx in
                                    HStack {
                                        Text(spelers[sIdx].name)
                                            .font(.headline)
                                        Spacer()
                                        Text("+\(entry.rondeScores[safe: sIdx] ?? 0) pt")
                                            .fontWeight(.bold)
                                        Text("(Totaal: \(entry.totalen[safe: sIdx] ?? 0))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
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
                .navigationTitle("Puntenverloop Beverbende")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Sluit") {
                            toonGeschiedenisSheet = false
                        }
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
                        Text("Wil je de stand terugzetten naar ronde \(entry.ronde)?")
                    }
                }
            }
        }
    }

    private func herstelNaarStartVanRonde(_ entry: BeverbendeRondeEntry) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        var vorigTotaleScores = entry.totalen
        for i in vorigTotaleScores.indices {
            vorigTotaleScores[i] -= (entry.rondeScores[safe: i] ?? 0)
        }
        totaleScores = vorigTotaleScores
        scores = Array(repeating: Array(repeating: 0, count: 4), count: spelers.count)
        huidigeRonde = entry.ronde
        rondeGeschiedenis.removeAll { $0.ronde >= entry.ronde }
        toonGeschiedenisSheet = false
    }

    private func herstelNaarEindeVanRonde(_ entry: BeverbendeRondeEntry) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        totaleScores = entry.totalen
        scores = Array(repeating: Array(repeating: 0, count: 4), count: spelers.count)
        huidigeRonde = entry.ronde + 1
        rondeGeschiedenis.removeAll { $0.ronde > entry.ronde }
        toonGeschiedenisSheet = false
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
        var roundTotals: [Int] = []
        for index in spelers.indices {
            if index < scores.count {
                let rondeScore = scores[index].reduce(0, +)
                roundTotals.append(rondeScore)
                if index < totaleScores.count {
                    totaleScores[index] += rondeScore
                }
            } else {
                roundTotals.append(0)
            }
        }

        let starter = spelers[safe: huidigeStarterIndex]?.name ?? "Speler 1"
        rondeGeschiedenis.append(
            BeverbendeRondeEntry(
                ronde: huidigeRonde,
                starter: starter,
                rondeScores: roundTotals,
                totalen: totaleScores
            )
        )
    }

    private func naarVolgendeRonde() {
        huidigeRonde += 1
        scores = Array(repeating: Array(repeating: 0, count: 4), count: spelers.count)
        withAnimation {
            isExpanded = Array(repeating: false, count: spelers.count)
        }
    }

    private func bepaalWinnaar() {
        if let winnaarIndex = totaleScores.enumerated().min(by: { $0.element < $1.element })?.offset {
            winnaar = spelers[winnaarIndex]
        }
    }

    private func resetGame() {
        scores = Array(repeating: Array(repeating: 0, count: 4), count: spelers.count)
        totaleScores = Array(repeating: 0, count: spelers.count)
        isExpanded = Array(repeating: false, count: spelers.count)
        huidigeRonde = 1
        rondeGeschiedenis = []
        winnaar = nil
        showWinnaarView = false
        if !spelers.isEmpty {
            startSpelerIndex = Int.random(in: 0..<spelers.count)
        }
    }

    private var beverbendeScoreProgression: [RoundScoreDataPoint] {
        var points: [RoundScoreDataPoint] = []
        for p in spelers {
            points.append(RoundScoreDataPoint(roundNumber: 0, roundLabel: "Start", playerName: p.name, score: 0))
        }
        for entry in rondeGeschiedenis {
            for (idx, p) in spelers.enumerated() {
                let score = entry.totalen[safe: idx] ?? 0
                points.append(RoundScoreDataPoint(
                    roundNumber: entry.ronde,
                    roundLabel: "Ronde \(entry.ronde)",
                    playerName: p.name,
                    score: score
                ))
            }
        }
        return points
    }
}

#Preview {
    BeverbendeScoreView(aantalRondes: 4, spelers: [Player(name: "Speler 1"), Player(name: "Speler 2")])
}
