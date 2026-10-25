import SwiftUI

struct LoveLetterSetupView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var aantalSpelers: Int = 4
    @State private var doelFiches: Int = 4
    @State private var spelers: [String] = Array(repeating: "", count: 8)
    @State private var geselecteerdeKaartIds: Set<String> = LoveLetterPreset.standaard.cardIds
    @State private var isCustomizingCards: Bool = false
    @FocusState private var focusedField: Int?

    private func defaultFiches(for playerCnt: Int) -> Int {
        switch playerCnt {
        case 2: return 6
        case 3: return 5
        case 4: return 4
        default: return 3
        }
    }

    private var currentPreset: LoveLetterPreset {
        if geselecteerdeKaartIds == LoveLetterPreset.standaard.cardIds {
            return .standaard
        } else if geselecteerdeKaartIds == LoveLetterPreset.premium.cardIds {
            return .premium
        } else if geselecteerdeKaartIds == LoveLetterPreset.premiumPlus.cardIds {
            return .premiumPlus
        } else {
            return .aangepast
        }
    }

    private var actieveKaarten: [LoveLetterCardInfo] {
        allLoveLetterCards.filter { geselecteerdeKaartIds.contains($0.id) }
    }

    private var totaalAantalKaartenInSpel: Int {
        actieveKaarten.reduce(0) { $0 + $1.copies }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header met logo
                headerView

                // Kies aantal spelers (2 t/m 8)
                playerCountSection

                // Doel fiches (Tokens of Affection)
                targetTokensSection

                // Kaartenset & Uitbreidingen
                cardSetSection

                // Opgeslagen Spelers Quick Chips
                SavedPlayersQuickChipsView(
                    spelers: $spelers,
                    aantalSpelers: aantalSpelers,
                    tintColor: .pink
                )

                // Invoervelden voor spelersnamen
                playerInputsSection

                Spacer(minLength: 16)

                // Start Spel knop
                startGameButton
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

    // MARK: - Subviews

    private var headerView: some View {
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
                Text("Deductie- & kaartspel • Standaard, Premium & Premium+")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Aantal Spelers")
                    .font(.headline)
                Spacer()
                Text("2 t/m 8 spelers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(2...8, id: \.self) { number in
                    Button(action: {
                        aantalSpelers = number
                        doelFiches = defaultFiches(for: number)
                    }) {
                        Text("\(number)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(aantalSpelers == number ? .white : .pink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
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
    }

    private var targetTokensSection: some View {
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
    }

    private var cardSetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Kaartenset & Uitbreidingen")
                    .font(.headline)
                Spacer()
                Text("\(totaalAantalKaartenInSpel) kaarten in spel")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.pink)
            }
            .padding(.horizontal)

            // Preset Buttons (Standaard, Premium, Premium+)
            HStack(spacing: 8) {
                ForEach([LoveLetterPreset.standaard, .premium, .premiumPlus], id: \.self) { preset in
                    let isSelected = currentPreset == preset
                    Button(action: {
                        withAnimation {
                            geselecteerdeKaartIds = preset.cardIds
                        }
                    }) {
                        Text(preset.rawValue)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(isSelected ? .white : .pink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? Color.pink : Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.pink : Color.pink.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)

            // Preset status & omschrijving
            HStack(spacing: 6) {
                if currentPreset == .aangepast {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.orange)
                    Text("Aangepaste set (\(geselecteerdeKaartIds.count) unieke soorten • \(totaalAantalKaartenInSpel) kaarten)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.pink)
                    Text(currentPreset.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            // Kaarten checklist disclosure
            DisclosureGroup(
                isExpanded: $isCustomizingCards,
                content: {
                    VStack(spacing: 8) {
                        ForEach(allLoveLetterCards) { card in
                            let isIncluded = geselecteerdeKaartIds.contains(card.id)
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    if isIncluded {
                                        geselecteerdeKaartIds.remove(card.id)
                                    } else {
                                        geselecteerdeKaartIds.insert(card.id)
                                    }
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: isIncluded ? "checkmark.square.fill" : "square")
                                        .foregroundColor(isIncluded ? .pink : .secondary)
                                        .font(.title3)

                                    ZStack {
                                        Circle()
                                            .fill(card.color.opacity(isIncluded ? 0.2 : 0.08))
                                            .frame(width: 32, height: 32)
                                        Text("\(card.value)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(isIncluded ? card.color : .secondary)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(card.name)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(isIncluded ? .primary : .secondary)
                                            Text("(\(card.copies)x)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Image(systemName: card.icon)
                                                .font(.caption2)
                                                .foregroundColor(isIncluded ? card.color : .secondary)
                                        }
                                        Text(card.subtitle)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(isIncluded ? Color.pink.opacity(0.06) : Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 6)
                },
                label: {
                    HStack {
                        Label(
                            currentPreset == .aangepast ? "Kaarten aanpassen (Aangepast)" : "Kaarten inzien / aanpassen",
                            systemImage: "slider.horizontal.3"
                        )
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.pink)

                        Spacer()

                        Text("\(actieveKaarten.count)/\(allLoveLetterCards.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            )
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var playerInputsSection: some View {
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
    }

    private var startGameButton: some View {
        let trimmedPlayers = Array(spelers.prefix(aantalSpelers).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        let canStart = !trimmedPlayers.contains(where: { $0.isEmpty }) && !actieveKaarten.isEmpty

        return NavigationLink(
            destination: LoveLetterGameView(
                spelers: trimmedPlayers,
                doelFiches: doelFiches,
                actieveKaarten: actieveKaarten
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
            .background(canStart ? Color.pink : Color.pink.opacity(0.4))
            .cornerRadius(12)
            .shadow(color: canStart ? Color.pink.opacity(0.35) : Color.clear, radius: 5, x: 0, y: 3)
        }
        .simultaneousGesture(TapGesture().onEnded {
            scoreManager.savePlayerNames(trimmedPlayers.filter { !$0.isEmpty })
        })
        .padding(.horizontal)
        .disabled(!canStart)
    }
}

#Preview {
    NavigationStack {
        LoveLetterSetupView()
    }
}
