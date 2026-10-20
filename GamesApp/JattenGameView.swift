import SwiftUI

struct JattenGameView: View {
    var spelers: [Player]

    @State private var huidigeRonde: Int = 1
    @State private var startSpelerIndex: Int = 0
    @State private var rondeScores: [Int] = []
    @State private var totaleScores: [Int] = []
    @State private var isExpanded: [Bool] = []
    @State private var showWinnaarView: Bool = false
    @State private var winnaar: Player?
    @State private var showZesDezelfdeAlert: Bool = false
    @State private var geselecteerdeWinnaarIndex: Int?

    var huidigeStarterIndex: Int {
        guard !spelers.isEmpty else { return 0 }
        return (startSpelerIndex + (huidigeRonde - 1)) % spelers.count
    }

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
                    Text("Ronde \(huidigeRonde) • Eerste met 6 dezelfde wint!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)

                // Wie mag beginnen (Startspeler kaart)
                HStack(spacing: 10) {
                    Image(systemName: "dice.fill")
                        .font(.title2)
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Begint deze ronde:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(spelers[safe: huidigeStarterIndex]?.name ?? "Speler 1")
                            .font(.headline)
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
                            Label("Willekeurig", systemImage: "arrow.triangle.2.circlepath")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.12))
                                .foregroundColor(.purple)
                                .cornerRadius(8)
                        }
                    } else {
                        Text("Om de beurt")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // Spelers lijst
                VStack(spacing: 12) {
                    ForEach(spelers.indices, id: \.self) { index in
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(spelers[index].name)
                                            .font(.headline)
                                        if index == huidigeStarterIndex {
                                            Text("Begint")
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.15))
                                                .foregroundColor(.green)
                                                .cornerRadius(6)
                                        }
                                    }
                                    Text("Totaal: \(totaleScores[safe: index] ?? 0) pt")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                // Knop 6 dezelfde! Direct winnen
                                Button(action: {
                                    geselecteerdeWinnaarIndex = index
                                    showZesDezelfdeAlert = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "crown.fill")
                                        Text("6 dezelfde!")
                                    }
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.orange, Color.purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(8)
                                    .shadow(color: Color.purple.opacity(0.3), radius: 3, x: 0, y: 2)
                                }

                                // Uitklappen knop voor score-invoer
                                Button(action: {
                                    if index < isExpanded.count {
                                        withAnimation {
                                            isExpanded[index].toggle()
                                        }
                                    }
                                }) {
                                    Image(systemName: (index < isExpanded.count && isExpanded[index]) ? "chevron.up.circle.fill" : "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.purple)
                                }
                                .padding(.leading, 6)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)

                            // Uitgeklapt invoergedeelte
                            if index < isExpanded.count && isExpanded[index] {
                                VStack(spacing: 10) {
                                    HStack {
                                        Text("Punten / Kaarten deze ronde:")
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

                // Knoppen onderin: Volgende ronde & Afronden
                VStack(spacing: 10) {
                    Button(action: {
                        volgendeRonde()
                    }) {
                        Label("Volgende Ronde", systemImage: "arrow.right.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        sluitSpelHandmatigAf()
                    }) {
                        Text("Spel Afronden")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
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
        .alert("6 dezelfde!", isPresented: $showZesDezelfdeAlert) {
            Button("Ja, winnaar!") {
                if let winIndex = geselecteerdeWinnaarIndex, winIndex < spelers.count {
                    spelerWintMetZesDezelfde(index: winIndex)
                }
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            if let winIndex = geselecteerdeWinnaarIndex, winIndex < spelers.count {
                Text("Heeft \(spelers[winIndex].name) 6 kaarten van dezelfde waarde verzameld? Dan wint \(spelers[winIndex].name) direct!")
            } else {
                Text("Heeft deze speler 6 dezelfde?")
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

    private func spelerWintMetZesDezelfde(index: Int) {
        // Totaal bijwerken
        for i in spelers.indices {
            if i < rondeScores.count && i < totaleScores.count {
                totaleScores[i] += rondeScores[i]
            }
        }
        winnaar = spelers[index]
        showWinnaarView = true
    }

    private func volgendeRonde() {
        // Totaal bijwerken
        for i in spelers.indices {
            if i < rondeScores.count && i < totaleScores.count {
                totaleScores[i] += rondeScores[i]
            }
        }

        huidigeRonde += 1
        rondeScores = Array(repeating: 0, count: spelers.count)
        withAnimation {
            isExpanded = Array(repeating: false, count: spelers.count)
        }
    }

    private func sluitSpelHandmatigAf() {
        for i in spelers.indices {
            if i < rondeScores.count && i < totaleScores.count {
                totaleScores[i] += rondeScores[i]
            }
        }
        bepaalWinnaar()
        showWinnaarView = true
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
    JattenGameView(spelers: [Player(name: "Speler 1"), Player(name: "Speler 2")])
}
