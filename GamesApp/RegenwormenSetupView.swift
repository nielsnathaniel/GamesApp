import SwiftUI

enum RegenwormenGameMode: String, CaseIterable, Identifiable {
    case eindstandStenen = "Eindstand (Stenen)"
    case beurtVoorBeurt = "Beurt voor beurt"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .eindstandStenen: return "square.grid.4x4.fill"
        case .beurtVoorBeurt: return "hand.tap.fill"
        }
    }
}

struct RegenwormenSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @State private var aantalSpelers: Int = 2
    @State private var spelers: [String] = Array(repeating: "", count: 7)
    @State private var spelmodus: RegenwormenGameMode = .eindstandStenen
    @State private var showAlert = false
    @FocusState private var focusedField: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Header
                HStack(spacing: 12) {
                    if UIImage(named: "Regenwormen") != nil {
                        Image("Regenwormen")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Image(systemName: "circle.hexagongrid.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Regenwormen")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Reiner Knizia • Meeste wormen wint! 🪱")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .center)

                // Speelwijze Kiezer
                VStack(alignment: .leading, spacing: 8) {
                    Text("Speelwijze")
                        .font(.headline)
                        .padding(.horizontal)

                    Picker("Speelwijze", selection: $spelmodus) {
                        ForEach(RegenwormenGameMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    Text(spelmodus == .eindstandStenen ? "💡 Wijs aan het einde van het spel direct de stenen aan per speler. Elke steen kan maar 1x gekozen worden en kleurt mee!" : "💡 Houd tijdens het spelen elke beurt bij, pak stenen van tafel of steel de bovenste steen van een medespeler met live grafiek!")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                // Kies aantal spelers (2 t/m 7)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aantal Spelers")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                        ForEach(2...7, id: \.self) { number in
                            Button(action: {
                                HapticManager.shared.light()
                                aantalSpelers = number
                            }) {
                                Text("\(number)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(aantalSpelers == number ? .white : .orange)
                                    .padding(10)
                                    .frame(maxWidth: .infinity)
                                    .background(aantalSpelers == number ? Color.orange : Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Opgeslagen Spelers Quick Chips
                SavedPlayersQuickChipsView(
                    spelers: $spelers,
                    aantalSpelers: aantalSpelers,
                    tintColor: .orange
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

                Spacer(minLength: 20)

                // Start spel knop
                NavigationLink(
                    destination: RegenwormenGameView(
                        spelers: spelers.prefix(aantalSpelers).map { Player(name: $0) },
                        initialTab: spelmodus == .eindstandStenen ? .eindstand : .beurtInvoer
                    )
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start Regenwormen")
                    }
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(12)
                    .shadow(color: Color.orange.opacity(0.35), radius: 5, x: 0, y: 3)
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
        .navigationTitle("Regenwormen")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scoreManager.refresh()
        }
    }
}

#Preview {
    NavigationStack {
        RegenwormenSetupView()
    }
}
