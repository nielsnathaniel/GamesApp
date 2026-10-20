import SwiftUI

struct RegenwormenGameView: View {
    var spelers: [Player]

    @State private var scores: [Int] = []
    @State private var selectedPlayerIndex: Int = 0
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
                HStack {
                    Image(systemName: "circle.hexagongrid.fill")
                        .foregroundColor(.orange)
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
                                    scores[selectedPlayerIndex] += aantal
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
                                scores[selectedPlayerIndex] -= 1
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
                                    scores[selectedPlayerIndex] += steen.wormen
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

    private func bepaalWinnaar() {
        if let maxScore = scores.max(),
           let winnaarIndex = scores.firstIndex(of: maxScore) {
            winnaar = spelers[winnaarIndex]
        } else {
            winnaar = spelers.first
        }
    }
}

#Preview {
    RegenwormenGameView(spelers: [Player(name: "Speler 1"), Player(name: "Speler 2")])
}
