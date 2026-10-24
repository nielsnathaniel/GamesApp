import SwiftUI

struct SpelsessiesBeheerView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @State private var selectedGameFilter: String = "Alle Spellen"

    // Alerts voor bevestiging
    @State private var gameToDelete: PlayedGame?
    @State private var showDeleteSingleGameAlert: Bool = false

    @State private var dayToDelete: DayGroup?
    @State private var showDeleteDayAlert: Bool = false

    @State private var showDeleteBeforeYesterdayAlert: Bool = false
    @State private var showDeleteGameTypeAlert: Bool = false

    struct DayGroup: Identifiable {
        var id: Date
        let date: Date
        let title: String
        var games: [PlayedGame]
    }

    private var availableGameFilters: [String] {
        var list = ["Alle Spellen"]
        let distinct = Set(scoreManager.playedGames.map { $0.gameName }).sorted()
        list.append(contentsOf: distinct)
        return list
    }

    private var filteredGames: [PlayedGame] {
        if selectedGameFilter == "Alle Spellen" {
            return scoreManager.playedGames
        } else {
            return scoreManager.playedGames.filter {
                $0.gameName.caseInsensitiveCompare(selectedGameFilter) == .orderedSame
            }
        }
    }

    private var groupedByDay: [DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredGames) { game in
            calendar.startOfDay(for: game.date)
        }

        let sortedDates = grouped.keys.sorted(by: >)
        return sortedDates.map { dayDate in
            let dayGames = (grouped[dayDate] ?? []).sorted(by: { $0.date > $1.date })
            return DayGroup(
                id: dayDate,
                date: dayDate,
                title: dayTitle(for: dayDate),
                games: dayGames
            )
        }
    }

    private var gamesBeforeYesterdayCount: Int {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        return scoreManager.playedGames.filter { $0.date < startOfYesterday }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. Spelfilter Chips
                if availableGameFilters.count > 1 {
                    filterChipsBar
                }

                // 2. Snelle opruim-kaart voor testdata (vóór gisteren)
                if gamesBeforeYesterdayCount > 0 && selectedGameFilter == "Alle Spellen" {
                    quickCleanupBanner
                }

                // 3. Actieve filters melding & snelle wis-knop voor dat specifieke spel
                if selectedGameFilter != "Alle Spellen" {
                    activeFilterBanner
                }

                // 4. Overzicht per dag
                if groupedByDay.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(groupedByDay) { group in
                            daySection(group)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Opgeslagen Spelsessies")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            scoreManager.refresh()
        }
        // Alert 1: Enkel potje verwijderen
        .alert("Spelsessie verwijderen", isPresented: $showDeleteSingleGameAlert) {
            Button("Verwijder", role: .destructive) {
                if let g = gameToDelete {
                    withAnimation {
                        scoreManager.deleteGame(id: g.id)
                    }
                }
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            if let g = gameToDelete {
                Text("Weet je zeker dat je '\(g.sessionTitle)' wilt verwijderen? De statistieken worden direct bijgewerkt.")
            } else {
                Text("Weet je zeker dat je dit potje wilt verwijderen?")
            }
        }
        // Alert 2: Hele dag verwijderen
        .alert("Alle potjes van de dag wissen", isPresented: $showDeleteDayAlert) {
            Button("Wis hele dag", role: .destructive) {
                if let d = dayToDelete {
                    withAnimation {
                        scoreManager.deleteGames(on: d.date)
                    }
                }
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            if let d = dayToDelete {
                Text("Weet je zeker dat je alle \(d.games.count) potjes van \(d.title) wilt verwijderen? Potjes van andere dagen blijven bewaard.")
            } else {
                Text("Weet je zeker dat je deze dag wilt wissen?")
            }
        }
        // Alert 3: Alles van vóór gisteren wissen
        .alert("Testdata vóór gisteren opruimen", isPresented: $showDeleteBeforeYesterdayAlert) {
            Button("Verwijder testdata", role: .destructive) {
                withAnimation {
                    scoreManager.deleteGamesBeforeYesterday()
                }
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            Text("Weet je zeker dat je alle \(gamesBeforeYesterdayCount) potjes van vóór gisteren wilt verwijderen? De echte gegevens van gisteren en vandaag blijven volledig bewaard.")
        }
        // Alert 4: Alle potjes van geselecteerd spel wissen
        .alert("Alle potjes van \(selectedGameFilter) wissen", isPresented: $showDeleteGameTypeAlert) {
            Button("Wis alle \(selectedGameFilter) potjes", role: .destructive) {
                withAnimation {
                    scoreManager.deleteGames(forGame: selectedGameFilter)
                    selectedGameFilter = "Alle Spellen"
                }
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            Text("Weet je zeker dat je alle opgeslagen potjes van \(selectedGameFilter) wilt wissen?")
        }
    }

    // MARK: - Filter Chips

    private var filterChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableGameFilters, id: \.self) { g in
                    let isSelected = selectedGameFilter == g
                    let color = g == "Alle Spellen" ? Color.blue : gameColor(for: g)

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedGameFilter = g
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: gameIcon(for: g))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(isSelected ? .white : color)
                            Text(g)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background {
                            ZStack {
                                if isSelected {
                                    color
                                        .clipShape(Capsule())
                                        .shadow(color: color.opacity(0.35), radius: 5, x: 0, y: 2)
                                } else {
                                    Color(UIColor.secondarySystemGroupedBackground)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .foregroundColor(isSelected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 2)
        }
    }

    // MARK: - Quick Cleanup Banner (Vóór Gisteren)

    private var quickCleanupBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "sparkles")
                        .foregroundColor(.orange)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Oude testdata opruimen?")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("Er zijn \(gamesBeforeYesterdayCount) potjes gespeeld vóór gisteren. Gisteren & vandaag blijven bewaard.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Wis testdata") {
                    showDeleteBeforeYesterdayAlert = true
                }
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.orange)
                .cornerRadius(8)
                .shadow(color: Color.orange.opacity(0.3), radius: 3, x: 0, y: 1.5)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }

    // MARK: - Actieve Filter Banner

    private var activeFilterBanner: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundColor(gameColor(for: selectedGameFilter))
            Text("Gefilterd op: \(selectedGameFilter) (\(filteredGames.count) potjes)")
                .font(.caption)
                .fontWeight(.semibold)

            Spacer()

            Button(role: .destructive, action: {
                showDeleteGameTypeAlert = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text("Wis alle \(selectedGameFilter)")
                }
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    // MARK: - Dag Sectie

    private func daySection(_ group: DayGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Dag Header
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(group.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\(group.games.count) \(group.games.count == 1 ? "spelsessie" : "spelsessies")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    dayToDelete = group
                    showDeleteDayAlert = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Wis deze dag")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 4)

            // Sessies van deze dag
            ForEach(group.games) { game in
                sessionCard(game)
            }
        }
    }

    // MARK: - Spelsessie Kaart

    private func sessionCard(_ game: PlayedGame) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // Spel icoontje
                let assetKey = game.gameName.replacingOccurrences(of: " ", with: "")
                if let uiImg = UIImage(named: game.gameName) ?? UIImage(named: assetKey) ?? (game.gameName.caseInsensitiveCompare("Nmbr9") == .orderedSame ? (UIImage(named: "Nmbr9") ?? UIImage(named: "NMbr9")) : nil) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(gameColor(for: game.gameName).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: gameIcon(for: game.gameName))
                            .foregroundColor(gameColor(for: game.gameName))
                            .font(.system(size: 20))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    // Duidelijke titel conform verzoek: "Spelsessie [Spelnaam] met [Spelers]"
                    Text(game.sessionTitle)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Text(timeString(game.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        if !game.winner.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.yellow)
                                Text(game.winner)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(6)
                        }
                    }
                }

                Spacer()

                // Verwijder knop voor individuele sessie
                Button(role: .destructive, action: {
                    gameToDelete = game
                    showDeleteSingleGameAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            // Scores per speler
            if !game.scores.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(game.scores) { sc in
                            HStack(spacing: 4) {
                                Text(sc.playerName)
                                    .fontWeight(.medium)
                                Text("\(sc.score) pt")
                                    .fontWeight(.bold)
                                    .foregroundColor(sc.isWinner ? .green : .secondary)

                                if let j = sc.juisteBalzakken, j > 0 {
                                    Text("🎯\(j)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.green)
                                }
                                if let f = sc.fouteBalzakken, f > 0 {
                                    Text("⚠️\(f)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.red)
                                }
                            }
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
    }

    // MARK: - Lege Staat

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 40)

            Text("Geen spelsessies gevonden")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Er zijn geen potjes die overeenkomen met de huidige selectie.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    // MARK: - Datum & Tijd Formattering (Nederlands)

    private func dayTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Vandaag (\(formattedDayMonth(date)))"
        } else if calendar.isDateInYesterday(date) {
            return "Gisteren (\(formattedDayMonth(date)))"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "nl_NL")
            formatter.dateFormat = "EEEE d MMMM yyyy"
            return formatter.string(from: date).capitalized
        }
    }

    private func formattedDayMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func gameIcon(for game: String) -> String {
        switch game {
        case "Alle Spellen": return "line.3.horizontal.decrease.circle.fill"
        case "Crockinole": return "circle.circle.fill"
        case "Regenwormen": return "circle.hexagongrid.fill"
        case "Jatten": return "hand.raised.fill"
        case "Balzakken": return "flame.fill"
        case "Beverbende": return "pawprint.fill"
        case "Nmbr9": return "number.square.fill"
        case "Duizenden": return "suit.spade.fill"
        case "Love Letter": return "heart.fill"
        default: return "gamecontroller.fill"
        }
    }

    private func gameColor(for game: String) -> Color {
        switch game {
        case "Crockinole": return .blue
        case "Regenwormen": return .orange
        case "Jatten": return .purple
        case "Balzakken": return .red
        case "Beverbende": return .green
        case "Nmbr9": return .indigo
        case "Love Letter": return .pink
        default: return .teal
        }
    }
}

#Preview {
    NavigationStack {
        SpelsessiesBeheerView()
    }
}
