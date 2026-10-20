import SwiftUI

struct CrockinoleSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @State private var spelerWit: String = ""
    @State private var spelerZwart: String = ""
    @State private var puntenMethode: String = "Alles"
    @State private var showAlert = false

    private var effectiveSpelers: [String] {
        let w = spelerWit.trimmingCharacters(in: .whitespaces)
        let z = spelerZwart.trimmingCharacters(in: .whitespaces)
        return [
            w.isEmpty ? "Wit" : w,
            z.isEmpty ? "Zwart" : z
        ]
    }

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Image("Crockinole")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .padding(.trailing, 10)
                    
                    Text("Crockinole")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 0)
                .frame(maxWidth: .infinity, alignment: .center)

                Text("Spelers (Wit tegen Zwart)")
                    .font(.headline)
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    PlayerNameInputField(
                        placeholder: "Speler Wit (standaard: Wit)",
                        text: $spelerWit,
                        suggestions: scoreManager.savedPlayerNames,
                        submitLabel: .next
                    )

                    PlayerNameInputField(
                        placeholder: "Speler Zwart (standaard: Zwart)",
                        text: $spelerZwart,
                        suggestions: scoreManager.savedPlayerNames,
                        submitLabel: .done
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Kies punten invoer methode
                Text("Invoermethode")
                    .font(.headline)
                    .padding(.top, 4)

                Picker("Punten Invoer Methode", selection: $puntenMethode) {
                    Text("Alles").tag("Alles")
                    Text("Berekend").tag("Berekend")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 16)

                Spacer(minLength: 20)

                // Start spel knop
                NavigationLink(destination: CrockinoleGameView(spelers: effectiveSpelers, puntenMethode: puntenMethode)) {
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
                    let entered = [spelerWit, spelerZwart].map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty && $0.lowercased() != "wit" && $0.lowercased() != "zwart" }
                    if !entered.isEmpty {
                        scoreManager.savePlayerNames(entered)
                    }
                })
                .padding(.horizontal)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Invoerfout"), message: Text("Er is een fout opgetreden."), dismissButton: .default(Text("OK")))
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
    CrockinoleSetupView()
}
