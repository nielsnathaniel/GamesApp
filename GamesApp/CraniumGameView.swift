import SwiftUI
import Combine

enum CraniumCategory: String, CaseIterable, Identifiable {
    case dataHead = "Data Head"
    case creativeCat = "Creative Cat"
    case wordWorm = "Word Worm"
    case starPerformer = "Star Performer"
    case clubCranium = "Club Cranium"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .dataHead: return "Trivia, weetjes & feiten"
        case .creativeCat: return "Tekenen, blind tekenen & kleien"
        case .wordWorm: return "Woorden, anagrammen & spelling"
        case .starPerformer: return "Uitbeelden, zingen & typetjes"
        case .clubCranium: return "Alle teams strijden tegelijk mee!"
        }
    }

    var icon: String {
        switch self {
        case .dataHead: return "brain"
        case .creativeCat: return "paintpalette.fill"
        case .wordWorm: return "textformat.abc"
        case .starPerformer: return "theatermasks.fill"
        case .clubCranium: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .dataHead: return .yellow
        case .creativeCat: return .blue
        case .wordWorm: return .red
        case .starPerformer: return .green
        case .clubCranium: return .purple
        }
    }
}

struct CraniumTeam: Identifiable {
    var id: UUID = UUID()
    let name: String
    let playerNames: [String]
    let color: Color
    var score: Int = 0
    var completedCategories: Set<String> = []
    var beurtenGespeeld: Int = 0

    func uitvoerder(voorBeurt beurt: Int) -> String {
        guard !playerNames.isEmpty else { return "" }
        let index = beurt % playerNames.count
        return playerNames[index]
    }

    func overigeSpelers(voorBeurt beurt: Int) -> [String] {
        guard playerNames.count > 1 else { return [] }
        let cur = uitvoerder(voorBeurt: beurt)
        return playerNames.filter { $0 != cur }
    }

    var heeftAlleCategorieen: Bool {
        let base = [
            CraniumCategory.dataHead.rawValue,
            CraniumCategory.creativeCat.rawValue,
            CraniumCategory.wordWorm.rawValue,
            CraniumCategory.starPerformer.rawValue
        ]
        return base.allSatisfy { completedCategories.contains($0) }
    }
}

struct CraniumRoundEntry: Identifiable {
    var id: UUID = UUID()
    let roundNumber: Int
    let teamName: String
    let performerName: String
    let category: String
    let isSuccess: Bool
    let isClubCranium: Bool
    let clubWinnerTeam: String?
    let totalAfter: Int
}

struct CraniumGameView: View {
    private let scoreManager = ScoreManager.shared

    let doelScore: Int
    let timerDuur: Int
    let vereisAlleCategorieen: Bool

    @State private var teams: [CraniumTeam]
    @State private var activeTeamIndex: Int = 0
    @State private var huidigeRonde: Int = 1

    // Beurt-invoer
    @State private var selectedCategory: CraniumCategory = .dataHead
    @State private var turnSuccess: Bool = true
    @State private var selectedClubWinnerIndex: Int = 0

    // Timer
    @State private var remainingSeconds: Int
    @State private var isTimerActive: Bool = false
    @State private var timerSubscription: AnyCancellable? = nil

    // Geschiedenis & Navigatie
    @State private var geschiedenis: [CraniumRoundEntry] = []
    @State private var showHistorySheet: Bool = false
    @State private var restoreTargetEntry: CraniumRoundEntry? = nil
    @State private var showRestoreDialog: Bool = false
    @State private var showWinnaarView: Bool = false
    @State private var winningTeam: CraniumTeam? = nil
    @State private var showAfrondenSheet: Bool = false

    init(teams: [CraniumTeam], doelScore: Int = 16, timerDuur: Int = 60, vereisAlleCategorieen: Bool = true) {
        self.doelScore = doelScore
        self.timerDuur = timerDuur
        self.vereisAlleCategorieen = vereisAlleCategorieen
        _teams = State(initialValue: teams)
        _remainingSeconds = State(initialValue: timerDuur)
    }

    private var activeTeam: CraniumTeam {
        guard activeTeamIndex < teams.count else {
            return teams.first ?? CraniumTeam(name: "Team", playerNames: [], color: .purple)
        }
        return teams[activeTeamIndex]
    }

    private var huidigeUitvoerder: String {
        activeTeam.uitvoerder(voorBeurt: activeTeam.beurtenGespeeld)
    }

    private var huidigeOverigen: [String] {
        activeTeam.overigeSpelers(voorBeurt: activeTeam.beurtenGespeeld)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                headerView

                // Stand & Categorie Badges per team
                teamsLeaderboardView

                // Actieve Beurt Card
                activeTurnCard

                // Voltooi beurt actieknop
                finishTurnButton
            }
            .padding(.vertical)
        }
        .navigationTitle("Cranium")
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
                let sortedTeams = teams.sorted {
                    if $0.id == winner.id { return true }
                    if $1.id == winner.id { return false }
                    return $0.score > $1.score
                }
                let teamEntries = sortedTeams.map { t in
                    WinnaarTeamEntry(
                        teamName: t.name,
                        playerNames: t.playerNames,
                        score: t.score,
                        isWinner: t.id == winner.id
                    )
                }
                WinnaarView(
                    gameName: "Cranium",
                    winningTeamName: winner.name,
                    teams: teamEntries,
                    isLowestScoreWins: false,
                    scoreProgression: craniumScoreProgression,
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
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("Ronde \(huidigeRonde)")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text(vereisAlleCategorieen ? "Finish bij \(doelScore) opdrachten & alle 4 categorieën!" : "Finish bij \(doelScore) punten!")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.top, 4)
    }

    // MARK: - Teams Scoreboard

    private var teamsLeaderboardView: some View {
        VStack(spacing: 12) {
            ForEach(teams.indices, id: \.self) { idx in
                let team = teams[idx]
                let isCurrent = idx == activeTeamIndex
                let progress = min(1.0, Double(team.score) / Double(max(1, doelScore)))

                VStack(spacing: 10) {
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

                    // 4 Categorie Planeet Badges
                    HStack(spacing: 8) {
                        ForEach([CraniumCategory.dataHead, .creativeCat, .wordWorm, .starPerformer]) { cat in
                            let hasCat = team.completedCategories.contains(cat.rawValue)
                            HStack(spacing: 3) {
                                Image(systemName: hasCat ? "checkmark.circle.fill" : cat.icon)
                                    .font(.system(size: 10))
                                Text(cat.rawValue)
                                    .font(.system(size: 9, weight: hasCat ? .bold : .medium))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(hasCat ? cat.color.opacity(0.25) : Color(UIColor.tertiarySystemGroupedBackground))
                            .foregroundColor(hasCat ? (cat == .dataHead ? .orange : cat.color) : .secondary.opacity(0.6))
                            .cornerRadius(6)
                        }
                    }

                    // Spelers info
                    HStack {
                        Text(team.playerNames.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Spacer()

                        let nextUitvoerder = team.uitvoerder(voorBeurt: team.beurtenGespeeld)
                        Text("Uitvoerder: \(nextUitvoerder)")
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

    // MARK: - Actieve Beurt Card

    private var activeTurnCard: some View {
        VStack(spacing: 16) {
            // Banner actieve team
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(activeTeam.color.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: "brain.head.profile")
                        .foregroundColor(activeTeam.color)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Beurt van: \(activeTeam.name)")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Text("🎭 \(huidigeUitvoerder) voert uit")
                            .fontWeight(.bold)
                            .foregroundColor(activeTeam.color)
                        if !huidigeOverigen.isEmpty {
                            Text("voor \(huidigeOverigen.joined(separator: " & "))")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.caption)
                }

                Spacer()
            }

            Divider()

            // 1. Categorie Kiezer
            VStack(alignment: .leading, spacing: 10) {
                Label("1. Kies Categorie van deze beurt", systemImage: "square.grid.2x2.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    ForEach([CraniumCategory.dataHead, .creativeCat, .wordWorm, .starPerformer]) { cat in
                        let isSelected = selectedCategory == cat
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedCategory = cat
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: cat.icon)
                                    .font(.subheadline)
                                    .foregroundColor(isSelected ? .white : cat.color)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(cat.rawValue)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(isSelected ? .white : .primary)
                                    Text(cat.subtitle)
                                        .font(.system(size: 8))
                                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(isSelected ? cat.color : Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                    }
                }

                // Club Cranium knop (volledige breedte)
                let isClub = selectedCategory == .clubCranium
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedCategory = .clubCranium
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(isClub ? .white : .purple)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Club Cranium (Iedereen doet mee!)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(isClub ? .white : .primary)
                            Text("Alle teams strijden tegelijk om een bonuspunt")
                                .font(.system(size: 9))
                                .foregroundColor(isClub ? .white.opacity(0.9) : .secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isClub ? Color.purple : Color.purple.opacity(0.12))
                    .cornerRadius(10)
                }
            }

            Divider()

            // 2. Cranium Timer (60s)
            VStack(spacing: 12) {
                HStack {
                    Label("2. Timer (\(timerDuur)s)", systemImage: "hourglass")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    if isTimerActive {
                        Text("AAN HET LOPEN")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.purple)
                    }
                }

                HStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 8)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: CGFloat(remainingSeconds) / CGFloat(max(1, timerDuur)))
                            .stroke(
                                remainingSeconds <= 5 ? Color.red : (remainingSeconds <= 15 ? Color.orange : Color.purple),
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
                                Text(isTimerActive ? "Pauzeer" : (remainingSeconds < timerDuur ? "Hervat" : "Start Zandloper"))
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isTimerActive ? Color.orange : Color.purple)
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

            // 3. Resultaat van de Opdracht
            VStack(alignment: .leading, spacing: 8) {
                Label("3. Uitslag van de opdracht", systemImage: "flag.checkered")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if selectedCategory == .clubCranium {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welk team heeft Club Cranium gewonnen?")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Picker("Winnaar Club Cranium", selection: $selectedClubWinnerIndex) {
                            ForEach(teams.indices, id: \.self) { tIdx in
                                Text("\(teams[tIdx].name) (+1 pt)").tag(tIdx)
                            }
                            Text("Niemand geraden (0 pt)").tag(-1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                } else {
                    HStack(spacing: 12) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            turnSuccess = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Gelukt! (+1)")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(turnSuccess ? Color.green : Color(UIColor.tertiarySystemGroupedBackground))
                            .foregroundColor(turnSuccess ? .white : .primary)
                            .cornerRadius(10)
                        }

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            turnSuccess = false
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Mislukt (0)")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(!turnSuccess ? Color.red : Color(UIColor.tertiarySystemGroupedBackground))
                            .foregroundColor(!turnSuccess ? .white : .primary)
                            .cornerRadius(10)
                        }
                    }
                }
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
                    Text(buttonActionTitle)
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

    private var buttonActionTitle: String {
        if selectedCategory == .clubCranium {
            if selectedClubWinnerIndex >= 0 && selectedClubWinnerIndex < teams.count {
                return "Voltooi (+1 voor \(teams[selectedClubWinnerIndex].name))"
            } else {
                return "Voltooi Club Cranium (0 pt)"
            }
        } else {
            return turnSuccess ? "Voltooi Beurt (+1 stap)" : "Voltooi Beurt (0 stap)"
        }
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
                        Text("Nog geen opdrachten voltooid.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.yellow)
                            Text("Houd een opdracht ingedrukt om de stand te herstellen.")
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

                                Text(entry.isSuccess ? "+1 pt" : "0 pt")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(entry.isSuccess ? .green : .secondary)
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.purple)
                                    .font(.caption)
                                (Text("Team: ").foregroundColor(.secondary) + Text(entry.teamName).fontWeight(.semibold))
                            }
                            .font(.subheadline)

                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Image(systemName: "theatermasks.fill")
                                        .foregroundColor(.secondary)
                                        .font(.caption2)
                                    Text("Uitvoerder: \(entry.performerName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                HStack(spacing: 4) {
                                    Text(entry.category)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.purple.opacity(0.15))
                                        .foregroundColor(.purple)
                                        .cornerRadius(4)
                                }

                                if entry.isClubCranium, let clubW = entry.clubWinnerTeam {
                                    Text("Gewonnen door: \(clubW)")
                                        .font(.caption)
                                        .foregroundColor(.orange)
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
                                Label("Herstel naar stand vóór deze opdracht", systemImage: "arrow.uturn.backward")
                            }
                            Button(action: {
                                herstelBeurt(entry, includeThisTurn: true)
                            }) {
                                Label("Zet stand terug naar na deze opdracht", systemImage: "arrow.uturn.forward")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cranium Beurtenlog")
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
                    Button("Herstel naar stand vóór deze opdracht (Wis opdracht)", role: .destructive) {
                        herstelBeurt(entry, includeThisTurn: false)
                    }
                    Button("Zet stand terug naar na deze opdracht") {
                        herstelBeurt(entry, includeThisTurn: true)
                    }
                    Button("Annuleren", role: .cancel) {}
                }
            } message: {
                if let entry = restoreTargetEntry {
                    Text("Wil je de opdracht van \(entry.teamName) in ronde \(entry.roundNumber) herstellen?")
                }
            }
        }
    }

    private func herstelBeurt(_ targetEntry: CraniumRoundEntry, includeThisTurn: Bool) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        guard let idx = geschiedenis.firstIndex(where: { $0.id == targetEntry.id }) else { return }

        let keptEntries = includeThisTurn ? Array(geschiedenis.prefix(idx + 1)) : Array(geschiedenis.prefix(idx))

        // Herbereken de teams exact op basis van de behouden beurten
        for tIdx in teams.indices {
            teams[tIdx].score = 0
            teams[tIdx].beurtenGespeeld = 0
            teams[tIdx].completedCategories = []
        }

        for e in keptEntries {
            if let tIdx = teams.firstIndex(where: { $0.name == e.teamName }) {
                teams[tIdx].beurtenGespeeld += 1
                if e.isSuccess {
                    teams[tIdx].score += 1
                    teams[tIdx].completedCategories.insert(e.category)
                }
            }
            if let clubWinner = e.clubWinnerTeam, let cIdx = teams.firstIndex(where: { $0.name == clubWinner }) {
                teams[cIdx].score += 1
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

    // MARK: - Timer Logica

    private func toggleTimer() {
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

    // MARK: - Beurt Verwerking

    private func voltooiBeurt() {
        stopTimer()

        var didWinPoint = false
        var clubWinnerName: String? = nil

        if selectedCategory == .clubCranium {
            if selectedClubWinnerIndex >= 0 && selectedClubWinnerIndex < teams.count {
                teams[selectedClubWinnerIndex].score += 1
                clubWinnerName = teams[selectedClubWinnerIndex].name
                didWinPoint = true
            }
        } else {
            if turnSuccess {
                teams[activeTeamIndex].score += 1
                teams[activeTeamIndex].completedCategories.insert(selectedCategory.rawValue)
                didWinPoint = true
            }
        }

        // Voeg toe aan geschiedenis
        let entry = CraniumRoundEntry(
            roundNumber: huidigeRonde,
            teamName: activeTeam.name,
            performerName: huidigeUitvoerder,
            category: selectedCategory.rawValue,
            isSuccess: didWinPoint,
            isClubCranium: selectedCategory == .clubCranium,
            clubWinnerTeam: clubWinnerName,
            totalAfter: activeTeam.score
        )
        geschiedenis.append(entry)

        teams[activeTeamIndex].beurtenGespeeld += 1

        // Controleer of het actieve team (of eventuele club winnaar) heeft gewonnen
        for t in teams {
            let reachedPoints = t.score >= doelScore
            let satisfiesCategories = !vereisAlleCategorieen || t.heeftAlleCategorieen
            if reachedPoints && satisfiesCategories {
                finalizeGame(withWinner: t)
                return
            }
        }

        // Ga naar volgende team
        let nextIndex = (activeTeamIndex + 1) % teams.count
        if nextIndex == 0 {
            huidigeRonde += 1
        }
        activeTeamIndex = nextIndex

        // Reset inputs voor volgende beurt
        turnSuccess = true
        selectedClubWinnerIndex = 0
        remainingSeconds = timerDuur
    }

    private func finalizeGame(withWinner winner: CraniumTeam) {
        winningTeam = winner
        showWinnaarView = true
    }

    private func resetGame() {
        for i in teams.indices {
            teams[i].score = 0
            teams[i].beurtenGespeeld = 0
            teams[i].completedCategories = []
        }
        huidigeRonde = 1
        activeTeamIndex = 0
        geschiedenis = []
        winningTeam = nil
        showWinnaarView = false
        resetTimer()
    }

    private var craniumScoreProgression: [RoundScoreDataPoint] {
        var points: [RoundScoreDataPoint] = []
        var runningScores: [String: Int] = [:]
        for t in teams {
            runningScores[t.name] = 0
            points.append(RoundScoreDataPoint(roundNumber: 0, roundLabel: "Start", playerName: t.name, score: 0))
        }

        for (idx, entry) in geschiedenis.enumerated() {
            runningScores[entry.teamName] = entry.totalAfter
            let step = idx + 1
            for t in teams {
                points.append(RoundScoreDataPoint(
                    roundNumber: step,
                    roundLabel: "Beurt \(step)",
                    playerName: t.name,
                    score: runningScores[t.name, default: 0]
                ))
            }
        }
        return points
    }
}

#Preview {
    NavigationStack {
        CraniumGameView(
            teams: [
                CraniumTeam(name: "De Breinen", playerNames: ["Niels", "Tom"], color: .purple, score: 6),
                CraniumTeam(name: "De Bollebozen", playerNames: ["Lisa", "Sam"], color: .indigo, score: 5)
            ],
            doelScore: 16,
            timerDuur: 60,
            vereisAlleCategorieen: true
        )
    }
}
