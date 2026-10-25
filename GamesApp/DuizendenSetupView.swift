import SwiftUI

struct DuizendenSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @State private var aantalSpellenKaarten: Int = 2
    @State private var aantalSpelers: Int = 2
    @State private var spelers: [String] = Array(repeating: "", count: 6)
    @State private var eindscore: Int = 1000
    @State private var showAlert = false
    @FocusState private var focusedField: Int?

    var body: some View {
        ScrollView {
                VStack {
                    HStack(spacing: 12) {
                        Image("Duizenden")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .shadow(color: .teal.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Text("Duizenden")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 0)
                    .frame(maxWidth: .infinity, alignment: .center)

                    // Kies aantal spellen kaarten
                    Text("Aantal Spellen Kaarten")
                        .font(.headline)
                    HStack {
                        ForEach(2...4, id: \.self) { number in
                            Button(action: {
                                aantalSpellenKaarten = number
                            }) {
                                Text("\(number)")
                                    .font(.title3)
                                    .foregroundColor(aantalSpellenKaarten == number ? .white : .blue)
                                    .padding(8)
                                    .background(aantalSpellenKaarten == number ? Color.blue : Color.clear)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()

                    // Kies aantal spelers
                    Text("Aantal Spelers")
                        .font(.headline)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                        ForEach(2...6, id: \.self) { number in
                            Button(action: {
                                aantalSpelers = number
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

                    // Eindscore instellen
                    Text("Eindscore")
                        .font(.headline)
                    HStack {
                        Button(action: {
                            if eindscore > 500 {
                                eindscore -= 100
                            }
                        }) {
                            Image(systemName: "minus.circle")
                                .font(.title)
                                .foregroundColor(.red)
                        }
                        Text("\(eindscore)")
                            .font(.title2)
                            .frame(width: 60)
                        Button(action: {
                            if eindscore < 2000 {
                                eindscore += 100
                            }
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.title)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()

                    // Opgeslagen Spelers Quick Chips
                    SavedPlayersQuickChipsView(
                        spelers: $spelers,
                        aantalSpelers: aantalSpelers,
                        tintColor: .teal
                    )

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
                    NavigationLink(destination: DuizendenGameView(spelers: spelers.prefix(aantalSpelers).map { Player(name: $0) }, aantalSpellenKaarten: aantalSpellenKaarten, eindscore: eindscore)) {
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
    DuizendenSetupView()
} 