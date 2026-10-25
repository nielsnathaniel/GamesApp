import SwiftUI

enum FiftyFiftyWhiteGoblinMode: String, CaseIterable, Identifiable {
    case rondes = "Ronde per ronde"
    case enkelePot = "Enkele pot"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .rondes: return "arrow.triangle.2.circlepath"
        case .enkelePot: return "1.circle"
        }
    }
}

struct FiftyFiftySetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var aantalSpelers: Int = 4
    @State private var gameMode: FiftyFiftyWhiteGoblinMode = .rondes
    @State private var aantalRondesDoel: Int = 3
    @State private var gebruikLimiet: Bool = false
    @State private var limietStrafkaarten: Int = 25
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
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: .orange.opacity(0.35), radius: 4, x: 0, y: 2)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 46, height: 46)

                            Text("50")
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(.white)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fifty Fifty")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("White Goblin Games • Minste strafkaarten wint! 🦊🃏")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .center)

                // Spelregels samenvatting
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("Spelregels in het kort")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("• **Spelen:** Leg een **hoger getal** neer óf vervang de laatste kaart door een **lager getal** tussen de voorlaatste en laatste.")
                        Text("• **Niet kunnen:** Pak kaarten uit de rij als **strafkaarten** (1 punt per kaart).")
                        Text("• **🦊 Voskaarten:** Gebruik om te passen of te redden. **Pas op:** Heb je aan het einde nog een vos op hand? Dan heb je **direct verloren!**")
                            .foregroundColor(.red)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)

                // Spelmodus Kiezer
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spelmodus")
                        .font(.headline)
                        .padding(.horizontal)

                    Picker("Spelmodus", selection: $gameMode) {
                        ForEach(FiftyFiftyWhiteGoblinMode.allCases) { mode in
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
                                    .foregroundColor(aantalSpelers == number ? .white : .orange)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(aantalSpelers == number ? Color.orange : Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Rondes Doel of Limiet
                if gameMode == .rondes {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Aantal Rondes")
                                    .font(.headline)
                                Text("Aantal te spelen rondes (optellen van strafkaarten)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            HStack(spacing: 6) {
                                ForEach([3, 4, 5, 8], id: \.self) { r in
                                    Button(action: {
                                        HapticManager.shared.light()
                                        aantalRondesDoel = r
                                    }) {
                                        Text("\(r)")
                                            .font(.subheadline)
                                            .fontWeight(aantalRondesDoel == r ? .bold : .medium)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(aantalRondesDoel == r ? Color.orange.opacity(0.25) : Color(UIColor.secondarySystemGroupedBackground))
                                            .foregroundColor(aantalRondesDoel == r ? .orange : .primary)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(aantalRondesDoel == r ? Color.orange : Color.clear, lineWidth: 1.5)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Spelen tot een strafkaart-limiet", isOn: $gebruikLimiet)
                            .font(.headline)
                            .padding(.horizontal)

                        if gebruikLimiet {
                            HStack(spacing: 8) {
                                Text("Limiet:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Spacer()

                                ForEach([15, 20, 25, 30], id: \.self) { limit in
                                    Button(action: {
                                        HapticManager.shared.light()
                                        limietStrafkaarten = limit
                                    }) {
                                        Text("\(limit) 🃏")
                                            .font(.subheadline)
                                            .fontWeight(limietStrafkaarten == limit ? .bold : .medium)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(limietStrafkaarten == limit ? Color.orange.opacity(0.25) : Color(UIColor.secondarySystemGroupedBackground))
                                            .foregroundColor(limietStrafkaarten == limit ? .orange : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Opgeslagen Spelers Quick Chips
                SavedPlayersQuickChipsView(
                    spelers: $spelers,
                    aantalSpelers: aantalSpelers,
                    tintColor: .orange
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
                        aantalRondesDoel: aantalRondesDoel,
                        gebruikLimiet: gebruikLimiet,
                        limietStrafkaarten: limietStrafkaarten
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
                    .background(Color.orange)
                    .cornerRadius(12)
                    .shadow(color: Color.orange.opacity(0.35), radius: 5, x: 0, y: 3)
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
