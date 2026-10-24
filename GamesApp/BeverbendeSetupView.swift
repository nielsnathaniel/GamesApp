import SwiftUI

struct BeverbendeSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var aantalSpelers: Int = 2
    @State private var aantalRondes: Int = 2
    @State private var speelwijze: Speelwijze = .gelijkAanAantalSpelers
    @State private var spelers: [String] = Array(repeating: "", count: 6)
    @State private var showAlert = false

    enum Speelwijze {
        case gelijkAanAantalSpelers
        case kiesZelf
    }

    private var effectiveAantalRondes: Int {
        speelwijze == .gelijkAanAantalSpelers ? aantalSpelers : aantalRondes
    }

    var body: some View {
        ScrollView {
            VStack {
                HStack(spacing: 12) {
                    Image("Beverbende")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Text("Beverbende")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 0)
                .frame(maxWidth: .infinity, alignment: .center)

                // Kies aantal spelers
                Text("Aantal Spelers")
                    .font(.headline)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                    ForEach(2...6, id: \.self) { number in
                        Button(action: {
                            aantalSpelers = number
                            if speelwijze == .gelijkAanAantalSpelers {
                                aantalRondes = number
                            }
                        }) {
                            Text("\(number)")
                                .font(.title2)
                                .foregroundColor(aantalSpelers == number ? .white : .blue)
                                .padding()
                                .background(aantalSpelers == number ? Color.blue : Color.clear)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()

                // Kies aantal rondes
                Text("Aantal Rondes")
                    .font(.headline)
                Picker("Speelwijze", selection: $speelwijze) {
                    Text("Gelijk aan aantal spelers").tag(Speelwijze.gelijkAanAantalSpelers)
                    Text("Kies zelf").tag(Speelwijze.kiesZelf)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: speelwijze) { _, newValue in
                    if newValue == .gelijkAanAantalSpelers {
                        aantalRondes = aantalSpelers
                    }
                }

                if speelwijze == .kiesZelf {
                    HStack {
                        Button(action: {
                            if aantalRondes > 3 {
                                aantalRondes -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle")
                                .font(.title)
                                .foregroundColor(.red)
                        }
                        Text("\(aantalRondes)")
                            .font(.title2)
                            .frame(width: 40)
                        Button(action: {
                            if aantalRondes < 8 {
                                aantalRondes += 1
                            }
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.title)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                }

                // Invoervelden voor spelersnamen met dropdown voorstellen
                VStack(spacing: 12) {
                    ForEach(0..<aantalSpelers, id: \.self) { index in
                        PlayerNameInputField(
                            placeholder: "Naam Speler \(index + 1)",
                            text: $spelers[index],
                            suggestions: scoreManager.savedPlayerNames,
                            submitLabel: index < aantalSpelers - 1 ? .next : .done
                        )
                        .padding(.horizontal)
                    }
                }

                Spacer(minLength: 20)

                // Start spel knop
                NavigationLink(destination: BeverbendeScoreView(aantalRondes: effectiveAantalRondes, spelers: spelers.prefix(aantalSpelers).map { Player(name: $0) })) {
                    Text("Start Spel")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    scoreManager.savePlayerNames(spelers.prefix(aantalSpelers).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
                })
                .padding(.horizontal)
                .disabled(spelers.prefix(aantalSpelers).contains(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty }))
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Invoerfout"), message: Text("Vul alle spelersnamen in."), dismissButton: .default(Text("OK")))
                }
            }
            .padding()
        }
        .onAppear {
            scoreManager.refresh()
        }
    }
}

#Preview {
    BeverbendeSetupView()
}
