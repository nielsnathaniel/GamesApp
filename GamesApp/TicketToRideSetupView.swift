import SwiftUI

struct TicketToRideSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var aantalSpelers: Int = 4
    @State private var spelers: [String] = Array(repeating: "", count: 5)
    @State private var startModus: TTRScoreMode = .categorieen

    enum TTRScoreMode: String, CaseIterable, Identifiable {
        case categorieen = "Categorieën Berekenen"
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

                    Text(startModus == .categorieen ? "Routepunten, voltooide tickets, mislukte tickets, bonussen (langste route) en stations. Je kunt tijdens het spelen wisselen." : "Direct de eindscore per speler invullen.")
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
                    destination: TicketToRideGameView(
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
}

#Preview {
    NavigationStack {
        TicketToRideSetupView()
    }
}
