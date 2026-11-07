import SwiftUI

// MARK: - Risk Modellen & Kleuren

enum RiskArmyColor: String, CaseIterable, Identifiable {
    case red = "Rood"
    case blue = "Blauw"
    case yellow = "Geel"
    case green = "Groen"
    case black = "Zwart"
    case purple = "Paars"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red: return Color(red: 0.90, green: 0.22, blue: 0.27)
        case .blue: return Color(red: 0.11, green: 0.45, blue: 0.78)
        case .yellow: return Color(red: 0.94, green: 0.72, blue: 0.20)
        case .green: return Color(red: 0.16, green: 0.62, blue: 0.38)
        case .black: return Color(red: 0.18, green: 0.20, blue: 0.24)
        case .purple: return Color(red: 0.55, green: 0.24, blue: 0.78)
        }
    }

    var textColor: Color {
        switch self {
        case .yellow: return .black
        default: return .white
        }
    }
}

enum RiskGameMode: String, CaseIterable, Identifiable {
    case secretMissions = "Geheime Missies"
    case worldDomination = "Wereldheerschappij"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .secretMissions:
            return "Iedere speler krijgt een geheime opdracht. Wie als eerste zijn doel voltooit, wint direct!"
        case .worldDomination:
            return "Verover alle 42 gebieden en schakel alle tegenstanders uit voor de ultieme overwinning."
        }
    }
}

struct RiskPlayerSetup: Identifiable {
    var id: UUID = UUID()
    var name: String
    var armyColor: RiskArmyColor
}

// MARK: - Risk Setup View

struct RiskSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedNames: [String] = []
    @State private var playerColors: [RiskArmyColor] = [.red, .blue, .yellow, .green, .black, .purple]
    @State private var gameMode: RiskGameMode = .secretMissions
    @State private var progressiveCards: Bool = true
    @State private var newPlayerName: String = ""
    @State private var showNamePicker: Bool = false
    @State private var navigateToGame: Bool = false

    private let availableColors = RiskArmyColor.allCases

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Banner
                headerCard

                // Spelers en Legers Sectie
                playersSection

                // Spelregels & Modus
                gameSettingsSection

                // Start Knop
                startButton
            }
            .padding()
        }
        .navigationTitle("Risk Setup")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToGame) {
            RiskGameView(
                players: buildPlayers(),
                gameMode: gameMode,
                progressiveCards: progressiveCards
            )
        }
        .onAppear {
            initDefaultPlayers()
        }
    }

    // MARK: - Header
    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)

                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Risk Assistent")
                    .font(.title3.bold())
                Text("Stel 2 tot 6 spelers en legers in voor gevechten, versterkingen en geheime missies.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Spelers Lijst
    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Spelers & Legerkleuren", systemImage: "person.3.fill")
                    .font(.headline)
                Spacer()
                Text("\(selectedNames.count)/6 spelers")
                    .font(.caption.bold())
                    .foregroundColor(selectedNames.count >= 2 ? .green : .orange)
            }

            ForEach(selectedNames.indices, id: \.self) { idx in
                HStack(spacing: 12) {
                    // Positie badge
                    Text("\(idx + 1)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    // Spelersnaam
                    Text(selectedNames[idx])
                        .font(.subheadline.bold())
                        .lineLimit(1)

                    Spacer()

                    // Kleur Kiezer
                    Menu {
                        ForEach(availableColors) { col in
                            Button {
                                playerColors[idx] = col
                            } label: {
                                HStack {
                                    Text(col.rawValue)
                                    if playerColors[idx] == col {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(playerColors[idx].color)
                                .frame(width: 16, height: 16)
                            Text(playerColors[idx].rawValue)
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(playerColors[idx].color.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    // Verwijder knop
                    if selectedNames.count > 2 {
                        Button {
                            withAnimation {
                                if idx < selectedNames.count {
                                    _ = selectedNames.remove(at: idx)
                                }
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 18))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }

            // Nieuwe Speler Toevoegen
            if selectedNames.count < 6 {
                HStack(spacing: 10) {
                    TextField("Nieuwe spelersnaam...", text: $newPlayerName)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)

                    Button {
                        let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty && !selectedNames.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                            withAnimation {
                                selectedNames.append(trimmed)
                                newPlayerName = ""
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    .disabled(newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                // Bekende spelers snelle selectie
                let knownUnselected = scoreManager.fetchPlayerNames().filter { name in
                    !selectedNames.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame })
                }

                if !knownUnselected.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Snel toevoegen:")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(knownUnselected.prefix(8), id: \.self) { name in
                                    Button {
                                        withAnimation {
                                            selectedNames.append(name)
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 10))
                                            Text(name)
                                                .font(.caption.bold())
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Spelinstellingen
    private var gameSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Spelmodus & Regels", systemImage: "gearshape.fill")
                .font(.headline)

            Picker("Spelmodus", selection: $gameMode) {
                ForEach(RiskGameMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(gameMode.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            Divider()

            Toggle(isOn: $progressiveCards) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Oplopende Kaartensets")
                        .font(.subheadline.bold())
                    Text(progressiveCards ? "4, 6, 8, 10, 12, 15, 20... legers per set" : "Vaste waarde (4, 6, 8 of 10 legers)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Start Knop
    private var startButton: some View {
        Button {
            navigateToGame = true
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Risk Assistent")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                selectedNames.count >= 2
                    ? LinearGradient(colors: [Color.red, Color(red: 0.8, green: 0.1, blue: 0.2)], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [Color.gray, Color.gray.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(.white)
            .cornerRadius(14)
            .shadow(color: selectedNames.count >= 2 ? Color.red.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .disabled(selectedNames.count < 2)
    }

    private func initDefaultPlayers() {
        if selectedNames.isEmpty {
            let saved = scoreManager.fetchPlayerNames()
            if saved.count >= 2 {
                selectedNames = Array(saved.prefix(3))
            } else {
                selectedNames = ["Speler 1", "Speler 2", "Speler 3"]
            }
        }
    }

    private func buildPlayers() -> [RiskPlayer] {
        var result: [RiskPlayer] = []
        for i in selectedNames.indices {
            let col = playerColors[i % playerColors.count]
            result.append(
                RiskPlayer(
                    name: selectedNames[i],
                    armyColor: col,
                    mission: nil
                )
            )
        }
        return result
    }
}
