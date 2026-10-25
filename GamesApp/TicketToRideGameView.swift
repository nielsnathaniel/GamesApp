import SwiftUI

struct TTRPlayerScore {
    var routePoints: Int = 0
    var completedTickets: Int = 0
    var failedTickets: Int = 0
    var hasLongestRoute: Bool = false
    var hasGlobetrotter: Bool = false
    var unusedStations: Int = 0 // 0..3 (4 pt elk in Europa)
    var directScore: Int = 0

    func calculatedTotal() -> Int {
        let longest = hasLongestRoute ? 10 : 0
        let globe = hasGlobetrotter ? 10 : 0
        let stations = unusedStations * 4
        return routePoints + completedTickets - failedTickets + longest + globe + stations
    }
}

struct TTRTurnEntry: Identifiable, Equatable {
    let id: UUID
    let round: Int
    let playerIndex: Int
    let points: Int
    let description: String

    init(id: UUID = UUID(), round: Int, playerIndex: Int, points: Int, description: String) {
        self.id = id
        self.round = round
        self.playerIndex = playerIndex
        self.points = points
        self.description = description
    }
}

struct TicketToRideGameView: View {
    let spelers: [String]
    let initialMode: TicketToRideSetupView.TTRScoreMode
    let playerColors: [TTRColor]

    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var currentMode: TicketToRideSetupView.TTRScoreMode
    @State private var playerScores: [TTRPlayerScore]
    @State private var selectedPlayerIndex: Int = 0
    @State private var showWinnaarView: Bool = false
    @State private var winnaarPlayer: Player = Player(name: "")

    // Live ronde-per-ronde tracking
    @State private var currentRound: Int = 1
    @State private var turnIndexInRound: Int = 0
    @State private var turnHistory: [TTRTurnEntry] = []
    @State private var showCustomPointsAlert: Bool = false
    @State private var customPointsInput: String = ""
    @State private var showRondesSheet: Bool = false
    @State private var restoreTargetTurn: TTRTurnEntry? = nil
    @State private var showRestoreDialog: Bool = false

    init(
        spelers: [String],
        initialMode: TicketToRideSetupView.TTRScoreMode = .categorieen,
        playerColors: [TTRColor]? = nil
    ) {
        self.spelers = spelers
        self.initialMode = initialMode
        _currentMode = State(initialValue: initialMode)
        _playerScores = State(initialValue: Array(repeating: TTRPlayerScore(), count: spelers.count))

        let defaults: [TTRColor] = [.rood, .blauw, .groen, .geel, .zwart, .paars]
        self.playerColors = playerColors ?? Array(defaults.prefix(spelers.count))
    }

    private var activePlayerColor: TTRColor {
        playerColors[safe: selectedPlayerIndex] ?? .blauw
    }

    private var activeColor: Color {
        activePlayerColor.color
    }

    private var activeLightBg: Color {
        activePlayerColor.lightBgColor
    }

    private var activePlayerName: String {
        spelers[safe: selectedPlayerIndex] ?? ""
    }

    private func effectiveScore(for index: Int) -> Int {
        guard let p = playerScores[safe: index] else { return 0 }
        return currentMode == .direct ? p.directScore : p.calculatedTotal()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header met spelicoon
                headerView

                // Modus Wisselaar (3 opties)
                modeSwitchBar

                switch currentMode {
                case .categorieen:
                    categoriesView
                case .liveRondes:
                    liveRondesView
                case .direct:
                    directModeView
                }

                Spacer(minLength: 20)

                // Afronden knop
                finishButton
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text("Ticket to Ride")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    if currentMode == .categorieen || currentMode == .liveRondes {
                        if !activePlayerName.isEmpty {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(activeColor)
                                    .frame(width: 7, height: 7)
                                Text(activePlayerName)
                                    .font(.caption2)
                                    .fontWeight(.heavy)
                                    .foregroundColor(activeColor)
                                Text("• \(effectiveScore(for: selectedPlayerIndex)) pt")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showRondesSheet = true
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
        }
        .sheet(isPresented: $showRondesSheet) {
            allRoundsSheetView
        }
        .confirmationDialog(
            "Herstel beurt?",
            isPresented: $showRestoreDialog,
            titleVisibility: .visible
        ) {
            if let target = restoreTargetTurn {
                Button("Herstel vóór beurt van \(spelers[safe: target.playerIndex] ?? "") (Wis deze beurt)", role: .destructive) {
                    herstelNaarTurn(target, includeThisTurn: false)
                }
                Button("Herstel t/m beurt van \(spelers[safe: target.playerIndex] ?? "")") {
                    herstelNaarTurn(target, includeThisTurn: true)
                }
                Button("Annuleren", role: .cancel) {}
            }
        } message: {
            if let target = restoreTargetTurn {
                Text("Wil je de routepunten en stand terugzetten naar beurt in Ronde \(target.round)?")
            }
        }
        .navigationDestination(isPresented: $showWinnaarView) {
            WinnaarView(
                gameName: "Ticket to Ride",
                winnaar: winnaarPlayer,
                sortedSpelers: sortedPlayers,
                sortedScores: sortedScores,
                isLowestScoreWins: false,
                onReset: {
                    resetGame()
                }
            )
        }
        .alert("Aangepaste Routepunten", isPresented: $showCustomPointsAlert) {
            TextField("Punten (bijv. 9)", text: $customPointsInput)
                .keyboardType(.numberPad)
            Button("Toevoegen") {
                if let pts = Int(customPointsInput), pts >= 0 {
                    confirmLiveTurn(points: pts, description: "Aangepaste route (+\(pts) pt)")
                }
                customPointsInput = ""
            }
            Button("Annuleer", role: .cancel) {
                customPointsInput = ""
            }
        } message: {
            Text("Voer het aantal punten in voor de gelegde route van \(activePlayerName).")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            if UIImage(named: "TicketToRide") != nil {
                Image("TicketToRide")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: activeColor.opacity(0.3), radius: 3, x: 0, y: 1)
            } else {
                Image(systemName: "tram.fill")
                    .foregroundColor(activeColor)
                    .font(.system(size: 32))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Ticket to Ride")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(modeSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private var modeSubtitle: String {
        switch currentMode {
        case .categorieen:
            return "Eindtelling: routes, tickets & bonussen"
        case .liveRondes:
            return "Live bordspel: ronde per ronde invoeren"
        case .direct:
            return "Directe totaalscores invoeren"
        }
    }

    // MARK: - Modus Wisselaar

    private var modeSwitchBar: some View {
        Picker("Telmodus", selection: $currentMode) {
            ForEach(TicketToRideSetupView.TTRScoreMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    // MARK: - Categorieën Weergave (Eindtelling)

    private var categoriesView: some View {
        VStack(spacing: 16) {
            // Speler Selector Tabs met treinkleuren
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(spelers.indices, id: \.self) { idx in
                        let isSelected = selectedPlayerIndex == idx
                        let pColor = playerColors[safe: idx] ?? .blauw
                        let total = effectiveScore(for: idx)

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedPlayerIndex = idx
                            }
                        }) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(isSelected ? pColor.onColorTextColor : pColor.color)
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(spelers[idx])
                                        .font(.subheadline)
                                        .fontWeight(isSelected ? .bold : .medium)

                                    Text("\(total) pt")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(isSelected ? pColor.onColorTextColor.opacity(0.9) : pColor.color)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? pColor.color : pColor.lightBgColor)
                            .foregroundColor(isSelected ? pColor.onColorTextColor : .primary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(pColor.color.opacity(isSelected ? 0 : 0.4), lineWidth: 1.5)
                            )
                            .shadow(color: isSelected ? pColor.color.opacity(0.35) : Color.clear, radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            // Geselecteerde Speler Formulier
            if let activePlayer = spelers[safe: selectedPlayerIndex] {
                VStack(spacing: 14) {
                    // Header kaart van actieve speler in zijn/haar treinkleur
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(activeColor.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: "tram.fill")
                                .font(.title3)
                                .foregroundColor(activeColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Punten invoeren voor:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            Text(activePlayer)
                                .font(.title2)
                                .fontWeight(.black)
                                .foregroundColor(activeColor)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(playerScores[selectedPlayerIndex].calculatedTotal()) pt")
                                .font(.title)
                                .fontWeight(.heavy)
                                .foregroundColor(activeColor)
                            Text("Totaalscore")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(activeLightBg)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(activeColor.opacity(0.4), lineWidth: 1.5)
                    )
                    .padding(.horizontal)

                    // 1. Routepunten (Treintrajecten)
                    routePointsSection

                    // 2. Bestemmingskaarten (Tickets)
                    ticketsSection

                    // 3. Bonussen & Stations
                    bonusesSection
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Routepunten Sectie

    private var routePointsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("1. Routepunten (Treintrajecten)", systemImage: "tram.fill")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(activeColor)

                Spacer()

                Text("\(playerScores[selectedPlayerIndex].routePoints) pt")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(activeColor)
            }

            // Snelle presets gebaseerd op officiële treinlengtes:
            // 1 wagon = 1pt, 2 = 2pt, 3 = 4pt, 4 = 7pt, 5 = 10pt, 6 = 15pt, 8 = 21pt
            Text("Voeg route toe op basis van treinlengte:")
                .font(.caption2)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    trainPresetButton(length: 1, points: 1)
                    trainPresetButton(length: 2, points: 2)
                    trainPresetButton(length: 3, points: 4)
                    trainPresetButton(length: 4, points: 7)
                    trainPresetButton(length: 5, points: 10)
                    trainPresetButton(length: 6, points: 15)
                    trainPresetButton(length: 8, points: 21)
                }
            }

            // Handmatige correctie steppers
            HStack {
                Text("Handmatig aanpassen:")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 6) {
                    Button(action: {
                        if playerScores[selectedPlayerIndex].routePoints >= 5 {
                            playerScores[selectedPlayerIndex].routePoints -= 5
                        }
                    }) {
                        Text("-5")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(activeLightBg)
                            .foregroundColor(activeColor)
                            .cornerRadius(6)
                    }

                    Button(action: {
                        if playerScores[selectedPlayerIndex].routePoints > 0 {
                            playerScores[selectedPlayerIndex].routePoints -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }

                    NumericScoreInputView(
                        score: $playerScores[selectedPlayerIndex].routePoints,
                        allowNegative: false,
                        range: 0...400,
                        tintColor: activeColor,
                        minWidth: 44,
                        height: 28,
                        font: .subheadline
                    )

                    Button(action: {
                        playerScores[selectedPlayerIndex].routePoints += 1
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(activeColor)
                    }

                    Button(action: {
                        playerScores[selectedPlayerIndex].routePoints += 5
                    }) {
                        Text("+5")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(activeLightBg)
                            .foregroundColor(activeColor)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(activeColor.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func trainPresetButton(length: Int, points: Int) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation {
                playerScores[selectedPlayerIndex].routePoints += points
            }
        }) {
            VStack(spacing: 2) {
                Text("\(length) 🚃")
                    .font(.caption2)
                    .fontWeight(.bold)
                Text("+\(points)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(activeColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(activeLightBg)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(activeColor.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bestemmingskaarten Sectie

    private var ticketsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("2. Bestemmingskaarten (Tickets)", systemImage: "ticket.fill")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(activeColor)

            // Voltooide tickets
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Voltooide tickets (Pluspunten)")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Totale punten van behaalde routes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: {
                        if playerScores[selectedPlayerIndex].completedTickets >= 5 {
                            playerScores[selectedPlayerIndex].completedTickets -= 5
                        }
                    }) {
                        Text("-5")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(activeLightBg)
                            .foregroundColor(activeColor)
                            .cornerRadius(6)
                    }

                    Button(action: {
                        if playerScores[selectedPlayerIndex].completedTickets > 0 {
                            playerScores[selectedPlayerIndex].completedTickets -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill").foregroundColor(.secondary)
                    }

                    NumericScoreInputView(
                        score: $playerScores[selectedPlayerIndex].completedTickets,
                        allowNegative: false,
                        range: 0...400,
                        tintColor: activeColor,
                        minWidth: 44,
                        height: 28,
                        font: .subheadline
                    )

                    Button(action: {
                        playerScores[selectedPlayerIndex].completedTickets += 1
                    }) {
                        Image(systemName: "plus.circle.fill").foregroundColor(activeColor)
                    }

                    Button(action: {
                        playerScores[selectedPlayerIndex].completedTickets += 5
                    }) {
                        Text("+5")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(activeLightBg)
                            .foregroundColor(activeColor)
                            .cornerRadius(6)
                    }
                }
            }

            Divider()

            // Niet-voltooide tickets (Strafpunten)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mislukte tickets (Aftrek)")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Minpunten voor niet-behaalde routes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: {
                        if playerScores[selectedPlayerIndex].failedTickets >= 5 {
                            playerScores[selectedPlayerIndex].failedTickets -= 5
                        }
                    }) {
                        Text("-5")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                    }

                    Button(action: {
                        if playerScores[selectedPlayerIndex].failedTickets > 0 {
                            playerScores[selectedPlayerIndex].failedTickets -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill").foregroundColor(.red)
                    }

                    NumericScoreInputView(
                        score: $playerScores[selectedPlayerIndex].failedTickets,
                        allowNegative: false,
                        range: 0...400,
                        tintColor: .red,
                        minWidth: 44,
                        height: 28,
                        font: .subheadline
                    )

                    Button(action: {
                        playerScores[selectedPlayerIndex].failedTickets += 1
                    }) {
                        Image(systemName: "plus.circle.fill").foregroundColor(.red)
                    }

                    Button(action: {
                        playerScores[selectedPlayerIndex].failedTickets += 5
                    }) {
                        Text("+5")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(activeColor.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Bonussen & Stations

    private var bonusesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("3. Bonussen & Stations", systemImage: "star.fill")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(activeColor)

            // Langste Route (+10 pt)
            Toggle(isOn: $playerScores[selectedPlayerIndex].hasLongestRoute) {
                HStack(spacing: 8) {
                    Image(systemName: "road.lanes")
                        .foregroundColor(activeColor)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Langste aaneengesloten route")
                            .font(.body)
                        Text("+10 punten bonus")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(activeColor)

            Divider()

            // Globetrotter (+10 pt)
            Toggle(isOn: $playerScores[selectedPlayerIndex].hasGlobetrotter) {
                HStack(spacing: 8) {
                    Image(systemName: "globe.europe.africa.fill")
                        .foregroundColor(activeColor)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Globetrotter (meeste tickets)")
                            .font(.body)
                        Text("+10 punten bonus (Europa/uitbreiding)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(activeColor)

            Divider()

            // Ongebruikte Stations (4 pt per station, max 3)
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(activeColor)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Overgebleven stations")
                            .font(.body)
                        Text("4 punten per ongebruikt station (max 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: {
                        if playerScores[selectedPlayerIndex].unusedStations > 0 {
                            playerScores[selectedPlayerIndex].unusedStations -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill").foregroundColor(.secondary)
                    }
                    .disabled(playerScores[selectedPlayerIndex].unusedStations <= 0)

                    Text("\(playerScores[selectedPlayerIndex].unusedStations)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(minWidth: 20)

                    Button(action: {
                        if playerScores[selectedPlayerIndex].unusedStations < 3 {
                            playerScores[selectedPlayerIndex].unusedStations += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill").foregroundColor(activeColor)
                    }
                    .disabled(playerScores[selectedPlayerIndex].unusedStations >= 3)

                    Text("(+\(playerScores[selectedPlayerIndex].unusedStations * 4) pt)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(activeColor)
                        .frame(minWidth: 44)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(activeColor.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - 3. Live Ronde-per-Ronde Weergave

    private var roundTurns: [TTRTurnEntry] {
        turnHistory.filter { $0.round == currentRound }
    }

    private var liveRondesView: some View {
        VStack(spacing: 16) {
            // Ronde & Beurt voortgangsbalk
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flag.checkered")
                        .font(.caption)
                        .foregroundColor(activeColor)
                    Text("Ronde \(currentRound)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(activeLightBg)
                .cornerRadius(20)

                Spacer()

                Text("Beurt \(turnIndexInRound + 1) van \(spelers.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // Spelers Voortgang Dots in huidige ronde
            HStack(spacing: 6) {
                ForEach(spelers.indices, id: \.self) { idx in
                    let isDone = idx < turnIndexInRound
                    let isCurrent = idx == turnIndexInRound
                    let pColor = playerColors[safe: idx] ?? .blauw

                    Button(action: {
                        withAnimation {
                            turnIndexInRound = idx
                            selectedPlayerIndex = idx
                        }
                    }) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isCurrent ? pColor.color : (isDone ? pColor.color.opacity(0.6) : Color.gray.opacity(0.3)))
                                .frame(width: isCurrent ? 12 : 9, height: isCurrent ? 12 : 9)
                            Text(spelers[idx])
                                .font(.caption2)
                                .fontWeight(isCurrent ? .bold : .regular)
                                .foregroundColor(isCurrent ? pColor.color : (isDone ? .primary : .secondary))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isCurrent ? pColor.lightBgColor : Color.clear)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isCurrent ? pColor.color.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            // Actieve Speler Beurt Kaart in diens treinkleur
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(activeColor.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: "tram.fill")
                            .font(.title2)
                            .foregroundColor(activeColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Aan de beurt:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text(activePlayerName)
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(activeColor)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(playerScores[selectedPlayerIndex].routePoints) pt")
                            .font(.title)
                            .fontWeight(.heavy)
                            .foregroundColor(activeColor)
                        Text("Routes totaal")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Actie Kiezer voor deze beurt
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wat heeft \(activePlayerName) gedaan deze beurt?")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    // Optie 1: Geen route gelegd
                    Button(action: {
                        confirmLiveTurn(points: 0, description: "Kaarten gepakt")
                    }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.secondary)
                            Text("Geen route gelegd (kaarten pakken)")
                                .fontWeight(.medium)
                            Spacer()
                            Text("+0 pt")
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .foregroundColor(.primary)

                    Text("Of claim een treintraject (routepunten):")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    // Trein presets (1..8 wagons)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        liveTrainPresetButton(length: 1, points: 1)
                        liveTrainPresetButton(length: 2, points: 2)
                        liveTrainPresetButton(length: 3, points: 4)
                        liveTrainPresetButton(length: 4, points: 7)
                        liveTrainPresetButton(length: 5, points: 10)
                        liveTrainPresetButton(length: 6, points: 15)
                        liveTrainPresetButton(length: 8, points: 21)
                        liveCustomPointsButton
                    }
                }
            }
            .padding()
            .background(activeLightBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(activeColor.opacity(0.4), lineWidth: 1.5)
            )
            .padding(.horizontal)

            // Beurt Geschiedenis van deze ronde
            if !roundTurns.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption)
                        Text("Beurten in Ronde \(currentRound)")
                            .font(.caption)
                            .fontWeight(.bold)
                        Spacer()
                        Button("Alle rondes") {
                            showRondesSheet = true
                        }
                        .font(.caption2)
                        .foregroundColor(activeColor)

                        if !turnHistory.isEmpty {
                            Button("Herstel vorige") {
                                undoLastTurn()
                            }
                            .font(.caption2)
                            .foregroundColor(.red)
                        }
                    }
                    .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text("Houd een beurt ingedrukt om de stand daarnaartoe te herstellen")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    ForEach(roundTurns) { t in
                        let pColor = playerColors[safe: t.playerIndex] ?? .blauw
                        HStack {
                            Circle().fill(pColor.color).frame(width: 8, height: 8)
                            Text(spelers[safe: t.playerIndex] ?? "")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("• \(t.description)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("+\(t.points) pt")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(t.points > 0 ? pColor.color : .secondary)

                            Button(action: {
                                restoreTargetTurn = t
                                showRestoreDialog = true
                            }) {
                                Image(systemName: "arrow.uturn.backward.circle")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                        .onLongPressGesture {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            restoreTargetTurn = t
                            showRestoreDialog = true
                        }
                        .contextMenu {
                            Button(role: .destructive, action: {
                                herstelNaarTurn(t, includeThisTurn: false)
                            }) {
                                Label("Herstel vóór beurt van \(spelers[safe: t.playerIndex] ?? "")", systemImage: "arrow.uturn.backward")
                            }
                            Button(action: {
                                herstelNaarTurn(t, includeThisTurn: true)
                            }) {
                                Label("Herstel t/m beurt van \(spelers[safe: t.playerIndex] ?? "")", systemImage: "arrow.uturn.forward")
                            }
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }

            // Knop: Naar Eindtelling
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation {
                    currentMode = .categorieen
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "flag.checkered.circle.fill")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Spel afgelopen? Ga naar Eindtelling")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Voer bestemmingskaarten, bonussen en stations in")
                            .font(.caption2)
                            .opacity(0.9)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.headline)
                }
                .foregroundColor(activePlayerColor.onColorTextColor)
                .padding()
                .background(activeColor)
                .cornerRadius(14)
                .shadow(color: activeColor.opacity(0.35), radius: 6, x: 0, y: 3)
            }
            .padding(.horizontal)
            .padding(.top, 4)
        }
    }

    private func liveTrainPresetButton(length: Int, points: Int) -> some View {
        Button(action: {
            confirmLiveTurn(points: points, description: "\(length)🚃 route (+\(points) pt)")
        }) {
            VStack(spacing: 2) {
                Text("\(length) 🚃")
                    .font(.caption2)
                    .fontWeight(.bold)
                Text("+\(points)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(activeColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(activeColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var liveCustomPointsButton: some View {
        Button(action: {
            showCustomPointsAlert = true
        }) {
            VStack(spacing: 2) {
                Text("✏️ Anders")
                    .font(.caption2)
                    .fontWeight(.bold)
                Text("Vrij getal")
                    .font(.caption2)
                    .foregroundColor(activeColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(activeColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func confirmLiveTurn(points: Int, description: String) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let activeIdx = selectedPlayerIndex
        playerScores[activeIdx].routePoints += points
        let entry = TTRTurnEntry(round: currentRound, playerIndex: activeIdx, points: points, description: description)
        turnHistory.append(entry)

        withAnimation(.easeInOut(duration: 0.25)) {
            if turnIndexInRound + 1 < spelers.count {
                turnIndexInRound += 1
                selectedPlayerIndex = turnIndexInRound
            } else {
                turnIndexInRound = 0
                currentRound += 1
                selectedPlayerIndex = 0
            }
        }
    }

    private func undoLastTurn() {
        guard let last = turnHistory.popLast() else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        playerScores[last.playerIndex].routePoints = max(0, playerScores[last.playerIndex].routePoints - last.points)

        withAnimation(.easeInOut(duration: 0.25)) {
            currentRound = last.round
            turnIndexInRound = last.playerIndex
            selectedPlayerIndex = last.playerIndex
        }
    }

    // MARK: - Directe Score Weergave

    private var directModeView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "keyboard")
                    .foregroundColor(.blue)
                Text("Tik op een score om direct een getal in te typen met het cijfertoetsenbord.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 2)

            ForEach(spelers.indices, id: \.self) { idx in
                let pColor = playerColors[safe: idx] ?? .blauw
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(pColor.color)
                            .frame(width: 12, height: 12)

                        Text(spelers[idx])
                            .font(.headline)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Button(action: {
                            playerScores[idx].directScore -= 10
                        }) {
                            Text("-10")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 6)
                                .background(pColor.lightBgColor)
                                .foregroundColor(pColor.color)
                                .cornerRadius(6)
                        }

                        Button(action: {
                            playerScores[idx].directScore -= 1
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                        }

                        NumericScoreInputView(
                            score: $playerScores[idx].directScore,
                            allowNegative: true,
                            range: -100...400,
                            tintColor: pColor.color,
                            minWidth: 54,
                            height: 36
                        )

                        Button(action: {
                            playerScores[idx].directScore += 1
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(pColor.color)
                        }

                        Button(action: {
                            playerScores[idx].directScore += 10
                        }) {
                            Text("+10")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 6)
                                .background(pColor.lightBgColor)
                                .foregroundColor(pColor.color)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(pColor.color.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Voltooien Knop

    private var finishButton: some View {
        Button(action: {
            finalizeGame()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                Text("Spel Voltooien & Uitslag Bekijken")
            }
            .font(.headline)
            .foregroundColor(activePlayerColor.onColorTextColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(activeColor)
            .cornerRadius(14)
            .shadow(color: activeColor.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .padding(.horizontal)
    }

    private func finalizeGame() {
        guard let highest = sortedPlayers.first else { return }
        winnaarPlayer = highest

        let detailed = spelers.indices.map { i in
            (name: spelers[i], score: effectiveScore(for: i))
        }
        scoreManager.saveGame(
            gameName: "Ticket to Ride",
            playerScores: detailed,
            winnerName: highest.name,
            scoreProgression: ttrChartData
        )
        ActiveGameManager.shared.clearActiveGame()
        showWinnaarView = true
    }

    private var sortedPlayers: [Player] {
        let pairs = spelers.indices.map { i in
            (player: Player(name: spelers[i]), score: effectiveScore(for: i))
        }
        return pairs.sorted { $0.score > $1.score }.map { $0.player }
    }

    private var sortedScores: [Int] {
        let pairs = spelers.indices.map { i in
            (player: Player(name: spelers[i]), score: effectiveScore(for: i))
        }
        return pairs.sorted { $0.score > $1.score }.map { $0.score }
    }

    // MARK: - Alle Rondes Sheet & Herstel Functies

    private var allRoundsSheetView: some View {
        NavigationStack {
            List {
                if turnHistory.isEmpty {
                    Text("Er zijn nog geen beurten geregistreerd.")
                        .foregroundColor(.secondary)
                } else {
                    Section(header: Text("Scoreverloop")) {
                        ScoreProgressionChartView(
                            title: "Scoreverloop Ticket to Ride",
                            dataPoints: ttrChartData,
                            playerNames: spelers
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.yellow)
                            Text("Houd een beurt ingedrukt om de puntenstand daarnaartoe te herstellen.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    let rounds = Array(Set(turnHistory.map { $0.round })).sorted()
                    ForEach(rounds, id: \.self) { r in
                        let turnsInR = turnHistory.filter { $0.round == r }
                        Section(header: Text("Ronde \(r)")) {
                            ForEach(turnsInR) { turn in
                                let pColor = playerColors[safe: turn.playerIndex] ?? .blauw
                                HStack {
                                    Circle().fill(pColor.color).frame(width: 8, height: 8)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(spelers[safe: turn.playerIndex] ?? "")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text(turn.description)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("+\(turn.points) pt")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(turn.points > 0 ? pColor.color : .secondary)

                                    Button(action: {
                                        restoreTargetTurn = turn
                                        showRestoreDialog = true
                                    }) {
                                        Image(systemName: "arrow.uturn.backward.circle")
                                            .font(.title3)
                                            .foregroundColor(.orange)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 3)
                                .contentShape(Rectangle())
                                .onLongPressGesture {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    restoreTargetTurn = turn
                                    showRestoreDialog = true
                                }
                                .contextMenu {
                                    Button(role: .destructive, action: {
                                        herstelNaarTurn(turn, includeThisTurn: false)
                                    }) {
                                        Label("Herstel vóór beurt van \(spelers[safe: turn.playerIndex] ?? "")", systemImage: "arrow.uturn.backward")
                                    }
                                    Button(action: {
                                        herstelNaarTurn(turn, includeThisTurn: true)
                                    }) {
                                        Label("Herstel t/m beurt van \(spelers[safe: turn.playerIndex] ?? "")", systemImage: "arrow.uturn.forward")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rondegeschiedenis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klaar") {
                        showRondesSheet = false
                    }
                }
            }
        }
    }

    private func herstelNaarTurn(_ target: TTRTurnEntry, includeThisTurn: Bool) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        guard let idx = turnHistory.firstIndex(where: { $0.id == target.id }) else { return }
        let cutoff = includeThisTurn ? idx + 1 : idx
        let keptTurns = Array(turnHistory.prefix(cutoff))

        // Reset and recompute routePoints
        for i in playerScores.indices {
            playerScores[i].routePoints = 0
        }
        for turn in keptTurns {
            if turn.playerIndex < playerScores.count {
                playerScores[turn.playerIndex].routePoints += turn.points
            }
        }
        turnHistory = keptTurns

        if let last = keptTurns.last {
            if last.playerIndex + 1 < spelers.count {
                turnIndexInRound = last.playerIndex + 1
                currentRound = last.round
                selectedPlayerIndex = turnIndexInRound
            } else {
                turnIndexInRound = 0
                currentRound = last.round + 1
                selectedPlayerIndex = 0
            }
        } else {
            currentRound = 1
            turnIndexInRound = 0
            selectedPlayerIndex = 0
        }
        showRondesSheet = false
    }

    private func resetGame() {
        playerScores = Array(repeating: TTRPlayerScore(), count: spelers.count)
        currentRound = 1
        turnIndexInRound = 0
        turnHistory = []
        selectedPlayerIndex = 0
        winnaarPlayer = Player(name: "")
        showWinnaarView = false
        ActiveGameManager.shared.clearActiveGame()
    }

    private func saveActiveDraft() {
        let summary = spelers.indices.map { i in
            "\(spelers[i]): \(effectiveScore(for: i)) pt"
        }.joined(separator: " • ")

        ActiveGameManager.shared.saveActiveGame(
            gameName: "Ticket to Ride",
            playerNames: spelers,
            currentRound: currentRound,
            summary: summary
        )
    }

    private var ttrChartData: [RoundScoreDataPoint] {
        let rounds = Array(Set(turnHistory.map { $0.round })).sorted()
        var runningScores = Array(repeating: 0, count: spelers.count)
        var points: [RoundScoreDataPoint] = []

        for r in rounds {
            let turnsInR = turnHistory.filter { $0.round == r }
            for turn in turnsInR {
                if turn.playerIndex < runningScores.count {
                    runningScores[turn.playerIndex] += turn.points
                }
            }
            for (idx, name) in spelers.enumerated() {
                points.append(RoundScoreDataPoint(
                    round: r,
                    playerName: name,
                    cumulativeScore: runningScores[safe: idx] ?? 0
                ))
            }
        }
        return points
    }
}

#Preview {
    NavigationStack {
        TicketToRideGameView(spelers: ["Niels", "Lisa", "Tom"], initialMode: .categorieen)
    }
}
