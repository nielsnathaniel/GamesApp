import SwiftUI

struct PigHoleSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    enum InvoerModus: String, CaseIterable, Identifiable {
        case live = "Ronde voor ronde"
        case snel = "Snelle eindscore"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .live: return "play.circle.fill"
            case .snel: return "bolt.fill"
            }
        }
    }

    @State private var invoerModus: InvoerModus = .live
    @State private var aantalSpelers: Int = 4
    @State private var startVarkens: Int = 15
    @State private var spelers: [String] = Array(repeating: "", count: 6)

    private func defaultPigs(for playerCnt: Int) -> Int {
        return 60 / max(1, playerCnt)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    if UIImage(named: "PigHole") != nil {
                        Image("PigHole")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .shadow(color: .pink.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.pink)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pig Hole")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Het Varkensgat • Dobbelspel")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .center)

                // Speelwijze Kiezer (Live vs Snelle Eindscore)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Speelwijze")
                        .font(.headline)
                        .padding(.horizontal)

                    Picker("Speelwijze", selection: $invoerModus) {
                        ForEach(InvoerModus.allCases) { modus in
                            Label(modus.rawValue, systemImage: modus.icon).tag(modus)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }

                // Kies aantal spelers (2 t/m 6)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aantal Spelers")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                        ForEach(2...6, id: \.self) { number in
                            Button(action: {
                                aantalSpelers = number
                                startVarkens = defaultPigs(for: number)
                            }) {
                                Text("\(number)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(aantalSpelers == number ? .white : .pink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(aantalSpelers == number ? Color.pink : Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.pink.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Startaantal varkentjes (alleen bij live ronde voor ronde)
                if invoerModus == .live {
                    VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Startvoorraad Varkentjes")
                                .font(.headline)
                            Text("Totaal 60 varkentjes verdeeld over \(aantalSpelers) spelers (\(defaultPigs(for: aantalSpelers)) elk)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Button(action: {
                                if startVarkens > 1 { startVarkens -= 1 }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(startVarkens > 1 ? .pink : .secondary.opacity(0.3))
                            }
                            .disabled(startVarkens <= 1)

                            NumericScoreInputView(
                                score: $startVarkens,
                                allowNegative: false,
                                range: 1...60,
                                tintColor: .pink,
                                minWidth: 46,
                                height: 32
                            )

                            Button(action: {
                                if startVarkens < 60 { startVarkens += 1 }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(startVarkens < 60 ? .pink : .secondary.opacity(0.3))
                            }
                            .disabled(startVarkens >= 60)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    HStack {
                        Text("💡 Tik op het getal om direct te typen, of gebruik de knoppen.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Spacer()

                        if startVarkens != defaultPigs(for: aantalSpelers) {
                            Button(action: {
                                startVarkens = defaultPigs(for: aantalSpelers)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Herstel (\(defaultPigs(for: aantalSpelers)))")
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.pink)
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
                    tintColor: .pink
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
                let trimmed = Array(spelers.prefix(aantalSpelers).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                NavigationLink(
                    destination: destinationView(trimmed: trimmed)
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: invoerModus == .snel ? "bolt.fill" : "play.fill")
                        Text(invoerModus == .snel ? "Eindscore Invullen" : "Start Spel")
                    }
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .cornerRadius(12)
                    .shadow(color: Color.pink.opacity(0.35), radius: 5, x: 0, y: 3)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    scoreManager.savePlayerNames(spelers.prefix(aantalSpelers).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
                })
                .padding(.horizontal)
                .disabled(spelers.prefix(aantalSpelers).contains(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty }))
            }
            .padding(.vertical)
        }
        .navigationTitle("Pig Hole")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scoreManager.refresh()
            startVarkens = defaultPigs(for: aantalSpelers)
        }
    }

    @ViewBuilder
    private func destinationView(trimmed: [String]) -> some View {
        if invoerModus == .snel {
            SnelleEindscoreGameView(
                gameName: "Pig Hole",
                themeColor: .pink,
                spelers: trimmed,
                isLowestScoreWins: true,
                scoreUnit: "varkentjes",
                allowNegative: false,
                initialScore: 0
            )
        } else {
            PigHoleGameView(
                spelers: trimmed,
                startVarkens: startVarkens
            )
        }
    }
}

#Preview {
    NavigationStack {
        PigHoleSetupView()
    }
}
