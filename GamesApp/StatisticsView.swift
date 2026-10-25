import SwiftUI

struct StatisticsView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    var isSheet: Bool = false
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSegment: StatSegment = .overzicht
    @State private var selectedGameFilter: String = "Alle Spellen"
    @State private var selectedTeamGameFilter: String = "Alle Spellen"
    @State private var selectedPartnerPlayer: String = ""
    @State private var selectedDetailGame: String = "Balzakken"
    @State private var selectedH2HPlayerA: String = ""
    @State private var selectedH2HPlayerB: String = ""
    @State private var selectedScoreProgressionSessionId: UUID? = nil
    @State private var expandedSessionIds: Set<UUID> = []
    @Namespace private var categoryAnimation

    init(isSheet: Bool = false, initialSegment: StatSegment = .overzicht, initialGame: String? = nil) {
        self.isSheet = isSheet
        _selectedSegment = State(initialValue: initialSegment)
        if let initialGame = initialGame {
            _selectedDetailGame = State(initialValue: initialGame)
            _selectedGameFilter = State(initialValue: initialGame)
        }
    }

    struct AppGameInfo: Identifiable {
        var id: String { name }
        let name: String
        let assetName: String
        let defaultIcon: String
        let defaultColor: Color
    }

    let allAppGames: [AppGameInfo] = [
        AppGameInfo(name: "Balzakken", assetName: "Balzakken", defaultIcon: "flame.fill", defaultColor: .red),
        AppGameInfo(name: "Qwixx", assetName: "Qwixx", defaultIcon: "dice.fill", defaultColor: .orange),
        AppGameInfo(name: "Pig Hole", assetName: "PigHole", defaultIcon: "circle.circle.fill", defaultColor: .pink),
        AppGameInfo(name: "Ticket to Ride", assetName: "TicketToRide", defaultIcon: "tram.fill", defaultColor: .blue),
        AppGameInfo(name: "Quickstop", assetName: "Quickstop", defaultIcon: "bolt.fill", defaultColor: .yellow),
        AppGameInfo(name: "Love Letter", assetName: "LoveLetter", defaultIcon: "heart.fill", defaultColor: .pink),
        AppGameInfo(name: "Regenwormen", assetName: "Regenwormen", defaultIcon: "circle.hexagongrid.fill", defaultColor: .orange),
        AppGameInfo(name: "Jatten", assetName: "Jatten", defaultIcon: "hand.raised.fill", defaultColor: .purple),
        AppGameInfo(name: "30 Seconds", assetName: "ThirtySeconds", defaultIcon: "timer", defaultColor: .orange),
        AppGameInfo(name: "Cranium", assetName: "Cranium", defaultIcon: "brain.head.profile", defaultColor: .purple),
        AppGameInfo(name: "Crockinole", assetName: "Crockinole", defaultIcon: "circle.circle.fill", defaultColor: .blue),
        AppGameInfo(name: "Beverbende", assetName: "Beverbende", defaultIcon: "pawprint.fill", defaultColor: .green),
        AppGameInfo(name: "Duizenden", assetName: "Duizenden", defaultIcon: "suit.spade.fill", defaultColor: .blue),
        AppGameInfo(name: "Nmbr9", assetName: "Nmbr9", defaultIcon: "number.square.fill", defaultColor: .indigo)
    ]

    enum StatSegment: String, CaseIterable, Identifiable {
        case overzicht = "Overzicht"
        case spelers = "Spelers"
        case perSpel = "Per Spel"
        case teams = "Duo's"
        case rivaliteiten = "Wie wint?"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overzicht: return "chart.pie.fill"
            case .spelers: return "crown.fill"
            case .perSpel: return "gamecontroller.fill"
            case .teams: return "person.2.fill"
            case .rivaliteiten: return "bolt.fill"
            }
        }

        var themeColor: Color {
            switch self {
            case .overzicht: return .blue
            case .spelers: return .purple
            case .perSpel: return .teal
            case .teams: return .indigo
            case .rivaliteiten: return .orange
            }
        }
    }

    var availableGames: [String] {
        var games = ["Alle Spellen"]
        let distinct = Set(scoreManager.playedGames.map { $0.gameName }).sorted()
        games.append(contentsOf: distinct)
        return games
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Moderne interactieve categorie-balk
                categoryNavBar

                ScrollView {
                    VStack(spacing: 18) {
                        switch selectedSegment {
                        case .overzicht:
                            overviewSection
                        case .spelers:
                            playersLeaderboardSection
                        case .perSpel:
                            perGameSection
                        case .teams:
                            teamsSection
                        case .rivaliteiten:
                            rivalriesSection
                        }
                    }
                    .padding()
                    .animation(.easeInOut(duration: 0.2), value: selectedSegment)
                }
            }
            .navigationTitle("Statistieken")
            .toolbar {
                if isSheet {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Sluit") {
                            dismiss()
                        }
                        .font(.body.weight(.semibold))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SpelsessiesBeheerView()) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.clock")
                            Text("Sessies")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .onAppear {
                scoreManager.refresh()
                if let mostPlayed = scoreManager.mostPlayedGames().first?.gameName,
                   scoreManager.playedGames.filter({ scoreManager.matchesGameName($0.gameName, selectedDetailGame) }).isEmpty {
                    selectedDetailGame = mostPlayed
                }
            }
        }
    }

    // MARK: - Moderne Categorie Balk

    private var categoryNavBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(StatSegment.allCases) { segment in
                        let isSelected = selectedSegment == segment

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedSegment = segment
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: segment.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(isSelected ? .white : segment.themeColor)

                                Text(segment.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(isSelected ? .white : .primary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background {
                                ZStack {
                                    if isSelected {
                                        segment.themeColor
                                            .clipShape(Capsule())
                                            .matchedGeometryEffect(id: "activeStatPill", in: categoryAnimation)
                                            .shadow(color: segment.themeColor.opacity(0.35), radius: 5, x: 0, y: 2)
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
                        }
                        .buttonStyle(.plain)
                        .id(segment)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: selectedSegment) { _, newSegment in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newSegment, anchor: .center)
                }
            }
        }
    }

    // MARK: - 1. OVERZICHT

    private var overviewSection: some View {
        VStack(spacing: 16) {
            // Snelle KPI-tegels
            quickStatsGrid

            // Meest gespeelde spellen met progress bars
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "flame.circle.fill")
                        .foregroundColor(.orange)
                    Text("Meest Gespeelde Spellen")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                let mostPlayed = scoreManager.mostPlayedGames()
                if mostPlayed.isEmpty {
                    emptyStateCard(text: "Nog geen gespeelde potjes geregistreerd.")
                } else {
                    let totalPlayed = max(1, mostPlayed.reduce(0) { $0 + $1.count })
                    ForEach(mostPlayed, id: \.gameName) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.gameName)
                                    .font(.headline)
                                Spacer()
                                Text("\(item.count)x")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            ProgressView(value: Double(item.count), total: Double(totalPlayed))
                                .tint(gameColor(for: item.gameName))
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)

            // Kampioenen per Spel
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("Kampioenen per Spel")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                let champions = scoreManager.mostWinsPerGame()
                if champions.isEmpty {
                    emptyStateCard(text: "Nog geen winnaars bekend.")
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(champions, id: \.gameName) { champ in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Circle()
                                        .fill(gameColor(for: champ.gameName).opacity(0.2))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Image(systemName: "trophy.fill")
                                                .font(.caption)
                                                .foregroundColor(gameColor(for: champ.gameName))
                                        )
                                    Text(champ.gameName)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }

                                Text(champ.winnerName)
                                    .font(.headline)
                                    .lineLimit(1)

                                Text("\(champ.wins) overwinning\(champ.wins == 1 ? "" : "en")")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)

            // Beste Score Ooit per Spel
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.purple)
                    Text("Topscore Record per Spel")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                let grouped = Dictionary(grouping: scoreManager.scores, by: { $0.gameName })
                if grouped.isEmpty {
                    emptyStateCard(text: "Nog geen topscores geregistreerd.")
                } else {
                    ForEach(grouped.keys.sorted(), id: \.self) { gameName in
                        if let list = grouped[gameName], let best = bestScore(for: gameName, in: list) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(gameName)
                                        .font(.headline)
                                    Text("Door \(best.playerName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("\(best.score)")
                                        .font(.title3)
                                        .fontWeight(.heavy)
                                    Text("pt")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.12))
                                .cornerRadius(8)
                            }
                            if gameName != grouped.keys.sorted().last {
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
    }

    private var quickStatsGrid: some View {
        let totalGames = scoreManager.playedGames.count
        let totalPlayers = scoreManager.fetchPlayerNames().count
        let topWinner = scoreManager.overallWinRankings().first?.playerName ?? "-"
        let favoriteGame = scoreManager.mostPlayedGames().first?.gameName ?? "-"

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // 1. Gespeeld -> Ga direct naar Opgeslagen Spelsessies
            NavigationLink(destination: SpelsessiesBeheerView()) {
                statCard(
                    title: "Gespeeld",
                    value: "\(totalGames)",
                    subtitle: "Sessies",
                    icon: "gamecontroller.fill",
                    color: .blue
                )
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                HapticManager.shared.light()
            })

            // 2. Spelers -> Schakel direct naar tabblad Spelers
            Button(action: {
                HapticManager.shared.light()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    selectedSegment = .spelers
                }
            }) {
                statCard(
                    title: "Spelers",
                    value: "\(totalPlayers)",
                    subtitle: "Ranglijst",
                    icon: "person.2.fill",
                    color: .purple
                )
            }
            .buttonStyle(.plain)

            // 3. Populairst -> Schakel naar tabblad Per Spel met het populairste spel geopend
            Button(action: {
                HapticManager.shared.light()
                if favoriteGame != "-" {
                    selectedDetailGame = favoriteGame
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    selectedSegment = .perSpel
                }
            }) {
                statCard(
                    title: "Populairst",
                    value: favoriteGame,
                    subtitle: "Details",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
            }
            .buttonStyle(.plain)

            // 4. Koploper -> Open spelersprofiel van koploper
            if topWinner != "-" && !topWinner.isEmpty {
                NavigationLink(destination: PlayerStatsView(playerName: topWinner)) {
                    statCard(
                        title: "Koploper",
                        value: topWinner,
                        subtitle: "Profiel",
                        icon: "crown.fill",
                        color: .yellow
                    )
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    HapticManager.shared.light()
                })
            } else {
                Button(action: {
                    HapticManager.shared.light()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedSegment = .spelers
                    }
                }) {
                    statCard(
                        title: "Koploper",
                        value: "-",
                        subtitle: "Nog geen",
                        icon: "crown.fill",
                        color: .yellow
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func statCard(title: String, value: String, subtitle: String? = nil, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.18))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 13, weight: .bold))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary.opacity(0.5))
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                if let sub = subtitle {
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.4))
                    Text(sub)
                        .font(.caption2)
                        .foregroundColor(color)
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
    }

    // MARK: - 2. SPELERS & RANGEN

    private var playersLeaderboardSection: some View {
        VStack(spacing: 16) {
            let rankings = scoreManager.overallWinRankings()

            if rankings.isEmpty {
                emptyStateCard(text: "Nog geen spelersstatistieken.")
            } else {
                // Podium Top 3 (indien minimaal 2 spelers)
                if rankings.count >= 2 {
                    podiumView(rankings: rankings)
                }

                // Volledige lijst
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alle Spelers Klassement")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 4)

                    ForEach(rankings.indices, id: \.self) { idx in
                        let rank = rankings[idx]
                        NavigationLink(destination: PlayerStatsView(playerName: rank.playerName)) {
                            HStack(spacing: 12) {
                                rankBadge(index: idx)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rank.playerName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("\(rank.totalGames) potjes • \(String(format: "%.0f%%", rank.winRate)) winst")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                HStack(spacing: 4) {
                                    Text("\(rank.wins)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                    Image(systemName: "trophy.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }

    private func podiumView(rankings: [(playerName: String, wins: Int, totalGames: Int, winRate: Double)]) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            // #2 Zilver
            if rankings.indices.contains(1) {
                podiumColumn(rank: 2, player: rankings[1].playerName, wins: rankings[1].wins, color: .gray, height: 100)
            }
            // #1 Goud
            if rankings.indices.contains(0) {
                podiumColumn(rank: 1, player: rankings[0].playerName, wins: rankings[0].wins, color: .yellow, height: 130)
            }
            // #3 Brons
            if rankings.indices.contains(2) {
                podiumColumn(rank: 3, player: rankings[2].playerName, wins: rankings[2].wins, color: .brown, height: 80)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }

    private func podiumColumn(rank: Int, player: String, wins: Int, color: Color, height: CGFloat) -> some View {
        NavigationLink(destination: PlayerStatsView(playerName: player)) {
            VStack(spacing: 6) {
                Text(rank == 1 ? "🥇" : (rank == 2 ? "🥈" : "🥉"))
                    .font(.largeTitle)

                Text(player)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(wins) winst")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.25))
                    .frame(height: height)
                    .overlay(
                        Text("#\(rank)")
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(color)
                    )
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func rankBadge(index: Int) -> some View {
        Text("\(index + 1)")
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundColor(index < 3 ? .white : .secondary)
            .frame(width: 28, height: 28)
            .background(index == 0 ? Color.yellow : (index == 1 ? Color.gray : (index == 2 ? Color.brown : Color.clear)))
            .clipShape(Circle())
    }

    // MARK: - 3. WIE WINT VAN WIE? (Rivaliteiten)

    private var rivalriesSection: some View {
        VStack(spacing: 16) {
            // Moderne Filter balk
            if availableGames.count > 1 {
                gameFilterBar
            }

            // Dedicated 1-tegen-1 Vergelijker Card
            headToHeadSelectorCard

            let rivalries = scoreManager.allRivalries(gameFilter: selectedGameFilter)
            if rivalries.isEmpty {
                emptyStateCard(text: "Geen onderlinge wedstrijden gevonden voor \(selectedGameFilter).")
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Alle Onderlinge Duels")
                            .font(.headline)
                        Spacer()
                        Text("\(rivalries.count) ontmoetingen")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)

                    ForEach(rivalries) { h2h in
                        VStack(spacing: 10) {
                            HStack {
                                Text(h2h.playerA)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("\(h2h.winsA) - \(h2h.winsB)")
                                    .font(.title2)
                                    .fontWeight(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.12))
                                    .cornerRadius(8)

                                Text(h2h.playerB)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }

                            // Vergelijkingsbalk
                            let total = max(1, h2h.winsA + h2h.winsB)
                            GeometryReader { geo in
                                HStack(spacing: 2) {
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: geo.size.width * CGFloat(h2h.winsA) / CGFloat(total))
                                    Rectangle()
                                        .fill(Color.purple)
                                        .frame(width: geo.size.width * CGFloat(h2h.winsB) / CGFloat(total))
                                }
                                .cornerRadius(4)
                            }
                            .frame(height: 6)

                            HStack {
                                Text("\(h2h.totalGames) potjes samen")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(h2h.leaderSummary)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
                    }
                }
            }
        }
    }

    private var headToHeadSelectorCard: some View {
        let allPlayers = scoreManager.fetchPlayerNames()
        let playerA = selectedH2HPlayerA.isEmpty ? (allPlayers.first ?? "") : selectedH2HPlayerA
        let playerB = selectedH2HPlayerB.isEmpty ? (allPlayers.indices.contains(1) ? allPlayers[1] : (allPlayers.last ?? "")) : selectedH2HPlayerB

        let h2h = scoreManager.headToHead(playerA: playerA, playerB: playerB, gameFilter: selectedGameFilter)

        return VStack(spacing: 14) {
            HStack {
                Image(systemName: "bolt.shield.fill")
                    .foregroundColor(.orange)
                Text("1-op-1 Directe Strijd")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("Kies 2 spelers")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if allPlayers.count < 2 {
                Text("Voeg minimaal 2 spelers toe om een directe 1-op-1 vergelijking te maken.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                // Twee selectieknoppen
                HStack(spacing: 12) {
                    Menu {
                        Picker("Speler 1", selection: $selectedH2HPlayerA) {
                            ForEach(allPlayers, id: \.self) { p in
                                Text(p).tag(p)
                            }
                        }
                    } label: {
                        HStack {
                            Circle().fill(Color.blue).frame(width: 8, height: 8)
                            Text(playerA.isEmpty ? "Speler 1" : playerA)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }

                    Text("VS")
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(.orange)
                        .padding(6)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Circle())

                    Menu {
                        Picker("Speler 2", selection: $selectedH2HPlayerB) {
                            ForEach(allPlayers, id: \.self) { p in
                                Text(p).tag(p)
                            }
                        }
                    } label: {
                        HStack {
                            Circle().fill(Color.purple).frame(width: 8, height: 8)
                            Text(playerB.isEmpty ? "Speler 2" : playerB)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(10)
                    }
                }

                // Battle Card Scorebord
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(playerA)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("\(h2h.winsA) winst")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 2) {
                            Text("\(h2h.winsA) - \(h2h.winsB)")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.primary)
                            if h2h.ties > 0 {
                                Text("\(h2h.ties)x gelijk")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(playerB)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            Text("\(h2h.winsB) winst")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    // Progress balk
                    let totalWins = max(1, h2h.winsA + h2h.winsB)
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geo.size.width * CGFloat(h2h.winsA) / CGFloat(totalWins))
                            Rectangle()
                                .fill(Color.purple)
                                .frame(width: geo.size.width * CGFloat(h2h.winsB) / CGFloat(totalWins))
                        }
                        .cornerRadius(4)
                    }
                    .frame(height: 8)

                    HStack {
                        Text("\(h2h.totalGames) potjes samen gespeeld")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(h2h.leaderSummary)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(h2h.winsA > h2h.winsB ? .blue : (h2h.winsB > h2h.winsA ? .purple : .orange))
                    }
                }
                .padding(12)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - 3. STATISTIEKEN PER SPEL

    private var perGameSection: some View {
        VStack(spacing: 16) {
            // Horizontale spelselectiebalk
            gameSelectorBar

            let activeGame = selectedDetailGame
            let sessionCount = scoreManager.playedGames.filter { scoreManager.matchesGameName($0.gameName, activeGame) }.count
            let isLowestWins = scoreManager.isLowestScoreWins(for: activeGame)

            // Spelkop met icoon en doel
            gameHeaderCard(gameName: activeGame, sessionCount: sessionCount, isLowestScoreWins: isLowestWins)

            if sessionCount == 0 {
                gameEmptyStateView(gameName: activeGame)
            } else {
                let leaderboard = scoreManager.gameLeaderboard(for: activeGame)
                let bestScore = scoreManager.bestScoreEver(for: activeGame)
                let recent = scoreManager.recentSessions(for: activeGame, limit: 10)

                // 4 Snelle KPI Tegels voor dit spel
                gameQuickStats(leaderboard: leaderboard, bestScore: bestScore, sessionCount: sessionCount)

                // Podium Top 3 indien minstens 2 spelers
                if leaderboard.count >= 2 {
                    gamePodiumView(leaderboard: leaderboard)
                }

                // Scoreverloop Grafiek voor dit spel (Regenwormen en andere spellen)
                gameScoreProgressionCard(recent: recent, gameName: activeGame)

                // Volledige ranglijst voor dit spel
                if !leaderboard.isEmpty {
                    gameLeaderboardCard(leaderboard: leaderboard, gameName: activeGame)
                }

                // Balzakken Hall of Fame (als Balzakken geselecteerd is)
                if scoreManager.matchesGameName(activeGame, "Balzakken") {
                    balzakkenHallOfFameCard
                }

                // Crokinole Uitgebreide Statistieken & Records
                if scoreManager.matchesGameName(activeGame, "Crockinole") {
                    crokinoleStatisticsCard
                }

                // Recente potjes voor dit spel
                gameRecentSessionsCard(recent: recent, gameName: activeGame)
            }
        }
    }

    // MARK: - Per Spel UI Componenten

    private var gameSelectorBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.teal)
                    .font(.subheadline)
                Text("Selecteer Spel")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Text("\(allAppGames.count) spellen")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allAppGames) { game in
                            let isSelected = scoreManager.matchesGameName(selectedDetailGame, game.name)
                            let playCount = scoreManager.playedGames.filter { scoreManager.matchesGameName($0.gameName, game.name) }.count

                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    selectedDetailGame = game.name
                                }
                            }) {
                                HStack(spacing: 6) {
                                    gameThumbnail(for: game.name, size: 20)

                                    Text(game.name)
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))

                                    if playCount > 0 {
                                        Text("\(playCount)x")
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(isSelected ? Color.white.opacity(0.25) : Color.orange.opacity(0.18))
                                            .foregroundColor(isSelected ? .white : .orange)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background {
                                    ZStack {
                                        if isSelected {
                                            game.defaultColor
                                                .clipShape(Capsule())
                                                .shadow(color: game.defaultColor.opacity(0.35), radius: 5, x: 0, y: 2)
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
                            .id(game.name)
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 2)
                }
                .onChange(of: selectedDetailGame) { _, newGame in
                    withAnimation {
                        proxy.scrollTo(newGame, anchor: .center)
                    }
                }
            }
        }
    }

    private func gameHeaderCard(gameName: String, sessionCount: Int, isLowestScoreWins: Bool) -> some View {
        HStack(spacing: 14) {
            gameHeroIcon(for: gameName, size: 60)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(gameName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()

                    // Win condition badge
                    HStack(spacing: 3) {
                        Image(systemName: isLowestScoreWins ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 11))
                        Text(isLowestScoreWins ? "Minste wint" : "Meeste wint")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isLowestScoreWins ? Color.teal : Color.orange).opacity(0.15))
                    .foregroundColor(isLowestScoreWins ? .teal : .orange)
                    .cornerRadius(8)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(sessionCount == 1 ? "1 potje geregistreerd" : "\(sessionCount) potjes geregistreerd")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private func gameQuickStats(leaderboard: [GameSpecificPlayerStat], bestScore: (playerName: String, score: Int)?, sessionCount: Int) -> some View {
        let champion = leaderboard.first
        let recordText = bestScore != nil ? "\(bestScore!.score) pt" : "-"
        let recordSub = bestScore != nil ? "door \(bestScore!.playerName)" : "Geen scores"
        let champSub = champion != nil ? "\(champion!.gamesWon)x winst (\(String(format: "%.0f%%", champion!.winRate)))" : "Geen winnaar"

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            gameStatCard(
                title: "Spel Kampioen",
                value: champion?.playerName ?? "-",
                subtitle: champSub,
                icon: "crown.fill",
                color: .yellow
            )
            gameStatCard(
                title: "Beste Score Ooit",
                value: recordText,
                subtitle: recordSub,
                icon: "star.circle.fill",
                color: .orange
            )
            gameStatCard(
                title: "Deelnemers",
                value: "\(leaderboard.count)",
                subtitle: leaderboard.count == 1 ? "1 actieve speler" : "\(leaderboard.count) actieve spelers",
                icon: "person.2.fill",
                color: .purple
            )
            gameStatCard(
                title: "Totaal Gespeeld",
                value: "\(sessionCount)",
                subtitle: sessionCount == 1 ? "1 potje voltooid" : "\(sessionCount) potjes voltooid",
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            )
        }
    }

    private func gameStatCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
    }

    private func gamePodiumView(leaderboard: [GameSpecificPlayerStat]) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            // #2 Zilver
            if leaderboard.indices.contains(1) {
                gamePodiumColumn(rank: 2, stat: leaderboard[1], color: .gray, height: 95)
            }
            // #1 Goud
            if leaderboard.indices.contains(0) {
                gamePodiumColumn(rank: 1, stat: leaderboard[0], color: .yellow, height: 125)
            }
            // #3 Brons
            if leaderboard.indices.contains(2) {
                gamePodiumColumn(rank: 3, stat: leaderboard[2], color: .brown, height: 75)
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
    }

    private func gamePodiumColumn(rank: Int, stat: GameSpecificPlayerStat, color: Color, height: CGFloat) -> some View {
        NavigationLink(destination: PlayerStatsView(playerName: stat.playerName)) {
            VStack(spacing: 5) {
                Text(rank == 1 ? "🥇" : (rank == 2 ? "🥈" : "🥉"))
                    .font(.title)

                Text(stat.playerName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(stat.gamesWon)x win (\(String(format: "%.0f%%", stat.winRate)))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.22))
                    .frame(height: height)
                    .overlay(
                        Text("#\(rank)")
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(color)
                    )
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func gameLeaderboardCard(leaderboard: [GameSpecificPlayerStat], gameName: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.number")
                    .foregroundColor(.blue)
                Text("Spelers Ranglijst")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("\(leaderboard.count) spelers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, stat in
                NavigationLink(destination: PlayerStatsView(playerName: stat.playerName)) {
                    HStack(spacing: 12) {
                        // Medaille of positie
                        ZStack {
                            Circle()
                                .fill(rankColor(for: index).opacity(0.15))
                                .frame(width: 32, height: 32)

                            if index == 0 {
                                Text("🥇").font(.subheadline)
                            } else if index == 1 {
                                Text("🥈").font(.subheadline)
                            } else if index == 2 {
                                Text("🥉").font(.subheadline)
                            } else {
                                Text("\(index + 1)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.playerName)
                                .font(.headline)
                                .foregroundColor(.primary)

                            HStack(spacing: 8) {
                                Text("\(stat.gamesWon)W - \(stat.gamesPlayed - stat.gamesWon)V")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                if let best = stat.bestScore {
                                    Text("•")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("Record: \(best) pt")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                if let avg = stat.averageScore {
                                    Text("•")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("Gem: \(String(format: "%.1f", avg))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Spacer()

                        // Winrate pill
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(String(format: "%.0f%%", stat.winRate))")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(stat.winRate >= 50 ? .green : .secondary)

                            Text("\(stat.gamesWon)/\(stat.gamesPlayed) gewonnen")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if index < leaderboard.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private var balzakkenHallOfFameCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.red)
                Text("Balzakken Hall of Fame")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("Juiste vs Foute Balzakken")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            let leaderboard = scoreManager.balzakkenLeaderboard()

            if leaderboard.isEmpty {
                Text("Nog geen balzakken geregistreerd.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // Highlights
                HStack(spacing: 12) {
                    if let koning = leaderboard.first(where: { $0.juisteBalzakken > 0 }) {
                        highlightTile(
                            title: "Balzakken Koning",
                            player: koning.playerName,
                            stat: "\(koning.juisteBalzakken)x juist",
                            icon: "crown.fill",
                            color: .yellow
                        )
                    }

                    if let brokkenpiloot = leaderboard.max(by: { $0.fouteBalzakken < $1.fouteBalzakken }), brokkenpiloot.fouteBalzakken > 0 {
                        highlightTile(
                            title: "Gevaarlijkste Speler",
                            player: brokkenpiloot.playerName,
                            stat: "\(brokkenpiloot.fouteBalzakken)x vals",
                            icon: "exclamationmark.triangle.fill",
                            color: .red
                        )
                    }
                }

                // Tabel per speler
                VStack(spacing: 8) {
                    ForEach(leaderboard) { stat in
                        HStack(spacing: 12) {
                            Text(stat.playerName)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Spacer()

                            // Juiste balzakken badge
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("\(stat.juisteBalzakken)x")
                                    .fontWeight(.bold)
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.12))
                            .cornerRadius(8)

                            // Foute balzakken badge
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("\(stat.fouteBalzakken)x")
                                    .fontWeight(.bold)
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(8)
                        }
                        .padding(.vertical, 2)

                        if stat.id != leaderboard.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private var crokinoleStatisticsCard: some View {
        let stats = scoreManager.crokinoleOverallStats()

        return VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "circle.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Crokinole Records & Statistieken")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Hoogste scores per ronde & per set")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            // Top Records Cards (Groot & opvallend)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // 1. Hoogste score in 1 ronde
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.orange)
                        Text("IN 1 RONDE")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.orange)
                    }

                    if let highRound = stats.allTimeHighestRound, highRound.score > 0 {
                        Text("\(highRound.score) pt")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(.primary)
                        Text("\(highRound.player) • R\(highRound.round)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("-")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Text("Nog geen rondes")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.25), lineWidth: 1))

                // 2. Hoogste score in 1 set
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("IN 1 SET")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.yellow.opacity(0.95))
                    }

                    if let highSet = stats.allTimeHighestSet, highSet.score > 0 {
                        Text("\(highSet.score) pt")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(.primary)
                        Text("\(highSet.player)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("-")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Text("Nog geen sets")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.12))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.3), lineWidth: 1))

                // 3. Grootste verschil in 1 ronde
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.blue)
                        Text("GROOTSTE VERSCHIL")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.blue)
                    }

                    if let diff = stats.allTimeHighestDifferential, diff.diff > 0 {
                        Text("+\(diff.diff) pt")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.primary)
                        Text("\(diff.player)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("-")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Text("Nog geen verschil")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.2), lineWidth: 1))

                // 4. Gemiddelde rondes per set
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.purple)
                        Text("RONDES PER SET")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.purple)
                    }

                    if stats.averageRoundsPerSet > 0 {
                        Text(String(format: "%.1f", stats.averageRoundsPerSet))
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.primary)
                        Text("gemiddeld")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    } else {
                        Text("-")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Text("Nog geen data")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.08))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.2), lineWidth: 1))
            }

            // Top 5 Hoogste Scores in 1 Ronde
            if !stats.topRoundScores.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🎯 Top Hoogste Scores in 1 Ronde")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    VStack(spacing: 6) {
                        ForEach(Array(stats.topRoundScores.prefix(5).enumerated()), id: \.offset) { idx, entry in
                            HStack {
                                Text("\(idx + 1).")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, alignment: .leading)

                                Text(entry.player)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text("• R\(entry.round)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text("\(entry.score) pt")
                                    .font(.subheadline)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.orange)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.6))
                            .cornerRadius(8)
                        }
                    }
                }
            }

            // Top 5 Hoogste Scores in 1 Set
            if !stats.topSetScores.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🏆 Top Hoogste Scores in 1 Set")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    VStack(spacing: 6) {
                        ForEach(Array(stats.topSetScores.prefix(5).enumerated()), id: \.offset) { idx, entry in
                            HStack {
                                Text("\(idx + 1).")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, alignment: .leading)

                                Text(entry.player)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Spacer()

                                Text("\(entry.score) pt")
                                    .font(.subheadline)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.yellow)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.6))
                            .cornerRadius(8)
                        }
                    }
                }
            }

            // Set Uitslag Verdeling (Clean sweeps, 3-1, 3-2)
            if stats.cleanSweepsCount > 0 || stats.regularWinsCount > 0 || stats.thrillerWinsCount > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("📊 Wedstrijd-uitslagen (Setverdeling)")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    HStack(spacing: 8) {
                        crokinolePill(title: "3-0 Sweep", count: stats.cleanSweepsCount, emoji: "🧹", color: .green)
                        crokinolePill(title: "3-1 Winst", count: stats.regularWinsCount, emoji: "🎯", color: .blue)
                        crokinolePill(title: "3-2 Thriller", count: stats.thrillerWinsCount, emoji: "🔥", color: .red)
                    }
                }
            }

            // Spelers PR Tabel
            if !stats.playerLeaderboard.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🥇 Persoonlijke Records per Speler")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    VStack(spacing: 8) {
                        ForEach(stats.playerLeaderboard) { player in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(player.playerName)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    Text("\(player.gamesWon)/\(player.gamesPlayed) gewonnen")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                HStack(spacing: 12) {
                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text("Max ronde")
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                        Text(player.highestRoundScore > 0 ? "\(player.highestRoundScore) pt" : "-")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.orange)
                                    }

                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text("Max set")
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                        Text(player.highestSetScore > 0 ? "\(player.highestSetScore) pt" : "-")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.yellow)
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.5))
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private func crokinolePill(title: String, count: Int, emoji: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(emoji)
                .font(.caption)
            Text("\(count)x")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(color.opacity(0.1))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.2), lineWidth: 1))
    }

    private func gameRecentSessionsCard(recent: [PlayedGame], gameName: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.indigo)
                Text("Recente Potjes")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink(destination: SpelsessiesBeheerView()) {
                    Text("Alles bekijken")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }

            if recent.isEmpty {
                Text("Geen recente potjes gevonden.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(recent) { game in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.caption2)
                                    Text(game.date, style: .date)
                                    Text("om")
                                    Text(game.date, style: .time)
                                }
                                .font(.caption2)
                                .foregroundColor(.secondary)

                                Spacer()

                                if game.isTie {
                                    Text("Gelijkspel")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.gray.opacity(0.18))
                                        .foregroundColor(.secondary)
                                        .cornerRadius(6)
                                } else {
                                    let displayWinner: String = {
                                        if let teams = game.teams, let winTeam = teams.first(where: { $0.isWinner }) {
                                            let players = winTeam.playerNames.joined(separator: " & ")
                                            if winTeam.teamName.isEmpty || ScoreManager.isDefaultTeamName(winTeam.teamName) {
                                                return players.isEmpty ? game.winner : players
                                            } else {
                                                return "\(winTeam.teamName) (\(players))"
                                            }
                                        }
                                        return game.winner
                                    }()

                                    HStack(spacing: 3) {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 9))
                                            .foregroundColor(.yellow)
                                        Text(displayWinner)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .cornerRadius(6)
                                }
                            }

                            // Horizontale lijst van scores
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(game.scores) { sc in
                                        let isWinner = sc.isWinner || (!game.isTie && sc.playerName.caseInsensitiveCompare(game.winner) == .orderedSame)
                                        HStack(spacing: 4) {
                                            if isWinner {
                                                Image(systemName: "trophy.fill")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.yellow)
                                            }
                                            Text(sc.playerName)
                                                .fontWeight(isWinner ? .bold : .regular)
                                            let unit = scoreManager.matchesGameName(game.gameName, "Crockinole") ? "sets" : "pt"
                                            Text("\(sc.score) \(unit)")
                                                .fontWeight(.bold)
                                                .foregroundColor(isWinner ? .green : .primary)
                                        }
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(isWinner ? Color.yellow.opacity(0.18) : Color(UIColor.tertiarySystemGroupedBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(isWinner ? Color.yellow.opacity(0.4) : Color.clear, lineWidth: 1)
                                        )
                                        .cornerRadius(6)
                                    }
                                }
                            }

                            if let crok = game.crokinoleStats {
                                HStack(spacing: 8) {
                                    if crok.maxRoundScore > 0 {
                                        HStack(spacing: 3) {
                                            Text("🎯 Max ronde:")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text("\(crok.maxRoundScore) pt")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    if crok.maxSetScore > 0 {
                                        HStack(spacing: 3) {
                                            Text("🏆 Max set:")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text("\(crok.maxSetScore) pt")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 2)
                            }

                            // Uitklapknop voor scoreverloop
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        if expandedSessionIds.contains(game.id) {
                                            expandedSessionIds.remove(game.id)
                                        } else {
                                            expandedSessionIds.insert(game.id)
                                        }
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chart.xyaxis.line")
                                        Text(expandedSessionIds.contains(game.id) ? "Verberg verloop" : "Toon scoreverloop")
                                    }
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }

                            if expandedSessionIds.contains(game.id) {
                                ScoreProgressionChartView(
                                    title: "\(game.sessionTitle)",
                                    dataPoints: game.effectiveScoreProgression,
                                    playerNames: game.playerNamesList
                                )
                                .padding(.top, 4)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(10)
                        .background(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.6))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private func gameScoreProgressionCard(recent: [PlayedGame], gameName: String) -> some View {
        let sessionsWithData = recent.filter { $0.scoreProgression != nil && !$0.scoreProgression!.isEmpty }
        let displaySessions = !sessionsWithData.isEmpty ? sessionsWithData : recent

        guard let firstSession = displaySessions.first else {
            return AnyView(EmptyView())
        }

        let activeSession = displaySessions.first(where: { $0.id == selectedScoreProgressionSessionId }) ?? firstSession

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(gameColor(for: gameName))
                    Text("Scoreverloop \(gameName)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(displaySessions.count) potje\(displaySessions.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Sessie selector chips als er meer dan 1 potje is
                if displaySessions.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(displaySessions.prefix(5).enumerated()), id: \.element.id) { idx, session in
                                let isSel = session.id == activeSession.id
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedScoreProgressionSessionId = session.id
                                }) {
                                    HStack(spacing: 6) {
                                        Text(idx == 0 ? "Laatste potje" : "Potje \(idx + 1)")
                                            .font(.caption)
                                            .fontWeight(isSel ? .bold : .medium)
                                        Text("• \(session.winner.isEmpty ? "Gelijkspel" : session.winner)")
                                            .font(.caption2)
                                            .foregroundColor(isSel ? .white.opacity(0.9) : .secondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isSel ? gameColor(for: gameName) : Color(UIColor.tertiarySystemGroupedBackground))
                                    .foregroundColor(isSel ? .white : .primary)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Scoreverloop grafiek
                ScoreProgressionChartView(
                    title: "\(activeSession.sessionTitle)",
                    dataPoints: activeSession.effectiveScoreProgression,
                    playerNames: activeSession.playerNamesList
                )

                // Eindstand overzicht van deze geselecteerde sessie
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(activeSession.scores) { sc in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(sc.isWinner ? Color.green : gameColor(for: gameName))
                                    .frame(width: 8, height: 8)
                                Text(sc.playerName)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                Text("\(sc.score) \(gameName.localizedCaseInsensitiveContains("regenworm") ? "🪱" : "pt")")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(sc.isWinner ? .green : .secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(6)
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }

    private func gameEmptyStateView(gameName: String) -> some View {
        VStack(spacing: 16) {
            gameHeroIcon(for: gameName, size: 70)
                .padding(.top, 8)

            Text("Nog Geen \(gameName) Gespeeld")
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Speel je eerste potje \(gameName) om de ranglijst, topscores, persoonlijke records en geschiedenis te ontgrendelen!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            NavigationLink(destination: destinationSetupView(for: gameName)) {
                HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.headline)
                    Text("Start \(gameName)")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(gameColor(for: gameName))
                .cornerRadius(12)
                .shadow(color: gameColor(for: gameName).opacity(0.35), radius: 6, x: 0, y: 3)
            }
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    @ViewBuilder
    private func gameThumbnail(for gameName: String, size: CGFloat = 20) -> some View {
        let assetName = allAppGames.first(where: { scoreManager.matchesGameName($0.name, gameName) })?.assetName ?? gameName
        if let actualName = resolveImageName(for: assetName) {
            Image(actualName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
        } else {
            Image(systemName: gameIcon(for: gameName))
                .font(.system(size: size * 0.65))
                .foregroundColor(gameColor(for: gameName))
                .frame(width: size, height: size)
        }
    }

    @ViewBuilder
    private func gameHeroIcon(for gameName: String, size: CGFloat = 64) -> some View {
        let assetName = allAppGames.first(where: { scoreManager.matchesGameName($0.name, gameName) })?.assetName ?? gameName
        if let actualName = resolveImageName(for: assetName) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                Image(actualName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: size, maxHeight: size)
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(gameColor(for: gameName).opacity(0.15))
                    .frame(width: size, height: size)
                Image(systemName: gameIcon(for: gameName))
                    .font(.system(size: size * 0.5))
                    .foregroundColor(gameColor(for: gameName))
            }
            .shadow(color: gameColor(for: gameName).opacity(0.2), radius: 6, x: 0, y: 3)
        }
    }

    @ViewBuilder
    private func destinationSetupView(for gameName: String) -> some View {
        let lower = gameName.lowercased()
        if lower.contains("nmbr9") {
            Nmbr9DetailView()
        } else if lower.contains("beverbende") {
            BeverbendeSetupView()
        } else if lower.contains("duizenden") {
            DuizendenSetupView()
        } else if lower.contains("crok") {
            CrockinoleSetupView()
        } else if lower.contains("regenwormen") {
            RegenwormenSetupView()
        } else if lower.contains("jatten") {
            JattenSetupView()
        } else if lower.contains("balzakken") {
            BalzakkenSetupView()
        } else if lower.contains("love") {
            LoveLetterSetupView()
        } else if lower.contains("qwixx") {
            QwixxSetupView()
        } else if lower.contains("pig") {
            PigHoleSetupView()
        } else if lower.contains("ticket") {
            TicketToRideSetupView()
        } else if lower.contains("quick") {
            QuickstopSetupView()
        } else if lower.contains("30") || lower.contains("thirty") {
            ThirtySecondsSetupView()
        } else if lower.contains("cranium") {
            CraniumSetupView()
        } else {
            ContentView()
        }
    }

    private func resolveImageName(for assetName: String) -> String? {
        if UIImage(named: assetName) != nil { return assetName }
        let stripped = assetName.replacingOccurrences(of: " ", with: "")
        if UIImage(named: stripped) != nil { return stripped }
        if assetName.caseInsensitiveCompare("nmbr9") == .orderedSame {
            if UIImage(named: "Nmbr9") != nil { return "Nmbr9" }
        }
        if assetName.caseInsensitiveCompare("loveletter") == .orderedSame || assetName.caseInsensitiveCompare("love letter") == .orderedSame {
            if UIImage(named: "LoveLetter") != nil { return "LoveLetter" }
        }
        if assetName.caseInsensitiveCompare("qwixx") == .orderedSame {
            if UIImage(named: "Qwixx") != nil { return "Qwixx" }
        }
        if assetName.caseInsensitiveCompare("pighole") == .orderedSame || assetName.caseInsensitiveCompare("pig hole") == .orderedSame {
            if UIImage(named: "PigHole") != nil { return "PigHole" }
        }
        if assetName.caseInsensitiveCompare("tickettoride") == .orderedSame || assetName.caseInsensitiveCompare("ticket to ride") == .orderedSame {
            if UIImage(named: "TicketToRide") != nil { return "TicketToRide" }
        }
        if assetName.caseInsensitiveCompare("quickstop") == .orderedSame || assetName.caseInsensitiveCompare("quick stop") == .orderedSame {
            if UIImage(named: "Quickstop") != nil { return "Quickstop" }
        }
        return nil
    }

    // MARK: - 5. TEAMS & DUO'S

    private var teamGameFilterBar: some View {
        let teamGames = ["Alle Spellen", "30 Seconds", "Cranium", "Crockinole"]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(teamGames, id: \.self) { g in
                    let isSelected = selectedTeamGameFilter == g
                    let color = g == "Alle Spellen" ? Color.indigo : gameColor(for: g)
                    Button(action: {
                        HapticManager.shared.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTeamGameFilter = g
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
            .padding(.vertical, 2)
            .padding(.horizontal, 2)
        }
    }

    private var teamsSection: some View {
        VStack(spacing: 20) {
            teamGameFilterBar

            let teamStats = scoreManager.teamLeaderboard(gameFilter: selectedTeamGameFilter)
            let teamPlayers = scoreManager.allPlayersWithTeamHistory()

            if teamStats.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue.opacity(0.8))
                        .padding(.top, 20)

                    Text("Nog Geen Teamwedstrijden")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(selectedTeamGameFilter == "Alle Spellen"
                         ? "Speel een teamwedstrijd bij 30 Seconds, Cranium of Crokinole om duo-statistieken, partnerchemie en de teamranglijst te ontgrendelen!"
                         : "Nog geen gespeelde potjes voor \(selectedTeamGameFilter) gevonden.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(spacing: 10) {
                        NavigationLink(destination: ThirtySecondsSetupView()) {
                            HStack {
                                Image(systemName: "timer")
                                Text("Start 30 Seconds")
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                        }

                        NavigationLink(destination: CraniumSetupView()) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                Text("Start Cranium")
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                        }

                        NavigationLink(destination: CrockinoleSetupView()) {
                            HStack {
                                Image(systemName: "circle.circle.fill")
                                Text("Start Crokinole")
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
            } else {
                // 1. Gouden Dream Team Banner (Beste Duo)
                if let bestDuo = teamStats.first {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.title2)
                            Text("DREAM TEAM VAN DE APP")
                                .font(.caption)
                                .fontWeight(.heavy)
                                .foregroundColor(.orange)
                            Spacer()
                            Text("Beste Duo")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.yellow.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(6)
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(bestDuo.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Spelers: \(bestDuo.playerNames.joined(separator: " & "))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(String(format: "%.0f%%", bestDuo.winRate))")
                                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                                    .foregroundColor(.blue)
                                Text("Winstpercentage")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.yellow)
                                Text("\(bestDuo.won)x gewonnen")
                                    .fontWeight(.semibold)
                            }
                            .font(.caption)

                            Text("•")
                                .foregroundColor(.secondary)

                            HStack(spacing: 4) {
                                Image(systemName: "gamecontroller.fill")
                                    .foregroundColor(.blue)
                                Text("\(bestDuo.played) potjes totaal")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.18), Color.blue.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow.opacity(0.4), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                }

                // 2. Partner Chemie ("Met wie speel jij het beste?")
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("Partner Chemie")
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    Text("Kies een speler om te zien met welke medespeler hij of zij de hoogste winstkans heeft:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Horizontale scrollbare spelers-knoppen
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(teamPlayers, id: \.self) { pName in
                                let isSelected = (selectedPartnerPlayer == pName || (selectedPartnerPlayer.isEmpty && pName == teamPlayers.first))
                                Button(action: {
                                    selectedPartnerPlayer = pName
                                }) {
                                    Text(pName)
                                        .font(.subheadline)
                                        .fontWeight(isSelected ? .bold : .medium)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? Color.purple : Color(UIColor.tertiarySystemGroupedBackground))
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    // Toon resultaten voor geselecteerde speler
                    let activePlayer = selectedPartnerPlayer.isEmpty ? (teamPlayers.first ?? "") : selectedPartnerPlayer
                    let partners = scoreManager.bestPartners(for: activePlayer)

                    if partners.isEmpty {
                        Text("Geen partnergeschiedenis gevonden voor \(activePlayer).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(partners) { part in
                                partnerCard(player: activePlayer, partner: part)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)

                // 3. Alle Teams Ranglijst (Leaderboard)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "list.number")
                            .foregroundColor(.blue)
                        Text("Duo Ranglijst")
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    ForEach(Array(teamStats.enumerated()), id: \.element.id) { index, team in
                        HStack(spacing: 12) {
                            // Rang / medaille
                            ZStack {
                                Circle()
                                    .fill(rankColor(for: index).opacity(0.15))
                                    .frame(width: 34, height: 34)

                                if index == 0 {
                                    Text("🥇").font(.subheadline)
                                } else if index == 1 {
                                    Text("🥈").font(.subheadline)
                                } else if index == 2 {
                                    Text("🥉").font(.subheadline)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(team.displayName)
                                    .font(.headline)
                                Text(team.playerNames.joined(separator: " & "))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(String(format: "%.0f%%", team.winRate)) win")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(team.winRate >= 50 ? .green : .secondary)

                                Text("\(team.won)W - \(team.played - team.won)V")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)

                        if index < teamStats.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
            }
        }
    }

    private func partnerCard(player: String, partner: PartnerSynergyStat) -> some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.purple)
                    Text(partner.partnerName)
                        .font(.headline)
                }

                Spacer()

                synergyBadge(winRate: partner.winRate)
            }

            ProgressView(value: partner.winRate, total: 100.0)
                .tint(synergyColor(winRate: partner.winRate))

            HStack {
                Text("\(partner.winsTogether) van de \(partner.gamesTogether) potjes gewonnen")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(String(format: "%.0f%%", partner.winRate)) winst")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(synergyColor(winRate: partner.winRate))
            }
        }
        .padding(12)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func synergyBadge(winRate: Double) -> some View {
        let (label, color, icon): (String, Color, String) = {
            if winRate >= 75 {
                return ("Onverslaanbaar", .green, "crown.fill")
            } else if winRate >= 50 {
                return ("Gouden Duo", .blue, "star.fill")
            } else {
                return ("Uitdaging", .orange, "flame")
            }
        }()

        return HStack(spacing: 4) {
            Image(systemName: icon)
            Text(label)
        }
        .font(.system(size: 10, weight: .bold))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(6)
    }

    private func synergyColor(winRate: Double) -> Color {
        if winRate >= 60 { return .green }
        if winRate >= 45 { return .blue }
        return .orange
    }

    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .brown
        default: return .blue
        }
    }

    private func highlightTile(title: String, player: String, stat: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            Text(player)
                .font(.headline)
                .lineLimit(1)
            Text(stat)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
    }

    private func emptyStateCard(text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.title)
                .foregroundColor(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Moderne Spel Filter Balk (Rivaliteiten)

    private var gameFilterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .foregroundColor(.orange)
                    .font(.subheadline)

                Text("Filter op Spel")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if selectedGameFilter != "Alle Spellen" {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedGameFilter = "Alle Spellen"
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Wis filter")
                        }
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    }
                }
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableGames, id: \.self) { g in
                        let isSelected = selectedGameFilter == g
                        let color = g == "Alle Spellen" ? Color.orange : gameColor(for: g)

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
                .padding(.vertical, 2)
                .padding(.horizontal, 2)
            }
        }
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
        case "Qwixx": return "dice.fill"
        case "Pig Hole": return "circle.circle.fill"
        case "Ticket to Ride": return "tram.fill"
        case "Quickstop": return "bolt.fill"
        case "30 Seconds": return "timer"
        case "Cranium": return "brain.head.profile"
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
        case "Qwixx": return .orange
        case "Pig Hole": return .pink
        case "Ticket to Ride": return .blue
        case "Quickstop": return .yellow
        case "30 Seconds": return .orange
        case "Cranium": return .purple
        default: return .teal
        }
    }

    private func bestScore(for gameName: String, in scores: [Score]) -> Score? {
        let isLowestWins = scoreManager.isLowestScoreWins(for: gameName)
        if isLowestWins {
            return scores.min(by: { $0.score < $1.score })
        } else {
            return scores.max(by: { $0.score < $1.score })
        }
    }
}

#Preview {
    StatisticsView()
}
