import SwiftUI

struct JattenGameView: View {
    var spelers: [Player]
    var aantalRondes: Int

    @State private var huidigeRonde: Int = 1
    @State private var rondeScores: [Int] = []
    @State private var totaleScores: [Int] = []
    @State private var isExpanded: [Bool] = []
    @State private var showWinnaarView: Bool = false
    @State private var winnaar: Player?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.purple)
                        Text("Jatten")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    Text("Ronde \(huidigeRonde) van \(aantalRondes)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                // Spelers lijst
                VStack(spacing: 10) {
                    ForEach(spelers.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 0) {
                            Button(action: {
                                if index < isExpanded.count {
                                    withAnimation {
                                        isExpanded[index].toggle()
                                    }
                                }
                            }) {
                                HStack {
                                    Text(spelers[index].name)
                                        .font(.headline)
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Totaal: \(totaleScores[safe: index] ?? 0) pt")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                        if rondeScores[safe: index] ?? 0 > 0 {
                                            Text("Deze ronde: +\(rondeScores[safe: index] ?? 0)")
                                                .font(.caption)
                                                .foregroundColor(.purple)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                            }

                            if index < isExpanded.count && isExpanded[index] {
                                VStack(spacing: 10) {
                                    HStack {
                                        Text("Score deze ronde:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(rondeScores[safe: index] ?? 0)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.purple)
                                    }

                                    // Snelle knoppen
                                    HStack(spacing: 10) {
                                        Button("-1") {
                                            if index < rondeScores.count && rondeScores[index] > 0 {
                                                rondeScores[index] -= 1
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.red)

                                        Spacer()

                                        Button("+1") {
                                            if index < rondeScores.count {
                                                rondeScores[index] += 1
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.purple.opacity(0.8))

                                        Button("+5") {
                                            if index < rondeScores.count {
                                                rondeScores[index] += 5
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.purple)

                                        Button("+10") {
                                            if index < rondeScores.count {
                                                rondeScores[index] += 10
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.purple)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(10)
                                .padding(.horizontal, 4)
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 20)

                // Volgende ronde / afronden knop
                Button(action: {
                    volgendeRonde()
                }) {
                    Text(huidigeRonde < aantalRondes ? "Volgende Ronde" : "Spel Afronden")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onAppear {
            if rondeScores.isEmpty {
                rondeScores = Array(repeating: 0, count: spelers.count)
                totaleScores = Array(repeating: 0, count: spelers.count)
                isExpanded = Array(repeating: false, count: spelers.count)
            }
        }
        .navigationDestination(isPresented: $showWinnaarView) {
            if let winnaar = winnaar {
                WinnaarView(
                    gameName: "Jatten",
                    winnaar: winnaar,
                    sortedSpelers: spelers,
                    sortedScores: totaleScores,
                    isLowestScoreWins: false
                )
            }
        }
    }

    private func volgendeRonde() {
        // Totaal bijwerken
        for i in spelers.indices {
            if i < rondeScores.count && i < totaleScores.count {
                totaleScores[i] += rondeScores[i]
            }
        }

        if huidigeRonde < aantalRondes {
            huidigeRonde += 1
            rondeScores = Array(repeating: 0, count: spelers.count)
            withAnimation {
                isExpanded = Array(repeating: false, count: spelers.count)
            }
        } else {
            bepaalWinnaar()
            showWinnaarView = true
        }
    }

    private func bepaalWinnaar() {
        if let maxScore = totaleScores.max(),
           let winnaarIndex = totaleScores.firstIndex(of: maxScore) {
            winnaar = spelers[winnaarIndex]
        } else {
            winnaar = spelers.first
        }
    }
}

#Preview {
    JattenGameView(spelers: [Player(name: "Speler 1"), Player(name: "Speler 2")], aantalRondes: 5)
}
