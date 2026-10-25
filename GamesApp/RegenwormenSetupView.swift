import SwiftUI

struct RegenwormenSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @State private var aantalSpelers: Int = 2
    @State private var spelers: [String] = Array(repeating: "", count: 7)
    @State private var showAlert = false
    @FocusState private var focusedField: Int?

    var body: some View {
        ScrollView {
            VStack {
                HStack(spacing: 12) {
                    if UIImage(named: "Regenwormen") != nil {
                        Image("Regenwormen")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Image(systemName: "circle.hexagongrid.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                    }
                    
                    Text("Regenwormen")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 0)
                .frame(maxWidth: .infinity, alignment: .center)

                // Kies aantal spelers (2 t/m 7)
                Text("Aantal Spelers")
                    .font(.headline)
                    .padding(.top, 8)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                    ForEach(2...7, id: \.self) { number in
                        Button(action: {
                            aantalSpelers = number
                        }) {
                            Text("\(number)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(aantalSpelers == number ? .white : .orange)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(aantalSpelers == number ? Color.orange : Color.clear)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.orange, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding()

                // Opgeslagen Spelers Quick Chips
                SavedPlayersQuickChipsView(
                    spelers: $spelers,
                    aantalSpelers: aantalSpelers,
                    tintColor: .orange
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
                NavigationLink(destination: RegenwormenGameView(spelers: spelers.prefix(aantalSpelers).map { Player(name: $0) })) {
                    Text("Start Spel")
                        .font(.title2)
                        .fontWeight(.bold)
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
    RegenwormenSetupView()
}
