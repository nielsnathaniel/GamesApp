import SwiftUI

struct JattenSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    enum InvoerModus: String, CaseIterable, Identifiable {
        case live = "Rondebegeleider"
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
    @State private var spelers: [String] = Array(repeating: "", count: 5)
    @State private var showAlert = false
    @FocusState private var focusedField: Int?

    var body: some View {
        ScrollView {
            VStack {
                HStack(spacing: 12) {
                    if UIImage(named: "Jatten") != nil {
                        Image("Jatten")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.purple)
                    }
                    
                    Text("Jatten")
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
                        ForEach(InvoerModus.allCases) { modus in
                            Label(modus.rawValue, systemImage: modus.icon).tag(modus)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }

                // Kies aantal spelers (2 t/m 5)
                Text("Aantal Spelers")
                    .font(.headline)
                    .padding(.top, 8)

                HStack(spacing: 12) {
                    ForEach(2...5, id: \.self) { number in
                        Button(action: {
                            aantalSpelers = number
                        }) {
                            Text("\(number)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(aantalSpelers == number ? .white : .purple)
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(aantalSpelers == number ? Color.purple : Color.clear)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.purple, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding()

                // Speluitleg / info kaart
                HStack(spacing: 10) {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Speldoel")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("Het spel stopt zodra een speler als eerste 6 kaarten van dezelfde waarde verzameld heeft!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 12)

                // Opgeslagen Spelers Quick Chips
                SavedPlayersQuickChipsView(
                    spelers: $spelers,
                    aantalSpelers: aantalSpelers,
                    tintColor: .purple
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
                    .background(Color.green)
                    .cornerRadius(12)
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
                gameName: "Jatten",
                themeColor: .purple,
                spelers: trimmed,
                isLowestScoreWins: false,
                scoreUnit: "kaarten",
                allowNegative: false,
                initialScore: 0
            )
        } else {
            JattenGameView(spelers: trimmed.map { Player(name: $0) })
        }
    }
}

#Preview {
    JattenSetupView()
}
