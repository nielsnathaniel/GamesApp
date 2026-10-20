import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    let games = [
        ("Nmbr9", "Nmbr9"),
        ("Beverbende", "Beverbende"),
        ("Duizenden", "Duizenden"),
        ("Crockinole", "Crockinole"),
        ("Regenwormen", "Regenwormen"),
        ("Jatten", "Jatten"),
        ("Balzakken", "Balzakken")
    ]

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
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                    ForEach(games, id: \.0) { game in
                        NavigationLink(destination: destinationView(for: game.0)) {
                            VStack {
                                gameIcon(for: game.0, assetName: game.1)
                                Text(game.0)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.top, 5)
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
            .navigationTitle("Spellen")
        }
    }

    @ViewBuilder
    private func gameIcon(for gameName: String, assetName: String) -> some View {
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
        } else {
            // Aantrekkelijke SF Symbol fallback voor games zonder asset image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(gameIconColor(for: gameName).opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: gameIconSymbol(for: gameName))
                    .font(.system(size: 40))
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
