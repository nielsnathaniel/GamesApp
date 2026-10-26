import SwiftUI

struct QuickstopSetupView: View {
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
    @State private var limietStrafpunten: Int = 40
    @State private var spelers: [String] = Array(repeating: "", count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    if UIImage(named: "Quickstop") != nil {
                        Image("Quickstop")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.yellow)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quickstop")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Snel woordspel • Minste bliksems wint ⚡️")
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

                // Kies aantal spelers (2 t/m 7)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aantal Spelers")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(2...7, id: \.self) { number in
                            Button(action: {
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

                // Limiet strafpunten (alleen bij live ronde voor ronde)
                if invoerModus == .live {
                    VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Eindlimiet Strafpunten")
                                .font(.headline)
                            Text("Spel stopt zodra iemand deze limiet bereikt")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            ForEach([30, 40, 50], id: \.self) { limit in
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    limietStrafpunten = limit
                                }) {
                                    Text("\(limit) ⚡️")
                                        .font(.subheadline)
                                        .fontWeight(limietStrafpunten == limit ? .bold : .medium)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(limietStrafpunten == limit ? Color.yellow.opacity(0.25) : Color(UIColor.secondarySystemGroupedBackground))
                                        .foregroundColor(limietStrafpunten == limit ? .orange : .primary)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(limietStrafpunten == limit ? Color.orange : Color.clear, lineWidth: 1.5)
                                        )
                                }
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
        .navigationTitle("Quickstop")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scoreManager.refresh()
        }
    }

    @ViewBuilder
    private func destinationView(trimmed: [String]) -> some View {
        if invoerModus == .snel {
            SnelleEindscoreGameView(
                gameName: "Quickstop",
                themeColor: .orange,
                spelers: trimmed,
                isLowestScoreWins: true,
                scoreUnit: "⚡️",
                allowNegative: false,
                initialScore: 0
            )
        } else {
            QuickstopGameView(
                spelers: trimmed,
                limietStrafpunten: limietStrafpunten
            )
        }
    }
}

#Preview {
    NavigationStack {
        QuickstopSetupView()
    }
}
