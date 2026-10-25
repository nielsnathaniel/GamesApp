import SwiftUI

struct PlayerStatsView: View {
    var playerName: String
    @ObservedObject private var scoreManager = ScoreManager.shared

    var body: some View {
        let stats = scoreManager.detailedStats(for: playerName)
        let opponents = scoreManager.fetchPlayerNames().filter { $0.caseInsensitiveCompare(playerName) != .orderedSame }
        let streaks = scoreManager.playerWinStreak(for: playerName)
        let badges = scoreManager.playerBadges(for: playerName)

        List {
            // Header kaart
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)

                    Text(playerName)
                        .font(.title)
                        .fontWeight(.bold)

                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("\(stats.totalGames)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Gespeeld")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Divider()
                            .frame(height: 26)

                        VStack(spacing: 2) {
                            Text("\(stats.totalWins)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Gewonnen")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Divider()
                            .frame(height: 26)

                        VStack(spacing: 2) {
                            Text(String(format: "%.0f%%", stats.winRate))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Winstkans")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Divider()
                            .frame(height: 26)

                        VStack(spacing: 2) {
                            HStack(spacing: 2) {
                                Text("\(streaks.current)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(streaks.current > 0 ? .orange : .secondary)
                                if streaks.current > 0 {
                                    Text("🔥")
                                        .font(.caption2)
                                }
                            }
                            Text(streaks.best > streaks.current ? "Reeks (Max \(streaks.best))" : "Reeks")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // Badges & Prestaties
            if !badges.isEmpty {
                Section(header: Text("Badges & Prestaties")) {
                    ForEach(badges) { badge in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(badge.color.opacity(0.15))
                                    .frame(width: 38, height: 38)
                                Image(systemName: badge.icon)
                                    .foregroundColor(badge.color)
                                    .font(.system(size: 18))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(badge.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(badge.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
            }

            // Prestaties per spel
            Section(header: Text("Prestaties per Spel")) {
                if stats.statsPerGame.isEmpty {
                    Text("Nog geen spelstatistieken voor \(playerName).")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(stats.statsPerGame) { gStat in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(gStat.gameName)
                                    .font(.headline)
                                Spacer()
                                Text("\(gStat.won) van de \(gStat.played) gewonnen")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(gStat.won > 0 ? .green : .secondary)
                            }

                            HStack {
                                Text("Winstpercentage: \(String(format: "%.0f%%", gStat.winRate))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if let best = gStat.bestScore {
                                    Text("Beste score: \(best) pt")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Head-to-Head tegen medespelers
            Section(header: Text("Onderlinge Strijd (Wie wint van wie?)")) {
                let rivalries = opponents.compactMap { opp -> HeadToHeadRecord? in
                    let rec = scoreManager.headToHead(playerA: playerName, playerB: opp)
                    return rec.totalGames > 0 ? rec : nil
                }.sorted { $0.totalGames > $1.totalGames }

                if rivalries.isEmpty {
                    Text("Nog geen onderlinge potjes tegen andere spelers geregistreerd.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(rivalries) { h2h in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("vs \(h2h.playerB)")
                                    .font(.headline)
                                Spacer()
                                Text("\(h2h.winsA) - \(h2h.winsB)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(h2h.winsA > h2h.winsB ? .green : (h2h.winsA < h2h.winsB ? .red : .orange))
                            }

                            HStack {
                                Text("\(h2h.totalGames) potjes samen gespeeld")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(h2h.leaderSummary)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Beste Team Partners
            let partners = scoreManager.bestPartners(for: playerName)
            if !partners.isEmpty {
                Section(header: Text("Team Partners 🤝")) {
                    ForEach(partners) { part in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(part.partnerName)
                                    .font(.headline)
                                Text("\(part.winsTogether) van de \(part.gamesTogether) potjes gewonnen")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(String(format: "%.0f%%", part.winRate)) win")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(part.winRate >= 50 ? .green : .orange)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle(playerName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PlayerStatsView(playerName: "Speler 1")
}
