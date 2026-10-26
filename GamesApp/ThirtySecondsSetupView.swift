import SwiftUI

struct ThirtySecondsSetupTeam: Identifiable {
    var id: UUID = UUID()
    var name: String
    var speler1: String = ""
    var speler2: String = ""
    var speler3: String = ""
    var color: Color

    var validPlayers: [String] {
        [speler1, speler2, speler3]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

struct ThirtySecondsSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    enum InvoerModus: String, CaseIterable, Identifiable {
        case live = "Ronde voor ronde"
        case snel = "Snelle eindscore"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .live: return "play.circle.fill"
            case .snel: return "bolt.fill"
            }
        }
    }

    @State private var invoerModus: InvoerModus = .live
    @State private var aantalTeams: Int = 2
    @State private var doelScore: Int = 35
    @State private var timerDuur: Int = 30

    @State private var teams: [ThirtySecondsSetupTeam] = [
        ThirtySecondsSetupTeam(name: "Team Oranje", speler1: "", speler2: "", speler3: "", color: .orange),
        ThirtySecondsSetupTeam(name: "Team Blauw", speler1: "", speler2: "", speler3: "", color: .blue),
        ThirtySecondsSetupTeam(name: "Team Groen", speler1: "", speler2: "", speler3: "", color: .green),
        ThirtySecondsSetupTeam(name: "Team Paars", speler1: "", speler2: "", speler3: "", color: .purple)
    ]

    @State private var showThirdPlayer: [Bool] = [false, false, false, false]
    @State private var showNewPlayerAlert: Bool = false
    @State private var newPlayerNameInput: String = ""

    private var actieveTeams: [ThirtySecondsSetupTeam] {
        Array(teams.prefix(aantalTeams))
    }

    private func effectiveTeamName(for index: Int) -> String {
        guard index < teams.count else { return "Team \(index + 1)" }
        let trimmed = teams[index].name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }

        let players = teams[index].validPlayers
        if players.count >= 2 {
            return "\(players[0]) & \(players[1])"
        } else if let first = players.first {
            return "Team \(first)"
        }
        return "Team \(index + 1)"
    }

    private var kanStarten: Bool {
        for team in actieveTeams {
            if team.validPlayers.count < 2 { return false }
        }

        let allPlayers = actieveTeams.flatMap { $0.validPlayers }
        let unique = Set(allPlayers.map { $0.lowercased() })
        return allPlayers.count == unique.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Header
                headerView

                // Speelwijze Kiezer (Live vs Snelle Eindscore)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Speelwijze")
                        .font(.headline)
                        .padding(.horizontal)

                    Picker("Speelwijze", selection: $invoerModus) {
                        ForEach(InvoerModus.allCases) { modus in
                            Label(modus.rawValue, systemImage: modus.icon).tag(modus)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }

                // 1. Aantal teams selector
                teamsCountSelector

                // 2. Doelscore & Timer selector (alleen bij live ronde voor ronde)
                if invoerModus == .live {
                    gameSettingsCard
                }

                // 3. Bestaande spelers Quick Chips
                quickChipsSection

                // 4. Teams Kaarten
                teamsListSection

                // 5. Start Spel Knop
                startButton
            }
            .padding(.vertical)
        }
        .navigationTitle("30 Seconds")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            scoreManager.refresh()
        }
        .alert("Nieuwe Speler Toevoegen", isPresented: $showNewPlayerAlert) {
            TextField("Naam speler", text: $newPlayerNameInput)
            Button("Voeg toe") {
                let trimmed = newPlayerNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    scoreManager.savePlayerName(trimmed)
                    newPlayerNameInput = ""
                }
            }
            Button("Annuleer", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                    .shadow(color: .orange.opacity(0.35), radius: 5, x: 0, y: 2)

                Image(systemName: "timer")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("30 Seconds")
                    .font(.largeTitle)
                    .fontWeight(.heavy)

                Text("Vorm teams, rol de dobbelsteen en race naar de finish!")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    // MARK: - Teams Aantal Selector

    private var teamsCountSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aantal Teams")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Picker("Aantal Teams", selection: $aantalTeams) {
                Text("2 Teams").tag(2)
                Text("3 Teams").tag(3)
                Text("4 Teams").tag(4)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal)
    }

    // MARK: - Instellingen Doelscore & Timer

    private var gameSettingsCard: some View {
        VStack(spacing: 14) {
            // Doelscore
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Finish / Doelscore")
                        .font(.headline)
                    Text("Aantal stappen op het bord om te winnen")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    ForEach([30, 35, 40], id: \.self) { pts in
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            doelScore = pts
                        }) {
                            Text("\(pts)")
                                .font(.subheadline)
                                .fontWeight(doelScore == pts ? .bold : .medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(doelScore == pts ? Color.orange : Color(UIColor.tertiarySystemGroupedBackground))
                                .foregroundColor(doelScore == pts ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
            }

            Divider()

            // Timer Lengte
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Timer Lengte")
                        .font(.headline)
                    Text("Tijd per team per beurt")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    ForEach([25, 30, 35], id: \.self) { sec in
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            timerDuur = sec
                        }) {
                            Text("\(sec)s")
                                .font(.subheadline)
                                .fontWeight(timerDuur == sec ? .bold : .medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(timerDuur == sec ? Color.orange : Color(UIColor.tertiarySystemGroupedBackground))
                                .foregroundColor(timerDuur == sec ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    // MARK: - Quick Chips

    private var quickChipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Opgeslagen Spelers")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Spacer()

                Button(action: {
                    newPlayerNameInput = ""
                    showNewPlayerAlert = true
                }) {
                    Label("Nieuwe Speler", systemImage: "plus.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            if scoreManager.savedPlayerNames.isEmpty {
                Text("Nog geen opgeslagen spelers. Typ direct een naam hieronder in het team.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(scoreManager.savedPlayerNames, id: \.self) { name in
                            playerQuickChip(name)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func playerQuickChip(_ name: String) -> some View {
        let playCount = scoreManager.playerPlayCount(for: name)

        return Menu {
            ForEach(0..<aantalTeams, id: \.self) { tIdx in
                Button("Zet in \(effectiveTeamName(for: tIdx))") {
                    assignPlayer(name, toTeam: tIdx)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "person.fill")
                    .font(.system(size: 9))
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)

                if playCount > 0 {
                    Text("\(playCount)x")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.12))
            .foregroundColor(.orange)
            .cornerRadius(16)
        }
    }

    private func assignPlayer(_ name: String, toTeam teamIndex: Int) {
        guard teamIndex < teams.count else { return }
        if teams[teamIndex].speler1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            teams[teamIndex].speler1 = name
        } else if teams[teamIndex].speler2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            teams[teamIndex].speler2 = name
        } else if teams[teamIndex].speler3.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showThirdPlayer[teamIndex] = true
            teams[teamIndex].speler3 = name
        }
    }

    // MARK: - Teams Kaartenlijst

    private var teamsListSection: some View {
        VStack(spacing: 14) {
            ForEach(0..<aantalTeams, id: \.self) { tIdx in
                teamCard(for: tIdx)
            }
        }
        .padding(.horizontal)
    }

    private func teamCard(for index: Int) -> some View {
        let team = teams[index]
        let isThirdVisible = showThirdPlayer[safe: index] ?? false

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(team.color)
                    .frame(width: 14, height: 14)

                TextField("Teamnaam (optioneel)", text: $teams[index].name)
                    .font(.headline)

                Spacer()

                Text("Team \(index + 1)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(team.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(team.color).opacity(0.15))
                    .cornerRadius(6)
            }

            Divider()

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Speler 1")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    PlayerNameInputField(
                        placeholder: "Naam Speler 1",
                        text: $teams[index].speler1,
                        suggestions: scoreManager.savedPlayerNames,
                        submitLabel: .next
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Speler 2")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    PlayerNameInputField(
                        placeholder: "Naam Speler 2",
                        text: $teams[index].speler2,
                        suggestions: scoreManager.savedPlayerNames,
                        submitLabel: isThirdVisible ? .next : .done
                    )
                }
            }

            if isThirdVisible {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Speler 3 (optioneel)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            withAnimation {
                                teams[index].speler3 = ""
                                showThirdPlayer[index] = false
                            }
                        }) {
                            Text("Verwijder")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }

                    PlayerNameInputField(
                        placeholder: "Naam Speler 3",
                        text: $teams[index].speler3,
                        suggestions: scoreManager.savedPlayerNames,
                        submitLabel: .done
                    )
                }
            } else {
                Button(action: {
                    withAnimation {
                        showThirdPlayer[index] = true
                    }
                }) {
                    Label("3e speler toevoegen", systemImage: "plus.circle")
                        .font(.caption)
                        .foregroundColor(team.color)
                }
                .padding(.top, 2)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
    }

    // MARK: - Start Knop

    private var startButton: some View {
        NavigationLink(destination: destinationGameView) {
            HStack(spacing: 8) {
                Image(systemName: invoerModus == .snel ? "bolt.fill" : "play.fill")
                Text(invoerModus == .snel ? "Eindscore Invullen" : "Start 30 Seconds")
                    .fontWeight(.bold)
            }
            .font(.title3)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(kanStarten ? Color.orange : Color.gray)
            .cornerRadius(14)
            .shadow(color: kanStarten ? Color.orange.opacity(0.35) : Color.clear, radius: 5, x: 0, y: 3)
        }
        .disabled(!kanStarten)
        .simultaneousGesture(TapGesture().onEnded {
            slaSpelersOp()
        })
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private func slaSpelersOp() {
        let allValid = actieveTeams.flatMap { $0.validPlayers }
        scoreManager.savePlayerNames(allValid)
    }

    @ViewBuilder
    private var destinationGameView: some View {
        let configuredTeams = actieveTeams.enumerated().map { idx, t in
            ThirtySecondsTeam(
                name: effectiveTeamName(for: idx),
                playerNames: t.validPlayers,
                color: t.color
            )
        }

        if invoerModus == .snel {
            SnelleEindscoreGameView(
                gameName: "30 Seconds",
                themeColor: .orange,
                teamEntries: configuredTeams.map {
                    WinnaarTeamEntry(
                        teamName: $0.name,
                        playerNames: $0.playerNames,
                        score: 0,
                        isWinner: false
                    )
                },
                isLowestScoreWins: false,
                scoreUnit: "punten",
                allowNegative: false,
                initialScore: 0
            )
        } else {
            ThirtySecondsGameView(
                teams: configuredTeams,
                doelScore: doelScore,
                timerDuur: timerDuur
            )
        }
    }
}

#Preview {
    NavigationStack {
        ThirtySecondsSetupView()
    }
}
