import SwiftUI

/// Het officiële Spelerspaspoort:
/// Toont tafelkleur, avatar/foto, kern-inzichten (Aartsvijand, favoriet spel, beste spel),
/// badges/prestaties, statistieken per spel, en onderlinge head-to-head records.
struct PlayerStatsView: View {
    var playerName: String
    @ObservedObject private var scoreManager = ScoreManager.shared
    @State private var showProfileSheet: Bool = false

    var body: some View {
        let profile = scoreManager.profile(for: playerName)
        let stats = scoreManager.detailedStats(for: playerName)
        let opponents = scoreManager.fetchPlayerNames().filter { $0.caseInsensitiveCompare(playerName) != .orderedSame }
        let streaks = scoreManager.playerWinStreak(for: playerName)
        let badges = scoreManager.playerBadges(for: playerName)
        let nemesisInfo = scoreManager.nemesis(for: playerName)
        let favGame = scoreManager.favoriteGame(for: playerName)
        let bestG = scoreManager.bestGame(for: playerName)

        List {
            // MARK: - 1. Paspoort Hero Header Kaart
            Section {
                VStack(spacing: 14) {
                    // Avatar met bewerk-knop
                    Button(action: {
                        HapticManager.shared.light()
                        showProfileSheet = true
                    }) {
                        ZStack(alignment: .bottomTrailing) {
                            PlayerAvatarView(name: playerName, size: 84)

                            ZStack {
                                Circle()
                                    .fill(profile.color)
                                    .frame(width: 26, height: 26)
                                Image(systemName: "pencil")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 2, y: 2)
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                        }
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 4) {
                        Text(playerName)
                            .font(.title)
                            .fontWeight(.bold)

                        Button(action: {
                            showProfileSheet = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "paintpalette.fill")
                                    .font(.caption2)
                                Text("Tafelkleur & Avatar wijzigen")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(profile.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(profile.color.opacity(0.12))
                            .cornerRadius(12)
                        }
                    }

                    // Hoofdcijfers in 4 kolommen
                    HStack(spacing: 12) {
                        VStack(spacing: 2) {
                            Text("\(stats.totalGames)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Gespeeld")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(height: 24)

                        VStack(spacing: 2) {
                            Text("\(stats.totalWins)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Gewonnen")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(height: 24)

                        VStack(spacing: 2) {
                            Text(String(format: "%.0f%%", stats.winRate))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(profile.color)
                            Text("Winstkans")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(height: 24)

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
                            Text(streaks.best > streaks.current ? "Reeks (\(streaks.best))" : "Reeks")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // MARK: - 2. Spelerspaspoort Kern-Inzichten
            Section(header: Text("Paspoort Inzichten")) {
                // Aartsvijand (Angstgegner)
                if let nem = nemesisInfo {
                    HStack(spacing: 12) {
                        PlayerAvatarView(name: nem.opponent, size: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("😈 Aartsvijand:")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                Text(nem.opponent)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }

                            Text("\(nem.losses)x van verloren in \(nem.totalGames) potjes (\(String(format: "%.0f%%", nem.winRate)) winst)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 3)
                }

                // Favoriete Spel
                if let fav = favGame {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "heart.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 18))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Favoriete Spel")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text(fav.gameName)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        Text("\(fav.count)x gespeeld")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 3)
                }

                // Beste Spel (Hoogste winstkans)
                if let bg = bestG {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Beste Spel")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text(bg.gameName)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 1) {
                            Text(String(format: "%.0f%% win", bg.winRate))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("\(bg.wins) van de \(bg.played)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 3)
                }

                // Zegereeks Record
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Text("🔥")
                            .font(.system(size: 20))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Grootste Zegereeks")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text(streaks.best == 1 ? "1 overwinning" : "\(streaks.best) overwinningen op rij")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    if streaks.current > 0 {
                        Text("Nu: \(streaks.current) 🔥")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 3)
            }

            // MARK: - 3. Badges & Prestaties
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

            // MARK: - 4. Prestaties per Spel
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

            // MARK: - 5. Onderlinge Strijd (Wie wint van wie?)
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
                                HStack(spacing: 6) {
                                    PlayerAvatarView(name: h2h.playerB, size: 24, showBorder: false)
                                    Text("vs \(h2h.playerB)")
                                        .font(.headline)
                                }
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

            // MARK: - 6. Beste Team Partners
            let partners = scoreManager.bestPartners(for: playerName)
            if !partners.isEmpty {
                Section(header: Text("Team Partners 🤝")) {
                    ForEach(partners) { part in
                        HStack {
                            PlayerAvatarView(name: part.partnerName, size: 30)

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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    HapticManager.shared.light()
                    showProfileSheet = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(profile.color)
                }
            }
        }
        .sheet(isPresented: $showProfileSheet) {
            PlayerProfileEditSheet(playerName: playerName)
        }
    }
}

#Preview {
    NavigationStack {
        PlayerStatsView(playerName: "Speler 1")
    }
}
