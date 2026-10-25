import SwiftUI

struct QwixxSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var aantalSpelers: Int = 3
    @State private var spelers: [String] = Array(repeating: "", count: 5)
    @State private var startModus: QwixxScoreMode = .formulier

    enum QwixxScoreMode: String, CaseIterable, Identifiable {
        case formulier = "Digitaal Scoreformulier"
        case direct = "Direct Totaal Invullen"

        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    if UIImage(named: "Qwixx") != nil {
                        Image("Qwixx")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Qwixx")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Klassiek dobbelspel • Rood, Geel, Groen & Blauw")
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

                // Invoermodus
                VStack(alignment: .leading, spacing: 8) {
                    Text("Puntentelling Voorkeur")
                        .font(.headline)
                        .padding(.horizontal)

                    Picker("Invoermodus", selection: $startModus) {
                        ForEach(QwixxScoreMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    Text(startModus == .formulier ? "Kruisjes tellen per kleurrij (Rood, Geel, Groen, Blauw) en misworpen met automatische puntberekening. Je kunt ook tijdens het spel nog wisselen." : "Direct de eindscore per speler invullen.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

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
                    destination: QwixxGameView(
                        spelers: Array(spelers.prefix(aantalSpelers).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }),
                        initialMode: startModus
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
        .navigationTitle("Qwixx")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scoreManager.refresh()
        }
    }
}

#Preview {
    NavigationStack {
        QwixxSetupView()
    }
}
