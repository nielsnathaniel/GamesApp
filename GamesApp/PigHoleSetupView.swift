import SwiftUI

struct PigHoleSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var aantalSpelers: Int = 4
    @State private var startVarkens: Int = 15
    @State private var spelers: [String] = Array(repeating: "", count: 6)

    private func defaultPigs(for playerCnt: Int) -> Int {
        switch playerCnt {
        case 2: return 20
        case 3: return 18
        case 4: return 15
        case 5: return 13
        default: return 11
        }
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

                // Startaantal varkentjes
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Startvoorraad Varkentjes")
                                .font(.headline)
                            Text("Aantal varkentjes per speler bij aanvang")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 12) {
                            Button(action: {
                                if startVarkens > 5 { startVarkens -= 1 }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(startVarkens > 5 ? .pink : .secondary.opacity(0.3))
                            }
                            .disabled(startVarkens <= 5)

                            HStack(spacing: 4) {
                                Text("\(startVarkens)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("🐷")
                            }
                            .frame(minWidth: 50)

                            Button(action: {
                                if startVarkens < 30 { startVarkens += 1 }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(startVarkens < 30 ? .pink : .secondary.opacity(0.3))
                            }
                            .disabled(startVarkens >= 30)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
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
                    destination: PigHoleGameView(
                        spelers: Array(spelers.prefix(aantalSpelers).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }),
                        startVarkens: startVarkens
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
}

#Preview {
    NavigationStack {
        PigHoleSetupView()
    }
}
