import SwiftUI

struct CurrentGameView: View {
    var gameName: String
    var imageName: String
    var spelers: [Player]
    var rekenversie: Rekenversie
    var speelwijze: Speelwijze
    var aantalRondes: Int
    var totaleScore: Int

    @State private var huidigeRonde: Int = 1
    @State private var scores: [Int] = []
    @State private var laagScores: [[Int]] = []
    @State private var totaleScores: [Int] = []
    @State private var isExpanded: [Bool] = []
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showWinnaarView: Bool = false
    @State private var winnaar: Player?
    @State private var showRandomNumberView: Bool = false
    @State private var randomNumbers: [Int] = []
    @State private var currentRandomIndex: Int = 0

    private func laagTitel(voor laag: Int) -> String {
        switch laag {
        case 0: return "Begane grond (x0)"
        case 1: return "Laag 1 (x1)"
        case 2: return "Laag 2 (x2)"
        case 3: return "Laag 3 (x3)"
        case 4: return "Laag 4 (x4)"
        default: return "Laag \(laag)"
        }
    }

    var body: some View {
        VStack {
            HStack {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.trailing, 10)
                
                Text(gameName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)

            if speelwijze == .aantalRondes {
                Text("Ronde \(huidigeRonde) van \(aantalRondes)")
                    .font(.title2)
                    .padding()
            } else {
                Text("Ronde \(huidigeRonde)")
                    .font(.title2)
                    .padding()
            }

            Spacer()

            ScrollView {
                VStack {
                    ForEach(spelers.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Button(action: {
                                if index < isExpanded.count {
                                    isExpanded[index].toggle()
                                }
                            }) {
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
                            }
                            .padding(.vertical, 5)

                            if index < isExpanded.count && isExpanded[index] {
                                TabView {
                                    ForEach(0..<5, id: \.self) { laag in
                                        VStack {
                                            Text(laagTitel(voor: laag))
                                                .font(.headline)
                                            HStack {
                                                Button(action: {
                                                    if index < laagScores.count, laag < laagScores[index].count, laagScores[index][laag] > 0 {
                                                        laagScores[index][laag] -= 1
                                                    }
                                                }) {
                                                    Image(systemName: "minus.circle")
                                                        .font(.title)
                                                        .foregroundColor((index < laagScores.count && laag < laagScores[index].count && laagScores[index][laag] > 0) ? .red : .gray)
                                                }
                                                .disabled(!(index < laagScores.count && laag < laagScores[index].count && laagScores[index][laag] > 0))

                                                if index < laagScores.count && laag < laagScores[index].count {
                                                    Text("\(laagScores[index][laag])")
                                                        .font(.title2)
                                                        .frame(width: 40)
                                                }

                                                Button(action: {
                                                    if index < laagScores.count, laag < laagScores[index].count {
                                                        laagScores[index][laag] += 1
                                                    }
                                                }) {
                                                    Image(systemName: "plus.circle")
                                                        .font(.title)
                                                        .foregroundColor(.green)
                                                }
                                            }
                                        }
                                        .padding()
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                                .frame(height: 150)
                            }
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
                    .background(Color.yellow)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .sheet(isPresented: $showRandomNumberView) {
                RandomNumberScreen(randomNumbers: $randomNumbers, currentRandomIndex: $currentRandomIndex)
            }

            Button(action: {
                if validateScores() {
                    berekenScores()
                    if speelwijze == .totScore {
                        if let winnaar = checkWinnaar() {
                            self.winnaar = winnaar
                            showWinnaarView = true
                        } else {
                            naarVolgendeRonde()
                        }
                    } else if huidigeRonde == aantalRondes {
                        self.winnaar = bepaalWinnaar()
                        showWinnaarView = true
                    } else {
                        naarVolgendeRonde()
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
                        gameName: gameName,
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
            scores = Array(repeating: 0, count: spelers.count)
            laagScores = Array(repeating: Array(repeating: 0, count: 5), count: spelers.count)
            totaleScores = Array(repeating: 0, count: spelers.count)
            isExpanded = Array(repeating: false, count: spelers.count)
            resetRandomNumbers()
        }
    }

    private func validateScores() -> Bool {
        // Niet-gebouwde lagen mogen 0 zijn en blokkeren het afronden van het spel niet
        return true
    }

    private func berekenScores() {
        for index in spelers.indices {
            var rondeScore = 0
            for laag in 0..<5 {
                let factor = laag // Begane grond = x0, Laag 1 = x1, Laag 2 = x2, Laag 3 = x3, Laag 4 = x4
                if index < laagScores.count && laag < laagScores[index].count {
                    rondeScore += laagScores[index][laag] * factor
                }
            }
            if index < scores.count {
                scores[index] = rondeScore
                totaleScores[index] += rondeScore
            }
        }
    }

    private func naarVolgendeRonde() {
        huidigeRonde += 1
        laagScores = Array(repeating: Array(repeating: 0, count: 5), count: spelers.count)
    }

    private func checkWinnaar() -> Player? {
        let winnaars = spelers.enumerated().filter { $0.offset < totaleScores.count && totaleScores[$0.offset] >= totaleScore }
        if winnaars.count > 0 {
            return winnaars.max(by: { $0.offset < totaleScores.count && totaleScores[$0.offset] < totaleScores[$1.offset] })?.element
        }
        return nil
    }

    private func bepaalWinnaar() -> Player {
        return spelers.enumerated().max(by: { $0.offset < totaleScores.count && totaleScores[$0.offset] < totaleScores[$1.offset] })!.element
    }

    private func resetRandomNumbers() {
        randomNumbers = (0...9).flatMap { Array(repeating: $0, count: 2) }.shuffled()
        currentRandomIndex = 0
    }
}

#Preview {
    CurrentGameView(gameName: "Nmbr9", imageName: "Nmbr9", spelers: [Player(name: "Speler 1"), Player(name: "Speler 2")], rekenversie: .totaalwaardePerLaag, speelwijze: .totScore, aantalRondes: 4, totaleScore: 150)
}
