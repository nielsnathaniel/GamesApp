import SwiftUI

struct BalzakkenSetupView: View {
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
    @State private var aantalSpelers: Int = 3
    @State private var spelers: [String] = Array(repeating: "", count: 6)
    @State private var showAlert = false
    @FocusState private var focusedField: Int?

    var body: some View {
        ScrollView {
            VStack {
                HStack(spacing: 12) {
                    if UIImage(named: "Balzakken") != nil {
                        Image("Balzakken")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.red)
                    }
                    
                    Text("Balzakken")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 0)
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

                    Text(invoerModus == .snel ? "⚡️ Voer direct de uiteindelijke strafpunten per speler in." : "🎮 Begeleid het spel ronde na ronde met automatische strafpunten & 69/99 regels.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top, 6)

                // Kies aantal spelers (2 t/m 6)
                Text("Aantal Spelers")
                    .font(.headline)
                    .padding(.top, 8)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                    ForEach(2...6, id: \.self) { number in
                        Button(action: {
                            aantalSpelers = number
                        }) {
                            Text("\(number)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(aantalSpelers == number ? .white : .red)
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(aantalSpelers == number ? Color.red : Color.clear)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.red, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding()

                // Speluitleg / info
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("Het spel stopt zodra een speler 100 strafpunten bereikt. De speler met de minste strafpunten wint!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)

                // Opgeslagen Spelers Quick Chips
                SavedPlayersQuickChipsView(
                    spelers: $spelers,
                    aantalSpelers: aantalSpelers,
                    tintColor: .red
                )

                // Invoervelden voor spelersnamen met dropdown voorstellen
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

                Spacer(minLength: 20)

                // Start spel knop
                let trimmed = Array(spelers.prefix(aantalSpelers).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                NavigationLink(destination: destinationView(trimmed: trimmed)) {
                    HStack(spacing: 8) {
                        Image(systemName: invoerModus == .snel ? "bolt.fill" : "play.fill")
                        Text(invoerModus == .snel ? "Eindscore Invullen" : "Start Spel")
                    }
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    scoreManager.savePlayerNames(trimmed.filter { !$0.isEmpty })
                })
                .padding(.horizontal)
                .disabled(trimmed.contains(where: { $0.isEmpty }))
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Invoerfout"), message: Text("Vul alle spelersnamen in."), dismissButton: .default(Text("OK")))
                }
            }
            .padding()
        }
        .onAppear {
            scoreManager.refresh()
        }
    }

    @ViewBuilder
    private func destinationView(trimmed: [String]) -> some View {
        if invoerModus == .snel {
            SnelleEindscoreGameView(
                gameName: "Balzakken",
                themeColor: .red,
                spelers: trimmed,
                isLowestScoreWins: true,
                scoreUnit: "strafpunten",
                allowNegative: false,
                initialScore: 0
            )
        } else {
            BalzakkenGameView(spelers: trimmed.map { Player(name: $0) })
        }
    }
}

#Preview {
    BalzakkenSetupView()
}
