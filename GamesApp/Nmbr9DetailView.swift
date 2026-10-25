import SwiftUI

enum Rekenversie: String, CaseIterable, Identifiable {
    case totaalwaardePerLaag = "Totaalwaarde per laag"
    case aanvinkenPerLaag = "Aanvinken per laag"
    
    var id: String { self.rawValue }
}

enum Speelwijze: String, CaseIterable, Identifiable {
    case aantalRondes = "Aantal rondes"
    case totScore = "Tot score"
    
    var id: String { self.rawValue }
}

struct Nmbr9DetailView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @State private var aantalSpelers: Int = 2
    @State private var spelers: [Player] = Array(repeating: Player(name: ""), count: 4)
    @State private var selectedRekenversie: Rekenversie = .totaalwaardePerLaag
    @State private var selectedSpeelwijze: Speelwijze = .aantalRondes
    @State private var aantalRondes: Int = 4
    @State private var totaleScore: Int = 150
    @FocusState private var focusedField: Int?

    var body: some View {
        ScrollView {
            VStack {
                HStack(spacing: 12) {
                    if let uiImg = UIImage(named: "Nmbr9") ?? UIImage(named: "NMbr9") {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .shadow(color: .indigo.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Image(systemName: "number.square.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.indigo)
                    }
                    
                    Text("Nmbr9")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading) {
                    Text("Aantal spelers:")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 0.8) {
                        ForEach(2...4, id: \.self) { number in
                            Button(action: {
                                aantalSpelers = number
                            }) {
                                Text("\(number)")
                                    .font(.title)
                                    .frame(width: 60, height: 60)
                                    .background(aantalSpelers == number ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal)

                VStack(alignment: .leading) {
                    Text("Rekenversie:")
                        .font(.headline)
                    
                    Picker("Rekenversie", selection: $selectedRekenversie) {
                        ForEach(Rekenversie.allCases) { versie in
                            Text(versie.rawValue).tag(versie)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)

                VStack(alignment: .leading) {
                    Text("Speelwijze:")
                        .font(.headline)
                    
                    Picker("Speelwijze", selection: $selectedSpeelwijze) {
                        ForEach(Speelwijze.allCases) { wijze in
                            Text(wijze.rawValue).tag(wijze)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)

                if selectedSpeelwijze == .aantalRondes {
                    HStack {
                        Button(action: {
                            if aantalRondes > 1 {
                                aantalRondes -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle")
                                .font(.title)
                                .foregroundColor(.red)
                        }
                        Text("\(aantalRondes) rondes")
                            .font(.title2)
                            .padding(.horizontal)
                        Button(action: {
                            if aantalRondes < 9 {
                                aantalRondes += 1
                            }
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.title)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.top, 10)
                }

                if selectedSpeelwijze == .totScore {
                    HStack {
                        Button(action: {
                            if totaleScore > 50 {
                                totaleScore -= 10
                            }
                        }) {
                            Image(systemName: "minus.circle")
                                .font(.title)
                                .foregroundColor(.red)
                        }
                        Text("\(totaleScore) punten")
                            .font(.title2)
                            .padding(.horizontal)
                        Button(action: {
                            if totaleScore < 500 {
                                totaleScore += 10
                            }
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.title)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.top, 10)
                }

                // Opgeslagen Spelers Quick Chips
                SavedPlayersQuickChipsView(
                    spelers: Binding(
                        get: { spelers.map { $0.name } },
                        set: { newNames in
                            for i in 0..<spelers.count {
                                if i < newNames.count {
                                    spelers[i].name = newNames[i]
                                }
                            }
                        }
                    ),
                    aantalSpelers: aantalSpelers,
                    tintColor: .indigo
                )

                VStack(spacing: 12) {
                    ForEach(0..<aantalSpelers, id: \.self) { index in
                        PlayerNameInputField(
                            placeholder: "Naam speler \(index + 1)",
                            text: $spelers[index].name,
                            suggestions: scoreManager.savedPlayerNames,
                            submitLabel: index < aantalSpelers - 1 ? .next : .done
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 5)

                NavigationLink(destination: destinationView()) {
                    Text("Start Spel")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    scoreManager.savePlayerNames(spelers.prefix(aantalSpelers).map { $0.name }.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
                })
                .disabled(spelers.prefix(aantalSpelers).contains(where: { $0.name.trimmingCharacters(in: .whitespaces).isEmpty }))
                .padding(.horizontal)
                .padding(.top, 20)

                Spacer()
            }
            .padding()
        }
        .onAppear {
            scoreManager.refresh()
        }
    }

    @ViewBuilder
    private func destinationView() -> some View {
        CurrentGameView(gameName: "Nmbr9", imageName: "Nmbr9", spelers: Array(spelers.prefix(aantalSpelers)), rekenversie: selectedRekenversie, speelwijze: selectedSpeelwijze, aantalRondes: aantalRondes, totaleScore: totaleScore)
    }
}

#Preview {
    Nmbr9DetailView()
}
