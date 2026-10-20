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
                        isLowestScoreWins: true
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
                        ForEach(rondeGeschiedenis.reversed()) { entry in
                            Section(header: Text("Ronde \(entry.ronde) • Begonnen door \(entry.starter)")) {
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
}

#Preview {
    BeverbendeScoreView(aantalRondes: 4, spelers: [Player(name: "Speler 1"), Player(name: "Speler 2")])
}
