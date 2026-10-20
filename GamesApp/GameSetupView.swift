import SwiftUI

struct GameSetupView: View {
    @State private var selectedPlayers: [Player] = []
    @State private var showPlayerSelection: Bool = false
    @State private var aantalSpelers: Int = 2
    @State private var rekenversie: Rekenversie = .totaalwaardePerLaag
    @State private var speelwijze: Speelwijze = .aantalRondes

    var body: some View {
        VStack {
            Text("Spel Instellingen")
                .font(.largeTitle)
                .padding()

            Button(action: {
                showPlayerSelection = true
            }) {
                Text("Kies bestaande spelers")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .sheet(isPresented: $showPlayerSelection) {
                PlayerSelectionView(selectedPlayers: $selectedPlayers)
            }

            // Voeg hier de UI-elementen toe voor het kiezen van aantal spelers, rekenversie, speelwijze, etc.
            Picker("Aantal Spelers", selection: $aantalSpelers) {
                ForEach(2...6, id: \.self) { number in
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Picker("Rekenversie", selection: $rekenversie) {
                Text("Totaalwaarde Per Laag").tag(Rekenversie.totaalwaardePerLaag)
                // Voeg andere opties toe indien nodig
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Picker("Speelwijze", selection: $speelwijze) {
                Text("Aantal Rondes").tag(Speelwijze.aantalRondes)
                Text("Tot Score").tag(Speelwijze.totScore)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Spacer()

            Button(action: {
                // Start het spel met de gekozen instellingen
            }) {
                Text("Start Spel")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    GameSetupView()
}
