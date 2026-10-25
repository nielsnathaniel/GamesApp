import SwiftUI

enum TTRColor: String, CaseIterable, Identifiable, Codable {
    case rood = "Rood"
    case blauw = "Blauw"
    case groen = "Groen"
    case geel = "Geel"
    case zwart = "Zwart"
    case paars = "Paars"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .rood: return Color.red
        case .blauw: return Color.blue
        case .groen: return Color.green
        case .geel: return Color(red: 0.95, green: 0.72, blue: 0.05)
        case .zwart: return Color(white: 0.22)
        case .paars: return Color.purple
        }
    }

    var lightBgColor: Color {
        switch self {
        case .rood: return Color.red.opacity(0.12)
        case .blauw: return Color.blue.opacity(0.12)
        case .groen: return Color.green.opacity(0.12)
        case .geel: return Color.yellow.opacity(0.18)
        case .zwart: return Color.gray.opacity(0.18)
        case .paars: return Color.purple.opacity(0.12)
        }
    }

    var onColorTextColor: Color {
        return self == .geel ? .black : .white
    }
}

struct TicketToRideSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var aantalSpelers: Int = 4
    @State private var spelers: [String] = Array(repeating: "", count: 5)
    @State private var playerColors: [TTRColor] = [.rood, .blauw, .groen, .geel, .zwart]
    @State private var startModus: TTRScoreMode = .categorieen

    enum TTRScoreMode: String, CaseIterable, Identifiable {
        case categorieen = "Categorieën (Eindtelling)"
        case liveRondes = "Ronde per Ronde (Live)"
        case direct = "Direct Totaal Invullen"

        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    if UIImage(named: "TicketToRide") != nil {
                        Image("TicketToRide")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Image(systemName: "tram.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ticket to Ride")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Treinavontuur • Europa & USA")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .center)

                // Kies aantal spelers (2 t/m 5)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aantal Spelers")
                        .font(.headline)
                        .padding(.horizontal)

                    HStack(spacing: 10) {
                        ForEach(2...5, id: \.self) { number in
                            Button(action: {
                                aantalSpelers = number
                            }) {
                                Text("\(number)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(aantalSpelers == number ? .white : .blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(aantalSpelers == number ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Invoermodus
                VStack(alignment: .leading, spacing: 8) {
                    Text("Puntentelling Voorkeur")
                        .font(.headline)
                        .padding(.horizontal)

                    Picker("Invoermodus", selection: $startModus) {
                        ForEach(TTRScoreMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    modeDescriptionText
                }

                // Opgeslagen Spelers Quick Chips
                SavedPlayersQuickChipsView(
                    spelers: $spelers,
                    aantalSpelers: aantalSpelers,
                    tintColor: .blue
                )

                // Invoervelden voor spelersnamen & treinkleuren
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Spelers & Treinkleuren")
                            .font(.headline)
                        Spacer()
                        Text("Kies je treinkleur")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        ForEach(0..<aantalSpelers, id: \.self) { index in
                            playerRow(at: index)
                        }
                    }
                }

                Spacer(minLength: 16)

                // Start Spel knop
                NavigationLink(
                    destination: TicketToRideGameView(
                        spelers: Array(spelers.prefix(aantalSpelers).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }),
                        initialMode: startModus,
                        playerColors: Array(playerColors.prefix(aantalSpelers))
                    )
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start Spel")
                    }
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(color: Color.blue.opacity(0.35), radius: 5, x: 0, y: 3)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    scoreManager.savePlayerNames(spelers.prefix(aantalSpelers).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
                })
                .padding(.horizontal)
                .disabled(spelers.prefix(aantalSpelers).contains(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty }))
            }
            .padding(.vertical)
        }
        .navigationTitle("Ticket to Ride")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scoreManager.refresh()
        }
    }

    private func playerRow(at index: Int) -> some View {
        HStack(spacing: 8) {
            PlayerNameInputField(
                placeholder: "Naam Speler \(index + 1)",
                text: $spelers[index],
                suggestions: scoreManager.savedPlayerNames,
                submitLabel: index < aantalSpelers - 1 ? .next : .done
            )

            colorPickerMenu(for: index)
        }
        .padding(.horizontal)
    }

    private func colorPickerMenu(for index: Int) -> some View {
        let currentColor = playerColors[index]

        return Menu {
            ForEach(TTRColor.allCases) { c in
                Button {
                    playerColors[index] = c
                } label: {
                    HStack {
                        Circle().fill(c.color).frame(width: 12, height: 12)
                        Text(c.rawValue)
                        if currentColor == c {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(currentColor.color)
                    .frame(width: 14, height: 14)
                Text(currentColor.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(currentColor == .zwart ? .primary : currentColor.color)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .background(currentColor.lightBgColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(currentColor.color.opacity(0.35), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var modeDescriptionText: some View {
        switch startModus {
        case .categorieen:
            Text("Achteraf per speler routepunten, voltooide tickets, mislukte tickets, bonussen en stations invullen.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        case .liveRondes:
            Text("Tijdens het bordspel beurt voor beurt live gelegde routes invoeren in je eigen treinkleur. Na afloop vul je direct de tickets en bonussen in.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        case .direct:
            Text("Snel en direct de uiteindelijke totaalscores per speler intypen met het cijfertoetsenbord.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
}

#Preview {
    NavigationStack {
        TicketToRideSetupView()
    }
}
