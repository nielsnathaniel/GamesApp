import SwiftUI

struct LoveLetterSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var aantalSpelers: Int = 4
    @State private var doelFiches: Int = 4
    @State private var spelers: [String] = Array(repeating: "", count: 6)
    @State private var showAlert: Bool = false
    @FocusState private var focusedField: Int?

    private func defaultFiches(for playerCnt: Int) -> Int {
        switch playerCnt {
        case 2: return 6
        case 3: return 5
        case 4: return 4
        default: return 3
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header met logo
                HStack(spacing: 12) {
                    if UIImage(named: "LoveLetter") != nil {
                        Image("LoveLetter")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .shadow(color: .pink.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.pink)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Love Letter")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Deductie- & kaartspel")
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
                                doelFiches = defaultFiches(for: number)
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

                // Doel fiches (Tokens of Affection)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Doelscore")
                                .font(.headline)
                            Text("Aantal fiches/rozen nodig om te winnen")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 12) {
                            Button(action: {
                                if doelFiches > 2 { doelFiches -= 1 }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(doelFiches > 2 ? .pink : .secondary.opacity(0.4))
                            }
                            .disabled(doelFiches <= 2)

                            HStack(spacing: 4) {
                                Text("\(doelFiches)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.pink)
                                    .font(.caption)
                            }
                            .frame(minWidth: 44)

                            Button(action: {
                                if doelFiches < 10 { doelFiches += 1 }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(doelFiches < 10 ? .pink : .secondary.opacity(0.4))
                            }
                            .disabled(doelFiches >= 10)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }

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

                // Start Spel knop
                NavigationLink(
                    destination: LoveLetterGameView(
                        spelers: Array(spelers.prefix(aantalSpelers).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }),
                        doelFiches: doelFiches
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
        .navigationTitle("Love Letter")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scoreManager.refresh()
            doelFiches = defaultFiches(for: aantalSpelers)
        }
    }
}

#Preview {
    NavigationStack {
        LoveLetterSetupView()
    }
}
