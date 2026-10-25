import SwiftUI
import Combine

struct ThirtySecondsTeam: Identifiable {
    var id: UUID = UUID()
    let name: String
    let playerNames: [String]
    let color: Color
    var score: Int = 0
    var beurtenGespeeld: Int = 0

    // Wie omschrijft in deze beurt van het team
    func omschrijver(voorBeurt beurt: Int) -> String {
        guard !playerNames.isEmpty else { return "" }
        let index = beurt % playerNames.count
        return playerNames[index]
    }

    // Wie raden in deze beurt van het team
    func raadSpelers(voorBeurt beurt: Int) -> [String] {
        guard playerNames.count > 1 else { return [] }
        let currentOmschrijver = omschrijver(voorBeurt: beurt)
        return playerNames.filter { $0 != currentOmschrijver }
    }
}

struct ThirtySecondsRoundEntry: Identifiable {
    var id: UUID = UUID()
    let roundNumber: Int
    let teamName: String
    let describerName: String
    let diceRoll: Int
    let correctCount: Int
    let pointsGained: Int
    let totalAfter: Int
}

struct ThirtySecondsGameView: View {
    private let scoreManager = ScoreManager.shared

    let doelScore: Int
    let timerDuur: Int

    @State private var teams: [ThirtySecondsTeam]
    @State private var activeTeamIndex: Int = 0
    @State private var huidigeRonde: Int = 1

    // Beurt-invoer
    @State private var diceRoll: Int = 0
    @State private var hasRolledDice: Bool = false
    @State private var selectedCorrect: Int = 0

    // Timer
    @State private var remainingSeconds: Int
    @State private var isTimerActive: Bool = false
    @State private var timerSubscription: AnyCancellable? = nil

    // Geschiedenis & Navigatie
    @State private var geschiedenis: [ThirtySecondsRoundEntry] = []
    @State private var showHistorySheet: Bool = false
    @State private var restoreTargetEntry: ThirtySecondsRoundEntry? = nil
    @State private var showRestoreDialog: Bool = false
    @State private var showWinnaarView: Bool = false
    @State private var winningTeam: ThirtySecondsTeam? = nil

    // Bevestiging voor handmatig spel afronden
    @State private var showAfrondenSheet: Bool = false

    init(teams: [ThirtySecondsTeam], doelScore: Int = 35, timerDuur: Int = 30) {
        self.doelScore = doelScore
        self.timerDuur = timerDuur
        _teams = State(initialValue: teams)
        _remainingSeconds = State(initialValue: timerDuur)
    }

    private var activeTeam: ThirtySecondsTeam {
        guard activeTeamIndex < teams.count else {
            return teams.first ?? ThirtySecondsTeam(name: "Team", playerNames: [], color: .orange)
        }
        return teams[activeTeamIndex]
    }

    private var huidigeOmschrijver: String {
        activeTeam.omschrijver(voorBeurt: activeTeam.beurtenGespeeld)
    }

    private var huidigeRaadSpelers: [String] {
        activeTeam.raadSpelers(voorBeurt: activeTeam.beurtenGespeeld)
    }

    private var berekendeStappen: Int {
        max(0, selectedCorrect - diceRoll)
    }

    private var leaderTeam: ThirtySecondsTeam? {
        let maxScore = teams.map { $0.score }.max() ?? 0
        guard maxScore > 0 else { return nil }
        return teams.first { $0.score == maxScore }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                headerView

                // Stand & Voortgang per team
                teamsLeaderboardView

                // Actieve Beurt Card (Omschrijver, Dobbelsteen, Timer & Score)
                activeTurnCard

                // Voltooi beurt actieknop
                finishTurnButton
            }
            .padding(.vertical)
        }
        .navigationTitle("30 Seconds")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showHistorySheet = true }) {
                    Label("Logboek", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .sheet(isPresented: $showHistorySheet) {
            historySheetView
        }
        .navigationDestination(isPresented: $showWinnaarView) {
            if let winner = winningTeam {
                let sortedTeams = teams.sorted { $0.score > $1.score }
                let teamEntries = sortedTeams.map { t in
                    WinnaarTeamEntry(
                        teamName: t.name,
                        playerNames: t.playerNames,
                        score: t.score,
                        isWinner: t.id == winner.id
                    )
                }
                WinnaarView(
                    gameName: "30 Seconds",
                    winningTeamName: winner.name,
                    teams: teamEntries,
                    isLowestScoreWins: false,
                    onReset: {
                        resetGame()
                    }
                )
            }
        }
        .confirmationDialog("Spel Voortijdig Afronden?", isPresented: $showAfrondenSheet, titleVisibility: .visible) {
            ForEach(teams) { team in
                Button("Kies \(team.name) als winnaar") {
                    finalizeGame(withWinner: team)
                }
            }
            Button("Annuleren", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("Ronde \(huidigeRonde)")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text("Doel: eerste team bij \(doelScore) punten wint!")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.top, 4)
    }

    // MARK: - Teams Scoreboard

    private var teamsLeaderboardView: some View {
        VStack(spacing: 10) {
            ForEach(teams.indices, id: \.self) { idx in
                let team = teams[idx]
                let isCurrent = idx == activeTeamIndex
                let progress = min(1.0, Double(team.score) / Double(max(1, doelScore)))

                VStack(spacing: 8) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(team.color)
                                .frame(width: 12, height: 12)

                            Text(team.name)
                                .font(.headline)
                                .fontWeight(isCurrent ? .bold : .semibold)
                        }

                        if isCurrent {
                            Text("Aan de beurt")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(team.color)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }

                        Spacer()

                        Text("\(team.score) / \(doelScore) pt")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(isCurrent ? team.color : .primary)
                    }

                    // Voortgangsbalk
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(UIColor.tertiarySystemGroupedBackground))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(team.color)
                                .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 8)
                                .animation(.spring(response: 0.4), value: team.score)
                        }
                    }
                    .frame(height: 8)

                    // Spelers en rol
                    HStack {
                        Text(team.playerNames.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Spacer()

                        let nextOmschrijver = team.omschrijver(voorBeurt: team.beurtenGespeeld)
                        Text("Omschrijver: \(nextOmschrijver)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? team.color : Color.clear, lineWidth: 2)
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Actieve Beurt Kaart

    private var activeTurnCard: some View {
        VStack(spacing: 16) {
            // Banner actieve team
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(activeTeam.color.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.2.fill")
                        .foregroundColor(activeTeam.color)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Beurt van: \(activeTeam.name)")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Text("🗣️ \(huidigeOmschrijver) omschrijft")
                            .fontWeight(.bold)
                            .foregroundColor(activeTeam.color)
                        if !huidigeRaadSpelers.isEmpty {
                            Text("aan \(huidigeRaadSpelers.joined(separator: " & "))")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.caption)
                }

                Spacer()
            }

            Divider()

            // 1. Dobbelsteen Worp (0, 1 of 2)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("1. Dobbelsteen (0, 1 of 2)", systemImage: "die.face.2.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Button(action: rolDobbelsteen) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Rol dobbelsteen")
                        }
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                }

                HStack(spacing: 12) {
                    ForEach([0, 1, 2], id: \.self) { val in
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            diceRoll = val
                            hasRolledDice = true
                        }) {
                            VStack(spacing: 2) {
                                Text("\(val)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(val == 0 ? "Geen straf" : "-\(val) straf")
                                    .font(.system(size: 10))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(diceRoll == val && hasRolledDice ? Color.orange : Color(UIColor.tertiarySystemGroupedBackground))
                            .foregroundColor(diceRoll == val && hasRolledDice ? .white : .primary)
                            .cornerRadius(10)
                        }
                    }
                }
            }

            Divider()

            // 2. Interactieve Timer (30s)
            VStack(spacing: 12) {
                HStack {
                    Label("2. Timer (\(timerDuur)s)", systemImage: "stopwatch.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    if isTimerActive {
                        Text("AAN HET AFTELEN")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.red)
                    }
                }

                // Grote timer klok
                HStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 8)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: CGFloat(remainingSeconds) / CGFloat(max(1, timerDuur)))
                            .stroke(
                                remainingSeconds <= 5 ? Color.red : (remainingSeconds <= 10 ? Color.orange : Color.green),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: remainingSeconds)

                        Text("\(remainingSeconds)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(remainingSeconds <= 5 ? .red : .primary)
                    }

                    VStack(spacing: 8) {
                        Button(action: toggleTimer) {
                            HStack {
                                Image(systemName: isTimerActive ? "pause.fill" : "play.fill")
                                Text(isTimerActive ? "Pauzeer" : (remainingSeconds < timerDuur ? "Hervat" : "Start Timer"))
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isTimerActive ? Color.orange : Color.green)
                            .cornerRadius(10)
                        }

                        Button(action: resetTimer) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Herstart (\(timerDuur)s)")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Divider()

            // 3. Aantal geraden begrippen (0 t/m 5)
            VStack(alignment: .leading, spacing: 8) {
                Label("3. Hoeveel namen zijn goed geraden?", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    ForEach(0...5, id: \.self) { num in
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedCorrect = num
                        }) {
                            Text("\(num)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedCorrect == num ? activeTeam.color : Color(UIColor.tertiarySystemGroupedBackground))
                                .foregroundColor(selectedCorrect == num ? .white : .primary)
                                .cornerRadius(10)
                        }
                    }
                }

                // Berekening preview
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(activeTeam.color)

                    Text("\(selectedCorrect) goed - \(diceRoll) dobbelsteen = ")
                        .foregroundColor(.secondary)
                    Text("+\(berekendeStappen) \(berekendeStappen == 1 ? "stap" : "stappen")")
                        .fontWeight(.bold)
                        .foregroundColor(berekendeStappen > 0 ? activeTeam.color : .secondary)
                }
                .font(.footnote)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Voltooi Beurt Knop

    private var finishTurnButton: some View {
        VStack(spacing: 10) {
            Button(action: voltooiBeurt) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Voltooi Beurt (+\(berekendeStappen) pt)")
                        .fontWeight(.bold)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(activeTeam.color)
                .cornerRadius(14)
                .shadow(color: activeTeam.color.opacity(0.35), radius: 5, x: 0, y: 3)
            }

            Button(action: { showAfrondenSheet = true }) {
                Text("Spel vroegtijdig afronden")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // MARK: - Logboek Sheet

    private var historySheetView: some View {
        NavigationStack {
            List {
                if geschiedenis.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Nog geen beurten voltooid.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.yellow)
                            Text("Houd een beurt ingedrukt om de puntenstand te herstellen.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    ForEach(geschiedenis.reversed()) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Ronde \(entry.roundNumber)")
                                    .font(.headline)

                                Spacer()

                                Button(action: {
                                    restoreTargetEntry = entry
                                    showRestoreDialog = true
                                }) {
                                    Label("Herstel", systemImage: "arrow.uturn.backward.circle")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }

                                Text("+\(entry.pointsGained) pt")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(entry.pointsGained > 0 ? .green : .secondary)
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                (Text("Team: ").foregroundColor(.secondary) + Text(entry.teamName).fontWeight(.semibold))
                            }
                            .font(.subheadline)

                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Image(systemName: "quote.bubble.fill")
                                        .foregroundColor(.secondary)
                                        .font(.caption2)
                                    Text("Omschrijver: \(entry.describerName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                HStack(spacing: 4) {
                                    Image(systemName: "die.face.2.fill")
                                        .foregroundColor(.secondary)
                                        .font(.caption2)
                                    Text("Worp: \(entry.diceRoll)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.secondary)
                                        .font(.caption2)
                                    Text("\(entry.correctCount) goed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text("Totaalstand na beurt: \(entry.totalAfter) pt")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onLongPressGesture {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            restoreTargetEntry = entry
                            showRestoreDialog = true
                        }
                        .contextMenu {
                            Button(role: .destructive, action: {
                                herstelBeurt(entry, includeThisTurn: false)
                            }) {
                                Label("Herstel naar stand vóór deze beurt", systemImage: "arrow.uturn.backward")
                            }
                            Button(action: {
                                herstelBeurt(entry, includeThisTurn: true)
                            }) {
                                Label("Zet stand terug naar na deze beurt", systemImage: "arrow.uturn.forward")
                            }
                        }
                    }
                }
            }
            .navigationTitle("30 Seconds Beurtenlog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sluit") { showHistorySheet = false }
                }
            }
            .confirmationDialog(
                "Herstel stand naar Ronde \(restoreTargetEntry?.roundNumber ?? 1)?",
                isPresented: $showRestoreDialog,
                titleVisibility: .visible
            ) {
                if let entry = restoreTargetEntry {
                    Button("Herstel naar stand vóór deze beurt (Wis beurt)", role: .destructive) {
                        herstelBeurt(entry, includeThisTurn: false)
                    }
                    Button("Zet stand terug naar na deze beurt") {
                        herstelBeurt(entry, includeThisTurn: true)
                    }
                    Button("Annuleren", role: .cancel) {}
                }
            } message: {
                if let entry = restoreTargetEntry {
                    Text("Wil je de beurt van \(entry.teamName) in ronde \(entry.roundNumber) herstellen?")
                }
            }
        }
    }

    private func herstelBeurt(_ targetEntry: ThirtySecondsRoundEntry, includeThisTurn: Bool) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        guard let idx = geschiedenis.firstIndex(where: { $0.id == targetEntry.id }) else { return }

        let keptEntries = includeThisTurn ? Array(geschiedenis.prefix(idx + 1)) : Array(geschiedenis.prefix(idx))

        // Herbereken alle teamscores exact op basis van behouden beurten
        for tIdx in teams.indices {
            teams[tIdx].score = 0
            teams[tIdx].beurtenGespeeld = 0
        }

        for e in keptEntries {
            if let tIdx = teams.firstIndex(where: { $0.name == e.teamName }) {
                teams[tIdx].score += e.pointsGained
                teams[tIdx].beurtenGespeeld += 1
            }
        }

        geschiedenis = keptEntries

        if let last = keptEntries.last {
            huidigeRonde = last.roundNumber
            if let lastTeamIdx = teams.firstIndex(where: { $0.name == last.teamName }) {
                let nextIdx = (lastTeamIdx + 1) % teams.count
                if nextIdx == 0 {
                    huidigeRonde += 1
                }
                activeTeamIndex = nextIdx
            }
        } else {
            huidigeRonde = 1
            activeTeamIndex = 0
        }

        showHistorySheet = false
    }

    // MARK: - Spel Logica

    private func rolDobbelsteen() {
        HapticManager.shared.medium()
        // 30 Seconds dobbelsteen heeft vlakken: 0, 1, 2
        diceRoll = Int.random(in: 0...2)
        hasRolledDice = true
    }

    private func toggleTimer() {
        HapticManager.shared.light()
        if isTimerActive {
            stopTimer()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        if remainingSeconds == 0 {
            remainingSeconds = timerDuur
        }
        isTimerActive = true
        timerSubscription?.cancel()
        timerSubscription = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                    if remainingSeconds <= 3 && remainingSeconds > 0 {
                        HapticManager.shared.warning()
                    }
                } else {
                    stopTimer()
                    HapticManager.shared.error()
                }
            }
    }

    private func stopTimer() {
        isTimerActive = false
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    private func resetTimer() {
        stopTimer()
        remainingSeconds = timerDuur
    }

    private func voltooiBeurt() {
        stopTimer()

        let stappen = berekendeStappen
        teams[activeTeamIndex].score += stappen
        let updatedScore = teams[activeTeamIndex].score

        // Sla beurt op in logboek
        let entry = ThirtySecondsRoundEntry(
            roundNumber: huidigeRonde,
            teamName: activeTeam.name,
            describerName: huidigeOmschrijver,
            diceRoll: diceRoll,
            correctCount: selectedCorrect,
            pointsGained: stappen,
            totalAfter: updatedScore
        )
        geschiedenis.append(entry)

        // Roteer de beurtenteller voor dit team zodat de omschrijver de volgende beurt wisselt
        teams[activeTeamIndex].beurtenGespeeld += 1

        // Controleer of het team de finish heeft bereikt
        if updatedScore >= doelScore {
            finalizeGame(withWinner: teams[activeTeamIndex])
            return
        }

        // Ga naar het volgende team
        let nextIndex = (activeTeamIndex + 1) % teams.count
        if nextIndex == 0 {
            huidigeRonde += 1
        }
        activeTeamIndex = nextIndex

        // Reset beurt-invoer
        diceRoll = 0
        hasRolledDice = false
        selectedCorrect = 0
        remainingSeconds = timerDuur
    }

    private func finalizeGame(withWinner winner: ThirtySecondsTeam) {
        winningTeam = winner
        let sortedTeams = teams.sorted { $0.score > $1.score }
        let teamData = sortedTeams.map { (teamName: $0.name, playerNames: $0.playerNames, score: $0.score, isWinner: $0.id == winner.id) }
        scoreManager.saveTeamGame(gameName: "30 Seconds", teams: teamData)
        showWinnaarView = true
    }

    private func resetGame() {
        for i in teams.indices {
            teams[i].score = 0
            teams[i].beurtenGespeeld = 0
        }
        huidigeRonde = 1
        activeTeamIndex = 0
        geschiedenis = []
        winningTeam = nil
        showWinnaarView = false
        resetTimer()
    }
}

#Preview {
    NavigationStack {
        ThirtySecondsGameView(
            teams: [
                ThirtySecondsTeam(name: "Team Oranje", playerNames: ["Niels", "Tom"], color: .orange, score: 12),
                ThirtySecondsTeam(name: "Team Blauw", playerNames: ["Lisa", "Sam"], color: .blue, score: 9)
            ],
            doelScore: 35,
            timerDuur: 30
        )
    }
}
