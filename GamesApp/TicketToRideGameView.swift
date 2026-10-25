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

struct TicketToRideGameView: View {
    let spelers: [String]
    let initialMode: TicketToRideSetupView.TTRScoreMode

    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var currentMode: TicketToRideSetupView.TTRScoreMode
    @State private var playerScores: [TTRPlayerScore]
    @State private var selectedPlayerIndex: Int = 0
    @State private var showWinnaarView: Bool = false
    @State private var winnaarPlayer: Player = Player(name: "")

    init(spelers: [String], initialMode: TicketToRideSetupView.TTRScoreMode) {
        self.spelers = spelers
        self.initialMode = initialMode
        _currentMode = State(initialValue: initialMode)
        _playerScores = State(initialValue: Array(repeating: TTRPlayerScore(), count: spelers.count))
    }

    private func effectiveScore(for index: Int) -> Int {
        guard let p = playerScores[safe: index] else { return 0 }
        return currentMode == .categorieen ? p.calculatedTotal() : p.directScore
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                headerView

                // Modus Wisselaar
                modeSwitchBar

                if currentMode == .categorieen {
                    // Categorieën formulier
                    categoriesView
                } else {
                    // Directe score weergave
                    directModeView
                }

                Spacer(minLength: 20)

                // Afronden knop
                finishButton
            }
            .padding(.vertical)
        }
        .navigationTitle("Ticket to Ride")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showWinnaarView) {
            WinnaarView(
                gameName: "Ticket to Ride",
                winnaar: winnaarPlayer,
                sortedSpelers: sortedPlayers,
                sortedScores: sortedScores,
                isLowestScoreWins: false
            )
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
                    .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 1)
            } else {
                Image(systemName: "tram.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 32))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Ticket to Ride")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(currentMode == .categorieen ? "Puntentelling per categorie" : "Directe totaalscores")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
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

    // MARK: - Categorieën Weergave

    private var categoriesView: some View {
        VStack(spacing: 16) {
            // Speler Selector Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(spelers.indices, id: \.self) { idx in
                        let isSelected = selectedPlayerIndex == idx
                        let total = effectiveScore(for: idx)

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation { selectedPlayerIndex = idx }
                        }) {
                            VStack(spacing: 4) {
                                Text(spelers[idx])
                                    .font(.subheadline)
                                    .fontWeight(isSelected ? .bold : .medium)

                                Text("\(total) pt")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(isSelected ? .white : .blue)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
                            .foregroundColor(isSelected ? .white : .primary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            // Geselecteerde Speler Formulier
            if let activePlayer = spelers[safe: selectedPlayerIndex] {
                VStack(spacing: 14) {
                    // Header kaart van actieve speler
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Score van \(activePlayer)")
                                .font(.headline)
                            Text("Routes, bestemmingskaarten en bonussen")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(playerScores[selectedPlayerIndex].calculatedTotal()) pt")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Totaal")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // 1. Routepunten (Treintrajecten)
                    routePointsSection

                    // 2. Bestemmingskaarten (Tickets)
                    ticketsSection

                    // 3. Bonussen & Stations
                    bonusesSection
                }
                .padding(.vertical, 8)
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
                    .foregroundColor(.blue)

                Spacer()

                Text("\(playerScores[selectedPlayerIndex].routePoints) pt")
                    .font(.subheadline)
                    .fontWeight(.bold)
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
                            .background(Color.secondary.opacity(0.12))
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

                    Button(action: {
                        playerScores[selectedPlayerIndex].routePoints += 1
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }

                    Button(action: {
                        playerScores[selectedPlayerIndex].routePoints += 5
                    }) {
                        Text("+5")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.12))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
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
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.12))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bestemmingskaarten Sectie

    private var ticketsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("2. Bestemmingskaarten (Tickets)", systemImage: "ticket.fill")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.indigo)

            // Voltooide tickets
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Voltooide tickets")
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
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                    }

                    Button(action: {
                        if playerScores[selectedPlayerIndex].completedTickets > 0 {
                            playerScores[selectedPlayerIndex].completedTickets -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill").foregroundColor(.red)
                    }

                    Text("+\(playerScores[selectedPlayerIndex].completedTickets)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .frame(minWidth: 40)

                    Button(action: {
                        playerScores[selectedPlayerIndex].completedTickets += 1
                    }) {
                        Image(systemName: "plus.circle.fill").foregroundColor(.green)
                    }

                    Button(action: {
                        playerScores[selectedPlayerIndex].completedTickets += 5
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

            Divider()

            // Niet-voltooide tickets (Strafpunten)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mislukte tickets (Minpunten)")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Aftrek voor niet-behaalde routes")
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
                        Image(systemName: "minus.circle.fill").foregroundColor(.secondary)
                    }

                    Text("-\(playerScores[selectedPlayerIndex].failedTickets)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .frame(minWidth: 40)

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
        .padding(.horizontal)
    }

    // MARK: - Bonussen & Stations

    private var bonusesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("3. Bonussen & Stations", systemImage: "star.fill")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.orange)

            // Langste Route (+10 pt)
            Toggle(isOn: $playerScores[selectedPlayerIndex].hasLongestRoute) {
                HStack(spacing: 8) {
                    Image(systemName: "road.lanes")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Langste aaneengesloten route")
                            .font(.body)
                        Text("+10 punten bonus")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(.orange)

            Divider()

            // Globetrotter (+10 pt)
            Toggle(isOn: $playerScores[selectedPlayerIndex].hasGlobetrotter) {
                HStack(spacing: 8) {
                    Image(systemName: "globe.europe.africa.fill")
                        .foregroundColor(.teal)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Globetrotter (meeste tickets)")
                            .font(.body)
                        Text("+10 punten bonus (Europa/uitbreiding)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(.teal)

            Divider()

            // Ongebruikte Stations (4 pt per station, max 3)
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.blue)
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
                        Image(systemName: "plus.circle.fill").foregroundColor(.blue)
                    }
                    .disabled(playerScores[selectedPlayerIndex].unusedStations >= 3)

                    Text("(+\(playerScores[selectedPlayerIndex].unusedStations * 4) pt)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .frame(minWidth: 44)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Directe Score Weergave

    private var directModeView: some View {
        VStack(spacing: 12) {
            ForEach(spelers.indices, id: \.self) { idx in
                HStack(spacing: 14) {
                    Text(spelers[idx])
                        .font(.headline)

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: {
                            if playerScores[idx].directScore >= 10 {
                                playerScores[idx].directScore -= 10
                            }
                        }) {
                            Text("-10")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(6)
                        }

                        Button(action: {
                            if playerScores[idx].directScore > 0 {
                                playerScores[idx].directScore -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                        }

                        Text("\(playerScores[idx].directScore)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(minWidth: 44)

                        Button(action: {
                            playerScores[idx].directScore += 1
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        }

                        Button(action: {
                            playerScores[idx].directScore += 10
                        }) {
                            Text("+10")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
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
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(14)
            .shadow(color: Color.blue.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .padding(.horizontal)
    }

    private func finalizeGame() {
        guard let highest = sortedPlayers.first else { return }
        winnaarPlayer = highest

        let detailed = spelers.indices.map { i in
            (name: spelers[i], score: effectiveScore(for: i))
        }
        scoreManager.saveGame(gameName: "Ticket to Ride", playerScores: detailed, winnerName: highest.name)
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
}

#Preview {
    NavigationStack {
        TicketToRideGameView(spelers: ["Niels", "Lisa", "Tom"], initialMode: .categorieen)
    }
}
