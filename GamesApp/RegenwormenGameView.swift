import SwiftUI

struct RegenwormenTurnEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    let speler: String
    let actie: String
    let scoresNaBeurt: [Int]

    init(id: UUID = UUID(), timestamp: Date = Date(), speler: String, actie: String, scoresNaBeurt: [Int]) {
        self.id = id
        self.timestamp = timestamp
        self.speler = speler
        self.actie = actie
        self.scoresNaBeurt = scoresNaBeurt
    }
}

struct RegenwormenGameView: View {
    var spelers: [Player]

    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var scores: [Int] = []
    @State private var selectedPlayerIndex: Int = 0
    @State private var geschiedenis: [RegenwormenTurnEntry] = []
    @State private var toonGeschiedenisSheet: Bool = false
    @State private var restoreTargetEntry: RegenwormenTurnEntry? = nil
    @State private var showRestoreDialog: Bool = false
    @State private var showWinnaarView: Bool = false
    @State private var winnaar: Player?

    // Stenen 21..36 met hun wormwaardes
    let stenen: [(nummer: Int, wormen: Int)] = (21...36).map { nummer in
        let wormen: Int
        switch nummer {
        case 21...24: wormen = 1
        case 25...28: wormen = 2
        case 29...32: wormen = 3
        default: wormen = 4
        }
        return (nummer, wormen)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack(spacing: 10) {
                    if UIImage(named: "Regenwormen") != nil {
                        Image("Regenwormen")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 38, height: 38)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            .shadow(color: .orange.opacity(0.3), radius: 3, x: 0, y: 1)
                    } else {
                        Image(systemName: "circle.hexagongrid.fill")
                            .foregroundColor(.orange)
                    }
                    Text("Regenwormen")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 8)

                // Spelers lijst / tegels
                VStack(spacing: 8) {
                    Text("Kies speler om wormen toe te voegen:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: min(spelers.count, 3)), spacing: 10) {
                        ForEach(spelers.indices, id: \.self) { index in
                            Button(action: {
                                selectedPlayerIndex = index
                            }) {
                                VStack(spacing: 4) {
                                    Text(spelers[index].name)
                                        .font(.headline)
                                        .lineLimit(1)
                                        .foregroundColor(selectedPlayerIndex == index ? .white : .primary)

                                    HStack(spacing: 4) {
                                        Text("\(scores[safe: index] ?? 0)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Text("wormen")
                                            .font(.caption)
                                    }
                                    .foregroundColor(selectedPlayerIndex == index ? .white : .orange)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity)
                                .background(selectedPlayerIndex == index ? Color.orange : Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedPlayerIndex == index ? Color.orange : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Divider()
                    .padding(.horizontal)

                // Snelle wormen toevoegen / aftrekken voor geselecteerde speler
                VStack(spacing: 8) {
                    Text("Wormen voor \(spelers[safe: selectedPlayerIndex]?.name ?? "")")
                        .font(.headline)

                    HStack(spacing: 12) {
                        ForEach([1, 2, 3, 4], id: \.self) { aantal in
                            Button(action: {
                                if selectedPlayerIndex < scores.count {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    scores[selectedPlayerIndex] += aantal
                                    recordTurn(speler: spelers[selectedPlayerIndex].name, actie: "+\(aantal) \(aantal == 1 ? "worm" : "wormen")")
                                }
                            }) {
                                VStack(spacing: 2) {
                                    Text("+\(aantal)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text(aantal == 1 ? "worm" : "wormen")
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.orange, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Correctie knop (-1 worm)
                    HStack {
                        Spacer()
                        Button(action: {
                            if selectedPlayerIndex < scores.count && scores[selectedPlayerIndex] > 0 {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                scores[selectedPlayerIndex] -= 1
                                recordTurn(speler: spelers[selectedPlayerIndex].name, actie: "-1 worm")
                            }
                        }) {
                            Label("1 worm aftrekken", systemImage: "minus.circle")
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                        .disabled((scores[safe: selectedPlayerIndex] ?? 0) <= 0)
                        Spacer()
                    }
                    .padding(.top, 4)
                }

                Divider()
                    .padding(.horizontal)

                // Stenen overzicht (21 t/m 36)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stenen op tafel (21 t/m 36)")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 8) {
                        ForEach(stenen, id: \.nummer) { steen in
                            Button(action: {
                                if selectedPlayerIndex < scores.count {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    scores[selectedPlayerIndex] += steen.wormen
                                    recordTurn(speler: spelers[selectedPlayerIndex].name, actie: "Steen \(steen.nummer) (+\(steen.wormen) pt)")
                                }
                            }) {
                                VStack(spacing: 2) {
                                    Text("\(steen.nummer)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Text("\(steen.wormen) pt")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 20)

                // Afronden knop
                Button(action: {
                    bepaalWinnaar()
                    showWinnaarView = true
                }) {
                    Text("Spel Afronden & Winnaar Bekijken")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Regenwormen")
        .navigationBarTitleDisplayMode(.inline)
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
            "Herstel naar beurt?",
            isPresented: $showRestoreDialog,
            titleVisibility: .visible
        ) {
            if let entry = restoreTargetEntry {
                Button("Herstel vóór: \(entry.actie) van \(entry.speler)", role: .destructive) {
                    herstelNaarBeurt(entry, includeThisTurn: false)
                }
                Button("Herstel t/m: \(entry.actie) van \(entry.speler)") {
                    herstelNaarBeurt(entry, includeThisTurn: true)
                }
                Button("Annuleren", role: .cancel) {}
            }
        } message: {
            if let entry = restoreTargetEntry {
                Text("Wil je de stand van het spel terugzetten naar de beurt van \(entry.speler)?")
            }
        }
        .onAppear {
            if scores.isEmpty {
                scores = Array(repeating: 0, count: spelers.count)
            }
        }
        .navigationDestination(isPresented: $showWinnaarView) {
            if let winnaar = winnaar {
                WinnaarView(
                    gameName: "Regenwormen",
                    winnaar: winnaar,
                    sortedSpelers: spelers,
                    sortedScores: scores,
                    isLowestScoreWins: false
                )
            }
        }
    }

    private func recordTurn(speler: String, actie: String) {
        let entry = RegenwormenTurnEntry(speler: speler, actie: actie, scoresNaBeurt: scores)
        geschiedenis.append(entry)
    }

    private func bepaalWinnaar() {
        if let maxScore = scores.max(),
           let winnaarIndex = scores.firstIndex(of: maxScore) {
            winnaar = spelers[winnaarIndex]
        } else {
            winnaar = spelers.first
        }

        if let w = winnaar {
            let detailed = spelers.indices.map { i in
                (name: spelers[i].name, score: scores[safe: i] ?? 0)
            }
            scoreManager.saveGame(gameName: "Regenwormen", playerScores: detailed, winnerName: w.name)
        }
    }

    // MARK: - Geschiedenis & Herstel Weergave

    private var historySheetView: some View {
        NavigationStack {
            List {
                if geschiedenis.isEmpty {
                    Text("Er zijn nog geen beurten of acties geregistreerd.")
                        .foregroundColor(.secondary)
                } else {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.yellow)
                            Text("Houd een beurt ingedrukt om de puntenstand daarnaartoe te herstellen.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    ForEach(geschiedenis) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(entry.speler): \(entry.actie)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Spacer()
                                Button(action: {
                                    restoreTargetEntry = entry
                                    showRestoreDialog = true
                                }) {
                                    Image(systemName: "arrow.uturn.backward.circle")
                                        .font(.title3)
                                        .foregroundColor(.orange)
                                }
                                .buttonStyle(.plain)
                            }

                            HStack(spacing: 8) {
                                ForEach(spelers.indices, id: \.self) { idx in
                                    Text("\(spelers[idx].name): \(entry.scoresNaBeurt[safe: idx] ?? 0)🐛")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onLongPressGesture {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            restoreTargetEntry = entry
                            showRestoreDialog = true
                        }
                        .contextMenu {
                            Button(role: .destructive, action: {
                                herstelNaarBeurt(entry, includeThisTurn: false)
                            }) {
                                Label("Herstel vóór deze actie", systemImage: "arrow.uturn.backward")
                            }
                            Button(action: {
                                herstelNaarBeurt(entry, includeThisTurn: true)
                            }) {
                                Label("Herstel t/m deze actie", systemImage: "arrow.uturn.forward")
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

    private func herstelNaarBeurt(_ entry: RegenwormenTurnEntry, includeThisTurn: Bool) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        guard let idx = geschiedenis.firstIndex(where: { $0.id == entry.id }) else { return }
        let cutoff = includeThisTurn ? idx + 1 : idx
        let kept = Array(geschiedenis.prefix(cutoff))

        if let target = includeThisTurn ? entry : kept.last {
            scores = target.scoresNaBeurt
            if let pIdx = spelers.firstIndex(where: { $0.name == target.speler }) {
                selectedPlayerIndex = pIdx
            }
        } else {
            scores = Array(repeating: 0, count: spelers.count)
        }
        geschiedenis = kept
        toonGeschiedenisSheet = false
    }
}

#Preview {
    RegenwormenGameView(spelers: [Player(name: "Speler 1"), Player(name: "Speler 2")])
}
