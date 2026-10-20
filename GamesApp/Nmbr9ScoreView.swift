import SwiftUI

struct Nmbr9ScoreView: View {
    var spelers: [Player]

    @State private var scores: [[Int]] = []
    @State private var totaleScores: [Int] = []
    @State private var huidigeRonde: Int = 1
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
                            isLowestScoreWins: false
                        )
                    }
                }
            }
            .padding()
            .onAppear {
                scores = Array(repeating: Array(repeating: 0, count: 4), count: spelers.count)
                totaleScores = Array(repeating: 0, count: spelers.count)
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
        for index in spelers.indices {
            if index < scores.count {
                let rondeScore = scores[index].reduce(0, +)
                if index < totaleScores.count {
                    totaleScores[index] += rondeScore
                }
            }
        }
    }

    private func naarVolgendeRonde() {
        huidigeRonde += 1
        scores = Array(repeating: Array(repeating: 0, count: 4), count: spelers.count)
    }

    private func bepaalWinnaar() {
        if let winnaarIndex = totaleScores.enumerated().min(by: { $0.element < $1.element })?.offset {
            winnaar = spelers[winnaarIndex]
        }
    }

    private func resetRandomNumbers() {
        randomNumbers = (0...9).flatMap { Array(repeating: $0, count: 2) }.shuffled()
        currentRandomIndex = 0
    }
}

#Preview {
    Nmbr9ScoreView(spelers: [Player(name: "Speler 1"), Player(name: "Speler 2")])
}
