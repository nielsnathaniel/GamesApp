import SwiftUI

enum FiftyFiftyGameMode: String, CaseIterable, Identifiable {
    case rondes = "Rondes & Slagen"
    case snelleTelling = "Snelle Telling"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .rondes: return "arrow.triangle.2.circlepath"
        case .snelleTelling: return "sum"
        }
    }
}

struct FiftyFiftySetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var aantalSpelers: Int = 4
    @State private var gameMode: FiftyFiftyGameMode = .rondes
    @State private var limietStrafpunten: Int = 15
    @State private var gebruikLimiet: Bool = false
    @State private var aantalRondesDoel: Int = 5
    @State private var spelers: [String] = Array(repeating: "", count: 6)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    if UIImage(named: "FiftyFifty") != nil {
                        Image("FiftyFifty")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 46, height: 46)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.yellow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 44, height: 44)

                            Image(systemName: "circle.lefthalf.filled")
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fifty Fifty")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Reiner Knizia • Winnen is verliezen... tenzij 50/50! ☀️🌙")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .center)

                // Uitleg Kaartje: De 50/50 regel
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Hoe werkt de puntentelling?")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }

                    Text("• Hoogste kaart = **Blauw fiche (☀️)** • Laagste kaart = **Geel fiche (🌙)**\n• **1 Blauw + 1 Geel heffen elkaar op!**\n• Wie de **minste strafpunten** overhoudt, wint het spel.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)

                // Spelmodus Kiezer
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spelmodus")
                        .font(.headline)
                        .padding(.horizontal)

                    Picker("Spelmodus", selection: $gameMode) {
                        ForEach(FiftyFiftyGameMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                // Aantal Spelers (2 t/m 6)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aantal Spelers")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                        ForEach(2...6, id: \.self) { number in
                            Button(action: {
                                HapticManager.shared.light()
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

                // Eindlimiet / Doel
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Spelen tot een strafpunt-limiet", isOn: $gebruikLimiet)
                        .font(.headline)
                        .padding(.horizontal)

                    if gebruikLimiet {
                        HStack(spacing: 8) {
                            Text("Limiet:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            ForEach([10, 15, 20, 25], id: \.self) { limit in
                                Button(action: {
                                    HapticManager.shared.light()
                                    limietStrafpunten = limit
                                }) {
                                    Text("\(limit) pnt")
                                        .font(.subheadline)
                                        .fontWeight(limietStrafpunten == limit ? .bold : .medium)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(limietStrafpunten == limit ? Color.blue.opacity(0.25) : Color(UIColor.secondarySystemGroupedBackground))
                                        .foregroundColor(limietStrafpunten == limit ? .blue : .primary)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(limietStrafpunten == limit ? Color.blue : Color.clear, lineWidth: 1.5)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Opgeslagen Spelers Quick Chips
                SavedPlayersQuickChipsView(
                    spelers: $spelers,
                    aantalSpelers: aantalSpelers,
                    tintColor: .blue
                )

                // Invoervelden voor spelersnamen
                VStack(alignment: .leading, spacing: 10) {
                    Text("Spelers")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        ForEach(0..<aantalSpelers, id: \.self) { index in
                            PlayerNameInputField(
                                placeholder: "Naam Speler \(index + 1)",
                                text: $spelers[index],
                                suggestions: scoreManager.savedPlayerNames,
                                submitLabel: index < aantalSpelers - 1 ? .next : .done
                            )
                            .padding(.horizontal)
                        }
                    }
                }

                Spacer(minLength: 16)

                // Start Spel knop
                NavigationLink(
                    destination: FiftyFiftyGameView(
                        spelers: Array(spelers.prefix(aantalSpelers).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }),
                        gameMode: gameMode,
                        gebruikLimiet: gebruikLimiet,
                        limietStrafpunten: limietStrafpunten
                    )
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start Fifty Fifty")
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
        .navigationTitle("Fifty Fifty")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scoreManager.refresh()
        }
    }
}

#Preview {
    NavigationStack {
        FiftyFiftySetupView()
    }
}
