import SwiftUI

struct GegevensbeheerView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @State private var showClearHistoryAlert: Bool = false
    @State private var showClearPlayersAlert: Bool = false

    var body: some View {
        List {
            // Samenvatting Header Card
            Section {
                HStack(spacing: 16) {
                    // Spelers indicator
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("Spelers")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("\(scoreManager.fetchPlayerNames().count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(10)

                    // Spelsessies indicator
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Sessies")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("\(scoreManager.playedGames.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }

            // Beheer navigatie knoppen
            Section(header: Text("Beheer")) {
                // Knop naar Opgeslagen Spelers
                NavigationLink(destination: OpgeslagenSpelersView()) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .semibold))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Opgeslagen Spelers")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Spelers bekijken, toevoegen en verwijderen")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("\(scoreManager.fetchPlayerNames().count)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                }

                // Knop naar Opgeslagen Spelsessies
                NavigationLink(destination: SpelsessiesBeheerView()) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.orange)
                                .font(.system(size: 16, weight: .semibold))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Opgeslagen Spelsessies")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Geschiedenis per dag, spel of sessie wissen")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("\(scoreManager.playedGames.count)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                }
            }

            // Gevaarlijke Acties / Volledige Reset
            Section(header: Text("Volledige Reset"), footer: Text("Let op: Deze acties kunnen niet ongedaan worden gemaakt. Gebruik 'Opgeslagen Spelsessies' om gericht per dag of potje te verwijderen.")) {
                Button(role: .destructive, action: {
                    showClearHistoryAlert = true
                }) {
                    Label("Alle spelgeschiedenis & scores wissen", systemImage: "arrow.counterclockwise")
                        .foregroundColor(.red)
                }

                Button(role: .destructive, action: {
                    showClearPlayersAlert = true
                }) {
                    Label("Alle opgeslagen spelers wissen", systemImage: "person.crop.circle.badge.minus")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Gegevensbeheer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scoreManager.refresh()
        }
        .confirmationDialog(
            "Weet je zeker dat je alle spelgeschiedenis wilt wissen?",
            isPresented: $showClearHistoryAlert,
            titleVisibility: .visible
        ) {
            Button("Alle geschiedenis wissen", role: .destructive) {
                withAnimation {
                    scoreManager.clearHistory()
                }
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            Text("Alle opgeslagen potjes, statistieken en scores worden permanent verwijderd.")
        }
        .confirmationDialog(
            "Weet je zeker dat je alle opgeslagen spelers wilt wissen?",
            isPresented: $showClearPlayersAlert,
            titleVisibility: .visible
        ) {
            Button("Alle spelers wissen", role: .destructive) {
                withAnimation {
                    scoreManager.clearAllPlayers()
                }
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            Text("Alle opgeslagen spelersnamen worden gewist. Je kunt ze later weer handmatig of bij een nieuw spel toevoegen.")
        }
    }
}

#Preview {
    NavigationStack {
        GegevensbeheerView()
    }
}
