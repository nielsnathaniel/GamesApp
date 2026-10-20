import SwiftUI

struct DuizendenGameView: View {
    var spelers: [Player]
    var aantalSpellenKaarten: Int
    var eindscore: Int

    @State private var scores: [Int] = []
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
            Text("Duizenden Spel")
                .font(.largeTitle)
                .padding()

            Text("Aantal Spellen Kaarten: \(aantalSpellenKaarten)")
                .font(.headline)
                .padding()

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
                Text("Ronde Voltooien")
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
                        isLowestScoreWins: false
                    )
                }
            }
        }
        .padding()
        .onAppear {
            scores = Array(repeating: 0, count: spelers.count)
            tafelScores = Array(repeating: Array(repeating: 0, count: kaartSymbolen.count), count: spelers.count)
            handScores = Array(repeating: Array(repeating: 0, count: kaartSymbolen.count), count: spelers.count)
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
        for index in spelers.indices {
            var tafelScore = 0
            var handScore = 0
            for i in kaartSymbolen.indices {
                let waarde = kaartWaarde(voor: kaartSymbolen[i])
                tafelScore += tafelScores[index][i] * waarde
                handScore += handScores[index][i] * waarde
            }
            scores[index] += tafelScore - handScore
        }
        // Reset ingevoerde tafel- en handkaarten voor de volgende ronde
        tafelScores = Array(repeating: Array(repeating: 0, count: kaartSymbolen.count), count: spelers.count)
        handScores = Array(repeating: Array(repeating: 0, count: kaartSymbolen.count), count: spelers.count)
    }

    private func checkWinnaar() {
        if let maxScore = scores.max(), maxScore >= eindscore {
            let winnaars = spelers.indices.filter { scores[$0] == maxScore }
            if winnaars.count == 1 {
                winnaar = spelers[winnaars[0]]
            } else {
                winnaar = spelers[winnaars.max(by: { scores[$0] < scores[$1] }) ?? 0]
            }
            showWinnaarView = true
        }
    }
}

#Preview {
    DuizendenGameView(spelers: [Player(name: "Speler 1"), Player(name: "Speler 2")], aantalSpellenKaarten: 2, eindscore: 1000)
}
