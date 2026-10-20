import SwiftUI

struct PlayerSelectionView: View {
    @Binding var selectedPlayers: [Player]
    @State private var savedScores: [String: [String: Int]] = [:]

    var body: some View {
        NavigationView {
            List {
                // Verwijder of pas de functionaliteit aan om geen spelers te laden
            }
            .navigationTitle("Selecteer Spelers")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klaar") {
                        // Sluit de view
                    }
                }
            }
        }
    }
}

#Preview {
    PlayerSelectionView(selectedPlayers: .constant([]))
}
