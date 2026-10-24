import SwiftUI

enum GameSortOption: String, CaseIterable, Identifiable {
    case populair = "Populair"
    case toegevoegd = "Toegevoegd"
    case alfabetisch = "Alfabetisch"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .populair: return "flame.fill"
        case .toegevoegd: return "clock.arrow.circlepath"
        case .alfabetisch: return "textformat.abc"
        }
    }

    var iconColor: Color {
        switch self {
        case .populair: return .orange
        case .toegevoegd: return .blue
        case .alfabetisch: return .purple
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @AppStorage("game_sort_option") private var sortOption: GameSortOption = .toegevoegd
    @ObservedObject private var scoreManager = ScoreManager.shared
    @Namespace private var sortNamespace

    let games = [
        ("Nmbr9", "Nmbr9"),
        ("Beverbende", "Beverbende"),
        ("Duizenden", "Duizenden"),
        ("Crockinole", "Crockinole"),
        ("Regenwormen", "Regenwormen"),
        ("Jatten", "Jatten"),
        ("Balzakken", "Balzakken")
    ]

    private func playCount(for gameName: String) -> Int {
        scoreManager.playedGames.filter { played in
            let n1 = played.gameName.lowercased()
            let n2 = gameName.lowercased()
            if n1 == n2 { return true }
            if (n1.contains("crok") || n1.contains("crokinole")) && (n2.contains("crok") || n2.contains("crokinole")) {
                return true
            }
            return false
        }.count
    }

    private var sortedGames: [(String, String)] {
        switch sortOption {
        case .populair:
            return games.sorted { g1, g2 in
                let c1 = playCount(for: g1.0)
                let c2 = playCount(for: g2.0)
                if c1 != c2 {
                    return c1 > c2
                }
                guard let i1 = games.firstIndex(where: { $0.0 == g1.0 }),
                      let i2 = games.firstIndex(where: { $0.0 == g2.0 }) else { return false }
                return i1 < i2
            }
        case .toegevoegd:
            return games
        case .alfabetisch:
            return games.sorted { $0.0.localizedCaseInsensitiveCompare($1.0) == .orderedAscending }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            gameSelectionView
                .tabItem {
                    Label("Spellen", systemImage: "gamecontroller")
                }
                .tag(0)

            StatisticsView()
                .tabItem {
                    Label("Statistieken", systemImage: "chart.bar.xaxis")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Instellingen", systemImage: "gearshape")
                }
                .tag(2)
        }
    }

    private var gameSelectionView: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Moderne Sorteer / Filter balk
                sortFilterBar

                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                        ForEach(sortedGames, id: \.0) { game in
                            NavigationLink(destination: destinationView(for: game.0)) {
                                VStack(spacing: 8) {
                                    ZStack(alignment: .topTrailing) {
                                        gameIcon(for: game.0, assetName: game.1)

                                        if sortOption == .populair {
                                            let count = playCount(for: game.0)
                                            HStack(spacing: 2) {
                                                Image(systemName: "flame.fill")
                                                    .font(.system(size: 8))
                                                Text("\(count)x")
                                                    .font(.system(size: 10, weight: .bold))
                                            }
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(count > 0 ? Color.orange : Color.gray.opacity(0.5))
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                            .offset(x: 10, y: -6)
                                        }
                                    }

                                    VStack(spacing: 2) {
                                        Text(game.0)
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        if sortOption == .populair {
                                            let count = playCount(for: game.0)
                                            Text(count == 1 ? "1x gespeeld" : "\(count)x gespeeld")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.top, 2)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 4)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Spellen")
            .onAppear {
                scoreManager.refresh()
            }
        }
    }

    // MARK: - Moderne Sorteer / Filter Balk

    private var sortFilterBar: some View {
        HStack(spacing: 4) {
            ForEach(GameSortOption.allCases) { option in
                let isSelected = sortOption == option

                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        sortOption = option
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: option.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isSelected ? option.iconColor : .secondary)

                        Text(option.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemBackground))
                                .matchedGeometryEffect(id: "activeSortPill", in: sortNamespace)
                                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 1.5)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private func gameIcon(for gameName: String, assetName: String) -> some View {
        if UIImage(named: assetName) != nil {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .frame(width: 80, height: 80)

                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .frame(width: 80, height: 80)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        } else {
            // Aantrekkelijke SF Symbol fallback voor games zonder asset image
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(gameIconColor(for: gameName).opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: gameIconSymbol(for: gameName))
                    .font(.system(size: 38))
                    .foregroundColor(gameIconColor(for: gameName))
            }
        }
    }

    private func gameIconSymbol(for gameName: String) -> String {
        switch gameName {
        case "Crockinole": return "circle.circle.fill"
        case "Regenwormen": return "circle.hexagongrid.fill"
        case "Jatten": return "hand.raised.fill"
        case "Balzakken": return "flame.fill"
        default: return "gamecontroller.fill"
        }
    }

    private func gameIconColor(for gameName: String) -> Color {
        switch gameName {
        case "Crockinole": return .blue
        case "Regenwormen": return .orange
        case "Jatten": return .purple
        case "Balzakken": return .red
        default: return .green
        }
    }

    @ViewBuilder
    private func destinationView(for gameName: String) -> some View {
        switch gameName {
        case "Nmbr9":
            Nmbr9DetailView()
        case "Beverbende":
            BeverbendeSetupView()
        case "Duizenden":
            DuizendenSetupView()
        case "Crockinole":
            CrockinoleSetupView()
        case "Regenwormen":
            RegenwormenSetupView()
        case "Jatten":
            JattenSetupView()
        case "Balzakken":
            BalzakkenSetupView()
        default:
            Text("Onbekend Spel")
        }
    }
}

#Preview {
    ContentView()
}
