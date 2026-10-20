import SwiftUI

struct CrockinoleGameView: View {
    var spelers: [String] = ["Wit", "Zwart"]
    var puntenMethode: String = "Alles"

    // Ronde-invoer scores [Wit, Zwart]
    @State private var scores: [Int] = [0, 0]
    // Gewonnen sets [Wit, Zwart]
    @State private var setScores: [Int] = [0, 0]
    // Cumulatieve score in de huidige set [Wit, Zwart]
    @State private var totaleScores: [Int] = [0, 0]
    @State private var huidigeRonde: Int = 1
    @State private var showWinnaarView: Bool = false
    @State private var winnaar: String?

    // Selecties voor de rekentool
    @State private var selectedPlayerIndex: Int = 0 // 0 = Wit, 1 = Zwart
    @State private var selectedPoints: Int = 5

    let beschikbarePunten = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 4) {
                    Text("Crockinole")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Ronde \(huidigeRonde)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                // 1. Speler-tegels (Wit & Zwart)
                HStack(spacing: 16) {
                    ForEach(0..<min(spelers.count, 2), id: \.self) { index in
                        playerTile(for: index)
                    }
                }
                .padding(.horizontal)

                // Statusbalkje met actieve speler en optie tot reset van deze ronde
                HStack {
                    Text("Geselecteerd: ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    + Text(spelers[safe: selectedPlayerIndex] ?? "Speler")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    Spacer()

                    if scores[0] > 0 || scores[1] > 0 {
                        Button(action: {
                            scores = [0, 0]
                        }) {
                            Label("Ronde wissen", systemImage: "arrow.counterclockwise")
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // 2. Puntentegels (5, 10, 15, 20, 25, 30, 35, 40, 45, 50)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kies punten")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                        ForEach(beschikbarePunten, id: \.self) { punten in
                            Button(action: {
                                selectedPoints = punten
                            }) {
                                Text("\(punten)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(selectedPoints == punten ? Color.blue : Color(UIColor.secondarySystemBackground))
                                    .foregroundColor(selectedPoints == punten ? .white : .primary)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedPoints == punten ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // 3. Knop Toevoegen
                Button(action: {
                    if selectedPlayerIndex < scores.count {
                        scores[selectedPlayerIndex] += selectedPoints
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("\(selectedPoints) punten toevoegen aan \(spelers[safe: selectedPlayerIndex] ?? "")")
                            .fontWeight(.semibold)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(12)
                    .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal)

                // 4. Knop Ronde beëindigen
                Button(action: {
                    berekenRondeEnBeëindig()
                }) {
                    HStack {
                        Image(systemName: "flag.checkered")
                        Text("Ronde beëindigen")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal)
                .padding(.top, 4)

                Spacer(minLength: 20)
            }
        }
        .navigationDestination(isPresented: $showWinnaarView) {
            if let winnaar = winnaar {
                WinnaarView(
                    gameName: "Crockinole",
                    winnaarNaam: winnaar,
                    spelersNamen: spelers,
                    scores: setScores,
                    isLowestScoreWins: false
                )
            }
        }
    }

    // Spelertegel voor Wit of Zwart
    private func playerTile(for index: Int) -> some View {
        let isSelected = selectedPlayerIndex == index
        let naam = spelers[safe: index] ?? "Speler \(index + 1)"
        let isWit = index == 0 || naam.lowercased() == "wit"

        return Button(action: {
            selectedPlayerIndex = index
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle()
                        .fill(isWit ? Color.white : Color.black)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))

                    Text(naam)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Deze ronde")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(scores[safe: index] ?? 0) pt")
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Totaal:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(totaleScores[safe: index] ?? 0) pt")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Sets:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(setScores[safe: index] ?? 0) / 3")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.2) : Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
    }

    // Crokinole puntentelling conform officiële regels
    private func berekenRondeEnBeëindig() {
        let score0 = scores.indices.contains(0) ? scores[0] : 0
        let score1 = scores.indices.contains(1) ? scores[1] : 0

        if score0 > score1 {
            let diff = score0 - score1
            totaleScores[0] += diff
        } else if score1 > score0 {
            let diff = score1 - score0
            totaleScores[1] += diff
        }
        // Bij gelijkspel: geen punten toegekend

        // Controleer of een speler 100 punten heeft bereikt om een set te winnen
        for i in 0..<min(spelers.count, 2) {
            if totaleScores[i] >= 100 {
                setScores[i] += 1
                totaleScores[i] = 0 // Reset set-totaal na winnen van de set
            }
        }

        // Controleer of een speler 3 sets heeft gewonnen
        if let winnaarIndex = setScores.firstIndex(where: { $0 >= 3 }) {
            winnaar = spelers[winnaarIndex]
            showWinnaarView = true
        }

        // Reset ronde-invoer voor de volgende ronde
        scores = [0, 0]
        huidigeRonde += 1
    }
}

#Preview {
    CrockinoleGameView(spelers: ["Wit", "Zwart"], puntenMethode: "Alles")
}