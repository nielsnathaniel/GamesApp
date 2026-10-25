import SwiftUI

struct StatisticsView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @State private var selectedSegment: StatSegment = .overzicht
    @State private var selectedGameFilter: String = "Alle Spellen"
    @State private var selectedPartnerPlayer: String = ""
    @Namespace private var categoryAnimation

    enum StatSegment: String, CaseIterable, Identifiable {
        case overzicht = "Overzicht"
        case spelers = "Spelers"
        case teams = "Duo's"
        case rivaliteiten = "Wie wint?"
        case balzakken = "Balzakken"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overzicht: return "chart.pie.fill"
            case .spelers: return "crown.fill"
            case .teams: return "person.2.fill"
            case .rivaliteiten: return "bolt.fill"
            case .balzakken: return "flame.fill"
            }
        }

        var themeColor: Color {
            switch self {
            case .overzicht: return .blue
            case .spelers: return .purple
            case .teams: return .indigo
            case .rivaliteiten: return .orange
            case .balzakken: return .red
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
                        case .teams:
                            teamsSection
                        case .rivaliteiten:
                            rivalriesSection
                        case .balzakken:
                            balzakkenSpecialSection
                        }
                    }
                    .padding()
                    .animation(.easeInOut(duration: 0.2), value: selectedSegment)
                }
            }
            .navigationTitle("Statistieken")
            .toolbar {
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
            statCard(title: "Gespeeld", value: "\(totalGames)", icon: "gamecontroller.fill", color: .blue)
            statCard(title: "Spelers", value: "\(totalPlayers)", icon: "person.2.fill", color: .purple)
            statCard(title: "Populairst", value: favoriteGame, icon: "chart.line.uptrend.xyaxis", color: .orange)
            statCard(title: "Koploper", value: topWinner, icon: "crown.fill", color: .yellow)
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
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

            let rivalries = scoreManager.allRivalries(gameFilter: selectedGameFilter)
            if rivalries.isEmpty {
                emptyStateCard(text: "Geen onderlinge wedstrijden gevonden voor \(selectedGameFilter).")
            } else {
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

    // MARK: - 4. BALZAKKEN SPECIAAL (Juiste & Foute Balzakken)

    private var balzakkenSpecialSection: some View {
        VStack(spacing: 16) {
            // Header kaart
            HStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Balzakken Hall of Fame")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Juiste balzakken (0 pt) vs Foute balzakken (+25 pt)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)

            let leaderboard = scoreManager.balzakkenLeaderboard()

            if leaderboard.isEmpty {
                emptyStateCard(text: "Nog geen Balzakken potjes opgeslagen. Speel een potje Balzakken om deze statistieken te vullen!")
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
                VStack(alignment: .leading, spacing: 10) {
                    Text("Alle Balzakken Spelers")
                        .font(.headline)

                    ForEach(leaderboard) { stat in
                        HStack(spacing: 12) {
                            Text(stat.playerName)
                                .font(.headline)

                            Spacer()

                            // Juiste balzakken badge
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("\(stat.juisteBalzakken)")
                                    .fontWeight(.bold)
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.12))
                            .cornerRadius(8)

                            // Foute balzakken badge
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("\(stat.fouteBalzakken)")
                                    .fontWeight(.bold)
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(8)
                        }
                        .padding(.vertical, 4)

                        if stat.id != leaderboard.last?.id {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
        }
    }

    // MARK: - 5. TEAMS & DUO'S

    private var teamsSection: some View {
        VStack(spacing: 20) {
            let teamStats = scoreManager.teamLeaderboard()
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

                    Text("Speel een 2 tegen 2 wedstrijd bij Crokinole om duo-statistieken, partnerchemie en de teamranglijst te ontgrendelen!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    NavigationLink(destination: CrockinoleSetupView()) {
                        HStack {
                            Image(systemName: "circle.circle.fill")
                            Text("Start Crokinole Teamwedstrijd")
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
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
