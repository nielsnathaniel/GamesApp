import SwiftUI

struct OpgeslagenSpelersView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @State private var searchText: String = ""
    @State private var showAddPlayerAlert: Bool = false
    @State private var newPlayerName: String = ""
    @State private var playerToDelete: String? = nil
    @State private var showDeleteSingleAlert: Bool = false
    @State private var showClearAllAlert: Bool = false
    @State private var playerToEdit: String? = nil

    private var filteredPlayers: [String] {
        let players = scoreManager.fetchPlayerNames()
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return players
        } else {
            return players.filter { $0.localizedCaseInsensitiveContains(trimmed) }
        }
    }

    var body: some View {
        List {
            // Actieknop om direct een speler toe te voegen
            Section {
                Button(action: {
                    newPlayerName = ""
                    showAddPlayerAlert = true
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 32, height: 32)
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.system(size: 15, weight: .bold))
                        }

                        Text("Nieuwe speler toevoegen")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)

                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }

            // Spelersoverzicht
            Section {
                if filteredPlayers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: searchText.isEmpty ? "person.crop.circle.badge.questionmark" : "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.top, 16)

                        Text(searchText.isEmpty ? "Geen opgeslagen spelers" : "Geen spelers gevonden voor '\(searchText)'")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(searchText.isEmpty ? "Spelers die je gebruikt bij het starten van een potje worden hier automatisch bewaard." : "Probeer een andere zoekterm.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredPlayers, id: \.self) { player in
                        HStack(spacing: 12) {
                            // Avatar Badge
                            PlayerAvatarView(name: player, size: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(player)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                let playCount = scoreManager.playerPlayCount(for: player)
                                Text(playCount == 1 ? "1 potje gespeeld" : "\(playCount) potjes gespeeld")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            // Bewerken knop (Tafelkleur & avatar/foto)
                            Button(action: {
                                HapticManager.shared.light()
                                playerToEdit = player
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "paintpalette.fill")
                                        .font(.system(size: 12))
                                    Text("Profiel")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(scoreManager.profile(for: player).color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(scoreManager.profile(for: player).color.opacity(0.12))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)

                            // Verwijder knop
                            Button(role: .destructive, action: {
                                playerToDelete = player
                                showDeleteSingleAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.red.opacity(0.7))
                                    .padding(6)
                                    .background(Color.red.opacity(0.08))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            playerToEdit = player
                        }
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            if idx < filteredPlayers.count {
                                scoreManager.deletePlayer(name: filteredPlayers[idx])
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Opgeslagen Spelers")
                    Spacer()
                    Text("\(filteredPlayers.count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                }
            } footer: {
                if !filteredPlayers.isEmpty {
                    Text("Veeg naar links of tik op de prullenbak om een speler te verwijderen.")
                        .font(.caption2)
                }
            }

            // Volledig wissen optie
            if !scoreManager.fetchPlayerNames().isEmpty {
                Section {
                    Button(role: .destructive, action: {
                        showClearAllAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Label("Alle spelers wissen", systemImage: "trash.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("Opgeslagen Spelers")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Zoek speler...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    newPlayerName = ""
                    showAddPlayerAlert = true
                }) {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            scoreManager.refresh()
        }
        .alert("Nieuwe Speler Toevoegen", isPresented: $showAddPlayerAlert) {
            TextField("Spelersnaam", text: $newPlayerName)
            Button("Opslaan") {
                let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    withAnimation {
                        scoreManager.savePlayerName(trimmed)
                    }
                }
            }
            Button("Annuleer", role: .cancel) {}
        }
        .alert("Speler Verwijderen", isPresented: $showDeleteSingleAlert) {
            Button("Verwijder", role: .destructive) {
                if let p = playerToDelete {
                    withAnimation {
                        scoreManager.deletePlayer(name: p)
                    }
                }
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            if let p = playerToDelete {
                Text("Weet je zeker dat je '\(p)' wilt verwijderen uit de lijst met opgeslagen spelers?")
            } else {
                Text("Weet je zeker dat je deze speler wilt verwijderen?")
            }
        }
        .confirmationDialog(
            "Weet je zeker dat je alle opgeslagen spelers wilt wissen?",
            isPresented: $showClearAllAlert,
            titleVisibility: .visible
        ) {
            Button("Alle spelers wissen", role: .destructive) {
                withAnimation {
                    scoreManager.clearAllPlayers()
                }
            }
            Button("Annuleer", role: .cancel) {}
        }
        .sheet(isPresented: Binding(
            get: { playerToEdit != nil },
            set: { if !$0 { playerToEdit = nil } }
        )) {
            if let target = playerToEdit {
                PlayerProfileEditSheet(playerName: target)
            }
        }
    }

    private func playerInitials(_ name: String) -> String {
        let parts = name.split(separator: " ").map { String($0) }
        if parts.count >= 2, let first = parts.first?.first, let second = parts[1].first {
            return "\(first)\(second)".uppercased()
        } else if let first = name.first {
            return String(first).uppercased()
        }
        return "?"
    }

    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [.blue, .purple, .teal, .indigo, .orange, .pink, .green]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
}

#Preview {
    NavigationStack {
        OpgeslagenSpelersView()
    }
}
