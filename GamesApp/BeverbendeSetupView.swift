import SwiftUI

struct BeverbendeSetupView: View {
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
    @State private var aantalSpelers: Int = 2
    @State private var aantalRondes: Int = 2
    @State private var speelwijze: Speelwijze = .gelijkAanAantalSpelers
    @State private var spelers: [String] = Array(repeating: "", count: 6)
    @State private var showAlert = false

    enum Speelwijze {
        case gelijkAanAantalSpelers
        case kiesZelf
    }

    private var effectiveAantalRondes: Int {
        speelwijze == .gelijkAanAantalSpelers ? aantalSpelers : aantalRondes
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image("Beverbende")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Beverbende")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Tactisch kaartspel • Minste strafpunten wint! 🦫")
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
                        ForEach(InvoerModus.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    Text(invoerModus == .snel ? "⚡️ Voer direct de uiteindelijke strafpunten per speler in." : "🎮 Begeleid het spel ronde na ronde met scores per beurt.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
                                HapticManager.shared.light()
                                aantalSpelers = number
                                if speelwijze == .gelijkAanAantalSpelers {
                                    aantalRondes = number
                                }
                            }) {
                                Text("\(number)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(aantalSpelers == number ? .white : .green)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(aantalSpelers == number ? Color.green : Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.green.opacity(0.25), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                if invoerModus == .live {
                    // Kies aantal rondes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aantal Rondes")
                            .font(.headline)
                            .padding(.horizontal)

                        Picker("Rondes", selection: $speelwijze) {
                            Text("Gelijk aan aantal spelers").tag(Speelwijze.gelijkAanAantalSpelers)
                            Text("Kies zelf").tag(Speelwijze.kiesZelf)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: speelwijze) { _, newValue in
                            if newValue == .gelijkAanAantalSpelers {
                                aantalRondes = aantalSpelers
                            }
                        }

                        if speelwijze == .kiesZelf {
                            HStack {
                                Spacer()
                                Button(action: {
                                    if aantalRondes > 3 {
                                        HapticManager.shared.light()
                                        aantalRondes -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(aantalRondes > 3 ? .green : .secondary.opacity(0.3))
                                }
                                .disabled(aantalRondes <= 3)

                                Text("\(aantalRondes) rondes")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .frame(minWidth: 100)

                                Button(action: {
                                    if aantalRondes < 8 {
                                        HapticManager.shared.light()
                                        aantalRondes += 1
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(aantalRondes < 8 ? .green : .secondary.opacity(0.3))
                                }
                                .disabled(aantalRondes >= 8)
                                Spacer()
                            }
                            .padding(.top, 4)
                        }
                    }
                }

                // Opgeslagen Spelers Quick Chips
                SavedPlayersQuickChipsView(
                    spelers: $spelers,
                    aantalSpelers: aantalSpelers,
                    tintColor: .green
                )

                // Invoervelden voor spelersnamen met dropdown voorstellen
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

                // Start spel knop
                let trimmed = Array(spelers.prefix(aantalSpelers).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                NavigationLink(destination: destinationView(trimmed: trimmed)) {
                    HStack(spacing: 8) {
                        Image(systemName: invoerModus == .snel ? "bolt.fill" : "play.fill")
                        Text(invoerModus == .snel ? "Eindscore Invullen" : "Start Spel")
                    }
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(12)
                    .shadow(color: Color.green.opacity(0.35), radius: 5, x: 0, y: 3)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    scoreManager.savePlayerNames(spelers.prefix(aantalSpelers).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
                })
                .padding(.horizontal)
                .disabled(spelers.prefix(aantalSpelers).contains(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty }))
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Invoerfout"), message: Text("Vul alle spelersnamen in."), dismissButton: .default(Text("OK")))
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Beverbende")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scoreManager.refresh()
        }
    }

    @ViewBuilder
    private func destinationView(trimmed: [String]) -> some View {
        if invoerModus == .snel {
            SnelleEindscoreGameView(
                gameName: "Beverbende",
                themeColor: .green,
                spelers: trimmed,
                isLowestScoreWins: true,
                scoreUnit: "strafpunten",
                allowNegative: false,
                initialScore: 0
            )
        } else {
            BeverbendeScoreView(aantalRondes: effectiveAantalRondes, spelers: trimmed.map { Player(name: $0) })
        }
    }
}

#Preview {
    BeverbendeSetupView()
}
