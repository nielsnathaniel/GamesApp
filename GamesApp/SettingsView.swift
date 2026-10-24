import SwiftUI

struct SettingsView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @State private var showClearHistoryAlert: Bool = false
    @State private var showClearPlayersAlert: Bool = false
    @State private var showAddPlayerAlert: Bool = false
    @State private var newPlayerName: String = ""

    var body: some View {
        NavigationStack {
            List {
                // 1. Spelersbeheer
                Section(header: Label("Opgeslagen Spelers", systemImage: "person.2.fill")) {
                    let players = scoreManager.fetchPlayerNames()
                    if players.isEmpty {
                        Text("Geen opgeslagen spelers.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(players, id: \.self) { player in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                Text(player)
                                    .fontWeight(.medium)
                            }
                        }
                        .onDelete { indexSet in
                            for idx in indexSet {
                                if idx < players.count {
                                    scoreManager.deletePlayer(name: players[idx])
                                }
                            }
                        }
                    }

                    Button(action: {
                        newPlayerName = ""
                        showAddPlayerAlert = true
                    }) {
                        Label("Speler handmatig toevoegen", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }

                // 2. Spelgeschiedenis & Spelsessies
                Section(header: Label("Geschiedenis & Spelsessies", systemImage: "clock.arrow.circlepath")) {
                    NavigationLink(destination: SpelsessiesBeheerView()) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 18))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Spelsessies Beheren")
                                    .font(.headline)
                                Text("Verwijder per dag, per spel of per sessie")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text("\(scoreManager.playedGames.count)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 4)
                    }

                    let games = scoreManager.playedGames
                    if games.isEmpty {
                        Text("Nog geen gespeelde potjes opgeslagen.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(games.reversed()) { game in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(game.sessionTitle)
                                        .font(.headline)
                                    Spacer()
                                    Text(game.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                if !game.winner.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(.yellow)
                                        Text("Winnaar: \(game.winner)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                }

                                // Scores
                                HStack {
                                    ForEach(game.scores) { sc in
                                        Text("\(sc.playerName): \(sc.score)")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            let reversedGames = Array(games.reversed())
                            for idx in indexSet {
                                if idx < reversedGames.count {
                                    scoreManager.deleteGame(id: reversedGames[idx].id)
                                }
                            }
                        }
                    }
                }

                // 3. Gegevensbeheer & Reset acties
                Section(header: Label("Gegevensbeheer", systemImage: "trash.fill")) {
                    Button(role: .destructive, action: {
                        showClearHistoryAlert = true
                    }) {
                        Label("Spelgeschiedenis & scores wissen", systemImage: "arrow.counterclockwise")
                    }

                    Button(role: .destructive, action: {
                        showClearPlayersAlert = true
                    }) {
                        Label("Alle opgeslagen spelers wissen", systemImage: "person.crop.circle.badge.minus")
                    }
                }

                // 4. Speluitleg & Regels
                Section(header: Label("Spelregels Quick Reference", systemImage: "book.closed.fill")) {
                    DisclosureGroup("Balzakken Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Doel: Minste punten overhouden (einde bij 100 strafpunten)")
                            Text("• Kaarten: Balzakken van -1 (Bruisbal) t/m 11 (Blauwe Bal)")
                            Text("• De Swinger: Ruil je hand met een tegenspeler (0 pt als een ander Balzak roept)")
                            Text("• De Lul: Tegenstander pakt 2 kaarten (10 strafpunten als een ander Balzak roept!)")
                            Text("• BALZAK! roepen: Alleen tijdens je beurt met 5 punten of minder (zonder actiekaart)")
                            Text("• Goeie Balzak!: Roeper noteert 0 punten, overige spelers noteren handpunten")
                            Text("• Valse Balzak!: Roeper krijgt 25 strafpunten! Laagste speler noteert 0 punten")
                            Text("• Precies 69 punten: Strafpunten gaan terug naar 50!")
                            Text("• Precies 99 punten: Strafpunten gaan terug naar 75!")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }

                    DisclosureGroup("Jatten Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Doel: Als eerste 6 kaarten van dezelfde waarde verzamelen!")
                            Text("• Einde: Het spel stopt direct zodra iemand 6 dezelfde heeft")
                            Text("• Beurt 1: Leg 1 kaart uit je hand open in je verzameling")
                            Text("• Beurt 2: Steel kaarten blind uit de hand van 1 tegenstander")
                            Text("• Pas op: Trek je 2 dezelfde waarden tijdens het jatten? Beurt voorbij en buit terug!")
                            Text("• Oplichter: Steel 1 open kaart naar keuze uit de verzameling van het slachtoffer")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }

                    DisclosureGroup("Duizenden Kaartwaardes") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Joker = 25 punten")
                            Text("• Aas = 20 punten")
                            Text("• Heer / Vrouw / Boer / 10 = 10 punten")
                            Text("• Kaarten 4 t/m 9 = 5 punten")
                            Text("• Schoppen 3 = 100 strafpunten (bij verlies)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }

                    DisclosureGroup("Beverbende Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Laagste totaalscore na alle rondes wint")
                            Text("• Waarde van kaarten: 0 t/m 9")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }

                    DisclosureGroup("Crockinole Regels") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Puntenverschil per ronde gaat naar de rondewinnaar")
                            Text("• 100 punten nodig om een set te winnen")
                            Text("• Wie als eerste 3 sets wint, wint de wedstrijd!")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }
                }

                // 5. Over GamesApp
                Section(header: Label("Over GamesApp", systemImage: "info.circle.fill")) {
                    HStack {
                        Text("Versie")
                        Spacer()
                        Text("1.0 (iOS 18+)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Ondersteunde Spellen")
                        Spacer()
                        Text("7 spellen")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Instellingen")
            .onAppear {
                scoreManager.refresh()
            }
            .alert("Nieuwe Speler Toevoegen", isPresented: $showAddPlayerAlert) {
                TextField("Spelersnaam", text: $newPlayerName)
                Button("Opslaan") {
                    let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        scoreManager.savePlayerName(trimmed)
                    }
                }
                Button("Annuleer", role: .cancel) {}
            }
            .confirmationDialog(
                "Weet je zeker dat je alle spelgeschiedenis wilt wissen?",
                isPresented: $showClearHistoryAlert,
                titleVisibility: .visible
            ) {
                Button("Geschiedenis wissen", role: .destructive) {
                    scoreManager.clearHistory()
                }
                Button("Annuleer", role: .cancel) {}
            }
            .confirmationDialog(
                "Weet je zeker dat je alle opgeslagen spelers wilt wissen?",
                isPresented: $showClearPlayersAlert,
                titleVisibility: .visible
            ) {
                Button("Spelers wissen", role: .destructive) {
                    scoreManager.clearAllPlayers()
                }
                Button("Annuleer", role: .cancel) {}
            }
        }
    }
}

#Preview {
    SettingsView()
}
