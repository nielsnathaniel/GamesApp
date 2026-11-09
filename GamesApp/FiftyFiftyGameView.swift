import SwiftUI

struct FiftyFiftyWhiteGoblinRondeEntry: Identifiable {
    var id: UUID = UUID()
    let ronde: Int
    let strafkaartenDezeRonde: [Int]
    let vosOpHandDezeRonde: [Bool]
    let totaleStrafkaartenNaRonde: [Int]
}

struct FiftyFiftyGameView: View {
    let spelers: [String]
    let gameMode: FiftyFiftyWhiteGoblinMode
    let aantalRondesDoel: Int
    let gebruikLimiet: Bool
    let limietStrafkaarten: Int

    @ObservedObject private var scoreManager = ScoreManager.shared
    @ObservedObject private var activeGameManager = ActiveGameManager.shared

    @State private var huidigeRonde: Int = 1

    // Strafkaarten totalen
    @State private var totaleStrafkaarten: [Int]
    // Strafkaarten invoer voor de huidige ronde
    @State private var rondeStrafkaarten: [Int]
    // Vos op hand in de huidige ronde
    @State private var heeftVosOpHand: [Bool]
    // Cumulatief aantal keren vos gehad gedurende het hele spel
    @State private var totaleVossen: [Int]

    @State private var rondeGeschiedenis: [FiftyFiftyWhiteGoblinRondeEntry] = []
    @State private var showWinnaarView: Bool = false
    @State private var winnaarPlayer: Player = Player(name: "")
    @State private var toonGeschiedenisSheet: Bool = false
    @State private var showFinishConfirm: Bool = false
    @State private var restoreTargetEntry: FiftyFiftyWhiteGoblinRondeEntry? = nil
    @State private var showRestoreDialog: Bool = false
    @State private var showPuntenWijzigenSheet: Bool = false

    // Fifty Fifty 100-kaarten controle & automatische aanvulling
    @State private var handmatigIngevuld: Set<Int> = []
    @State private var automatischAangevuldIndex: Int? = nil

    init(
        spelers: [String],
        gameMode: FiftyFiftyWhiteGoblinMode = .rondes,
        aantalRondesDoel: Int = 3,
        gebruikLimiet: Bool = false,
        limietStrafkaarten: Int = 25
    ) {
        self.spelers = spelers
        self.gameMode = gameMode
        self.aantalRondesDoel = aantalRondesDoel
        self.gebruikLimiet = gebruikLimiet
        self.limietStrafkaarten = limietStrafkaarten

        _totaleStrafkaarten = State(initialValue: Array(repeating: 0, count: spelers.count))
        _rondeStrafkaarten = State(initialValue: Array(repeating: 0, count: spelers.count))
        _heeftVosOpHand = State(initialValue: Array(repeating: false, count: spelers.count))
        _totaleVossen = State(initialValue: Array(repeating: 0, count: spelers.count))
    }

    // MARK: - Berekeningen

    private func effectieveScore(voor index: Int) -> Int {
        guard index < totaleStrafkaarten.count && index < rondeStrafkaarten.count else { return 0 }
        if gameMode == .rondes {
            return totaleStrafkaarten[index] + rondeStrafkaarten[index]
        } else {
            return rondeStrafkaarten[index]
        }
    }

    private var huidigeLeider: String {
        guard !spelers.isEmpty else { return "" }
        // Spelers die deze ronde én in totaal GEEN vos hebben gehad komen als eerste in aanmerking
        let schoneSpelers = spelers.indices.filter { !heeftVosOpHand[$0] && totaleVossen[$0] == 0 }
        let kandidaten = !schoneSpelers.isEmpty ? schoneSpelers : spelers.indices.filter { !heeftVosOpHand[$0] }
        let lijst = !kandidaten.isEmpty ? kandidaten : Array(spelers.indices)
        let minScore = lijst.map { effectieveScore(voor: $0) }.min() ?? 0
        if let idx = lijst.first(where: { effectieveScore(voor: $0) == minScore }) {
            return spelers[idx]
        }
        return ""
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header statuskaart
                headerView

                // Voskaart waarschuwing / banner
                vosRuleBanner

                // Totaal strafkaarten controle banner (moet altijd 100 zijn)
                scoreControleBanner

                // Spelerslijst met strafkaarten invoer
                playersList

                // Actieknoppen
                actionSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Fifty Fifty")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    HapticManager.shared.light()
                    toonGeschiedenisSheet = true
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.orange)
                }
            }
        }
        .sheet(isPresented: $toonGeschiedenisSheet) {
            historySheet
        }
        .navigationDestination(isPresented: $showWinnaarView) {
            WinnaarView(
                gameName: "Fifty Fifty",
                winnaar: winnaarPlayer,
                sortedSpelers: sortedSpelersResultaat,
                sortedScores: sortedScoresResultaat,
                isLowestScoreWins: true,
                onReset: resetGame
            )
        }
        .confirmationDialog(
            "Spel Nu Afronden?",
            isPresented: $showFinishConfirm,
            titleVisibility: .visible
        ) {
            Button("Afronden en Winnaar Bekijken") {
                finishGame()
            }
            Button("Verder Spelen", role: .cancel) {}
        } message: {
            Text("De scores worden opgeslagen. De speler met de minste strafkaarten (zonder vos op hand) wint!")
        }
        .sheet(isPresented: $showPuntenWijzigenSheet) {
            PuntenWijzigenSheet(
                spelers: spelers,
                huidigeScores: totaleStrafkaarten,
                titel: "Fifty Fifty Stand Wijzigen",
                isLowestScoreWins: true
            ) { nieuweScores in
                totaleStrafkaarten = nieuweScores
                let entry = FiftyFiftyWhiteGoblinRondeEntry(
                    id: UUID(),
                    ronde: huidigeRonde,
                    strafkaartenDezeRonde: Array(repeating: 0, count: spelers.count),
                    vosOpHandDezeRonde: Array(repeating: false, count: spelers.count),
                    totaleStrafkaartenNaRonde: nieuweScores
                )
                rondeGeschiedenis.append(entry)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        .confirmationDialog(
            "Ronde herstellen?",
            isPresented: $showRestoreDialog,
            titleVisibility: .visible
        ) {
            Button("✏️ Punten direct wijzigen...") {
                openPuntenWijzigenVanuitGeschiedenis()
            }
            if let target = restoreTargetEntry {
                Button("Herstel naar Ronde \(target.ronde)", role: .destructive) {
                    restoreToRound(target)
                }
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            if let target = restoreTargetEntry {
                Text("De rondes na ronde \(target.ronde) worden teruggedraaid. Of pas de punten direct aan.")
            }
        }
        .onAppear {
            restoreDraftIfNeeded()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 12) {
            // Ronde indicator
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .foregroundColor(.orange)
                    if gameMode == .rondes {
                        Text("Ronde \(huidigeRonde) van \(aantalRondesDoel)")
                            .font(.title3)
                            .fontWeight(.bold)
                    } else {
                        Text("Enkele Pot")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }

                if gebruikLimiet && gameMode == .enkelePot {
                    Text("Limiet: \(limietStrafkaarten) strafkaarten")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Minste strafkaarten wint 🃏")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Leider badge
            if !huidigeLeider.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("Koploper")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }

                    Text(huidigeLeider)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Vos Rule Banner

    private var vosRuleBanner: some View {
        HStack(spacing: 10) {
            Text("🦊")
                .font(.system(size: 26))

            VStack(alignment: .leading, spacing: 1) {
                Text("Gouden Vosregel:")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                Text("Heb je aan het einde nog een voskaart op hand? Dan heb je direct verloren!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Fifty Fifty 100-Strafkaarten Controle Banner

    private var huidigeRondeTotaal: Int {
        rondeStrafkaarten.reduce(0, +)
    }

    private var isTotaalGeldig: Bool {
        huidigeRondeTotaal == 100
    }

    private var overgeblevenNietIngevuldeSpelerIndex: Int? {
        guard spelers.count >= 2 else { return nil }
        let nietIngevuld = spelers.indices.filter { !handmatigIngevuld.contains($0) }
        return nietIngevuld.count == 1 ? nietIngevuld.first : nil
    }

    private func updateSpelerScore(index: Int, newScore: Int, isHandmatig: Bool = true) {
        let clamped = max(0, min(100, newScore))
        rondeStrafkaarten[index] = clamped

        if isHandmatig {
            handmatigIngevuld.insert(index)
            if automatischAangevuldIndex == index {
                automatischAangevuldIndex = nil
            }
        }

        // Automatisch de laatste overgebleven persoon invullen als er N-1 spelers zijn ingevuld
        controleerEnVulLaatsteSpelerIn()
        saveDraft()
    }

    private func controleerEnVulLaatsteSpelerIn() {
        guard spelers.count >= 2 else { return }
        let nietIngevuld = spelers.indices.filter { !handmatigIngevuld.contains($0) }
        if nietIngevuld.count == 1, let targetIdx = nietIngevuld.first {
            let somAnderen = spelers.indices.filter { $0 != targetIdx }.reduce(0) { $0 + rondeStrafkaarten[$1] }
            let restant = max(0, 100 - somAnderen)
            rondeStrafkaarten[targetIdx] = restant
            automatischAangevuldIndex = targetIdx
        }
    }

    private func pasRestantHandmatigToe(targetIdx: Int, restant: Int) {
        rondeStrafkaarten[targetIdx] = max(0, restant)
        handmatigIngevuld.insert(targetIdx)
        automatischAangevuldIndex = nil
        saveDraft()
    }

    private var scoreControleKleur: Color {
        if isTotaalGeldig {
            return .green
        } else if huidigeRondeTotaal > 100 {
            return .red
        } else {
            return .orange
        }
    }

    private func restantVoorSpeler(_ targetIdx: Int) -> Int {
        let somAnderen = spelers.indices.filter { $0 != targetIdx }.reduce(0) { $0 + rondeStrafkaarten[$1] }
        return max(0, 100 - somAnderen)
    }

    @ViewBuilder
    private var scoreControleStatusView: some View {
        if isTotaalGeldig {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("Totaal: 100 / 100 strafkaarten ✅")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                Text("Klopt exact! Alle 100 kaarten zijn verdeeld.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } else if huidigeRondeTotaal < 100 {
            let rest = 100 - huidigeRondeTotaal
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("Totaal: \(huidigeRondeTotaal) / 100 strafkaarten")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                Text("Nog \(rest) strafkaart\(rest == 1 ? "" : "en") te verdelen.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } else {
            let teVeel = huidigeRondeTotaal - 100
            Image(systemName: "xmark.octagon.fill")
                .foregroundColor(.red)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("Totaal: \(huidigeRondeTotaal) / 100 strafkaarten")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                Text("\(teVeel) strafkaart\(teVeel == 1 ? "" : "en") te veel ingevoerd!")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    private var restantAanvullenKnop: some View {
        if let targetIdx = overgeblevenNietIngevuldeSpelerIndex, huidigeRondeTotaal != 100 {
            let restant = restantVoorSpeler(targetIdx)
            HStack {
                Spacer()
                Button(action: {
                    HapticManager.shared.light()
                    pasRestantHandmatigToe(targetIdx: targetIdx, restant: restant)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                        Text("Vul restant in bij \(spelers[targetIdx]) (\(restant) pt)")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var scoreControleBanner: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                scoreControleStatusView

                Spacer()

                Text("\(huidigeRondeTotaal)/100")
                    .font(.subheadline)
                    .fontWeight(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(scoreControleKleur.opacity(0.18))
                    .foregroundColor(scoreControleKleur)
                    .clipShape(Capsule())
            }

            restantAanvullenKnop
        }
        .padding(12)
        .background(scoreControleKleur.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(scoreControleKleur.opacity(0.3), lineWidth: 1.5)
        )
        .padding(.horizontal)
    }

    // MARK: - Spelers Kaartenlijst

    private var playersList: some View {
        VStack(spacing: 14) {
            ForEach(spelers.indices, id: \.self) { index in
                playerCard(for: index)
            }
        }
        .padding(.horizontal)
    }

    private func playerCard(for index: Int) -> some View {
        let name = spelers[index]
        let currentRoundScore = rondeStrafkaarten[index]
        let totalScore = effectieveScore(voor: index)
        let hasFox = heeftVosOpHand[index]

        return VStack(spacing: 12) {
            // Spelerheader + Strafkaarten badge
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if automatischAangevuldIndex == index {
                            HStack(spacing: 3) {
                                Image(systemName: "wand.and.stars")
                                Text("Aangevuld")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }

                    if hasFox {
                        HStack(spacing: 4) {
                            Text("🦊")
                            Text("Vos op hand (verliest ronde)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    } else if totaleVossen[index] > 0 {
                        HStack(spacing: 4) {
                            Text("🦊 \(totaleVossen[index])x vos gehad")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            if gameMode == .rondes {
                                Text("• Totaal: \(totalScore)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else if gameMode == .rondes {
                        Text("Totaal: \(totalScore) strafkaarten")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Score weergave
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(totalScore)")
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(hasFox ? .red : (totalScore == 0 ? .green : .orange))
                        Text(totalScore == 1 ? "kaart" : "kaarten")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if gameMode == .rondes {
                        Text("deze ronde: +\(currentRoundScore)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Invoerknoppen voor strafkaarten
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Button(action: {
                        HapticManager.shared.light()
                        if rondeStrafkaarten[index] > 0 {
                            updateSpelerScore(index: index, newScore: rondeStrafkaarten[index] - 1)
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(rondeStrafkaarten[index] > 0 ? .orange : .gray.opacity(0.3))
                    }
                    .disabled(rondeStrafkaarten[index] <= 0)

                    NumericScoreInputView(
                        score: Binding(
                            get: { rondeStrafkaarten[index] },
                            set: { updateSpelerScore(index: index, newScore: $0) }
                        ),
                        allowNegative: false,
                        range: 0...100,
                        tintColor: .orange,
                        placeholder: "0",
                        minWidth: 50,
                        height: 36,
                        font: .title3
                    )

                    Button(action: {
                        HapticManager.shared.light()
                        updateSpelerScore(index: index, newScore: rondeStrafkaarten[index] + 1)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    // Snelle ophoging (+1, +2, +5)
                    HStack(spacing: 6) {
                        ForEach([1, 2, 5], id: \.self) { amount in
                            Button(action: {
                                HapticManager.shared.light()
                                updateSpelerScore(index: index, newScore: rondeStrafkaarten[index] + amount)
                            }) {
                                Text("+\(amount)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Vos op hand toggle
                Button(action: {
                    HapticManager.shared.medium()
                    heeftVosOpHand[index].toggle()
                    saveDraft()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: hasFox ? "checkmark.square.fill" : "square")
                            .foregroundColor(hasFox ? .red : .secondary)
                            .font(.subheadline)

                        Text("🦊 Vos op hand (verliest direct bij einde)")
                            .font(.caption)
                            .fontWeight(hasFox ? .bold : .regular)
                            .foregroundColor(hasFox ? .red : .secondary)

                        Spacer()
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(hasFox ? Color.red.opacity(0.6) : (totalScore == 0 ? Color.green.opacity(0.4) : Color.clear), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Actieknoppen

    private var actionSection: some View {
        VStack(spacing: 12) {
            if gameMode == .rondes {
                if huidigeRonde < aantalRondesDoel {
                    // Volgende Ronde knop
                    Button(action: {
                        if isTotaalGeldig {
                            volgendeRonde()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isTotaalGeldig ? "arrow.right.circle.fill" : "lock.fill")
                            Text("Voltooi Ronde \(huidigeRonde) / \(aantalRondesDoel)")
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isTotaalGeldig ? Color.orange : Color.gray.opacity(0.5))
                        .cornerRadius(12)
                        .shadow(color: isTotaalGeldig ? Color.orange.opacity(0.35) : Color.clear, radius: 5, x: 0, y: 3)
                    }
                    .disabled(!isTotaalGeldig)
                    .padding(.horizontal)
                } else {
                    // Laatste ronde voltooid -> Afronden knop
                    Button(action: {
                        if isTotaalGeldig {
                            finishGame()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isTotaalGeldig ? "flag.checkered" : "lock.fill")
                            Text("Voltooi Laatste Ronde & Bekijk Winnaar")
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isTotaalGeldig ? Color.green : Color.gray.opacity(0.5))
                        .cornerRadius(12)
                        .shadow(color: isTotaalGeldig ? Color.green.opacity(0.35) : Color.clear, radius: 5, x: 0, y: 3)
                    }
                    .disabled(!isTotaalGeldig)
                    .padding(.horizontal)
                }
            } else {
                // Enkele pot
                Button(action: {
                    if isTotaalGeldig {
                        finishGame()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isTotaalGeldig ? "flag.checkered" : "lock.fill")
                        Text("Spel Afronden & Uitslag Bekijken")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isTotaalGeldig ? Color.green : Color.gray.opacity(0.5))
                    .cornerRadius(12)
                    .shadow(color: isTotaalGeldig ? Color.green.opacity(0.35) : Color.clear, radius: 5, x: 0, y: 3)
                }
                .disabled(!isTotaalGeldig)
                .padding(.horizontal)
            }

            if !isTotaalGeldig {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(huidigeRondeTotaal > 100 ? .red : .orange)
                    if huidigeRondeTotaal < 100 {
                        Text("Totaal moet exact 100 zijn om door te gaan (nog \(100 - huidigeRondeTotaal) open).")
                    } else {
                        Text("Totaal moet exact 100 zijn om door te gaan (\(huidigeRondeTotaal - 100) te veel).")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }

            // Tussentijds afronden knop
            if gameMode == .rondes && (!rondeGeschiedenis.isEmpty || isTotaalGeldig) {
                Button(action: {
                    HapticManager.shared.medium()
                    showFinishConfirm = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "flag.checkered")
                        Text("Spel Nu Voortijdig Afronden")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Ronde Voltooien & Geschiedenis

    private func volgendeRonde() {
        HapticManager.shared.success()

        // 1. Voeg ronde strafkaarten toe aan totalen en werk vossentelling bij
        for i in spelers.indices {
            totaleStrafkaarten[i] += rondeStrafkaarten[i]
            if heeftVosOpHand[i] {
                totaleVossen[i] += 1
            }
        }

        // 2. Sla snapshot op in geschiedenis
        let entry = FiftyFiftyWhiteGoblinRondeEntry(
            ronde: huidigeRonde,
            strafkaartenDezeRonde: rondeStrafkaarten,
            vosOpHandDezeRonde: heeftVosOpHand,
            totaleStrafkaartenNaRonde: totaleStrafkaarten
        )
        rondeGeschiedenis.append(entry)

        // 3. Reset ronde invoervelden
        rondeStrafkaarten = Array(repeating: 0, count: spelers.count)
        heeftVosOpHand = Array(repeating: false, count: spelers.count)
        handmatigIngevuld.removeAll()
        automatischAangevuldIndex = nil

        // 4. Volgende ronde
        huidigeRonde += 1
        saveDraft()
    }

    private func restoreToRound(_ entry: FiftyFiftyWhiteGoblinRondeEntry) {
        HapticManager.shared.medium()
        withAnimation {
            totaleStrafkaarten = entry.totaleStrafkaartenNaRonde
            rondeStrafkaarten = Array(repeating: 0, count: spelers.count)
            heeftVosOpHand = entry.vosOpHandDezeRonde
            handmatigIngevuld.removeAll()
            automatischAangevuldIndex = nil
            rondeGeschiedenis.removeAll { $0.ronde >= entry.ronde }
            huidigeRonde = entry.ronde
            toonGeschiedenisSheet = false
            saveDraft()
        }
    }

    // MARK: - Spel Afronden

    private func finishGame() {
        HapticManager.shared.celebration()

        // Als er in 'Ronde per ronde' nog kaarten in de huidige ronde stonden, voeg ze toe
        if gameMode == .rondes {
            for i in spelers.indices {
                totaleStrafkaarten[i] += rondeStrafkaarten[i]
                if heeftVosOpHand[i] {
                    totaleVossen[i] += 1
                }
            }
            rondeStrafkaarten = Array(repeating: 0, count: spelers.count)
            heeftVosOpHand = Array(repeating: false, count: spelers.count)
        } else {
            for i in spelers.indices {
                if heeftVosOpHand[i] {
                    totaleVossen[i] += 1
                }
            }
        }

        let eindScores = spelers.indices.map { effectieveScore(voor: $0) }

        // Bepaal winnaar: spelers met 0 vossen winnen ALTIJD van spelers met 1+ vossen
        let geordendeIndices = spelers.indices.sorted { i1, i2 in
            let v1 = totaleVossen[i1]
            let v2 = totaleVossen[i2]
            if v1 != v2 {
                return v1 < v2 // 0 vossen staat altijd boven 1+ vossen
            }
            return eindScores[i1] < eindScores[i2] // minste strafkaarten wint
        }

        let winnaarIndex = geordendeIndices.first ?? 0
        winnaarPlayer = Player(name: spelers[winnaarIndex])

        // Opslaan in ScoreManager
        let detailedScores: [(name: String, score: Int, juiste: Int, foute: Int)] = spelers.indices.map { i in
            let vosPenalty = totaleVossen[i] * 10
            return (name: spelers[i], score: eindScores[i], juiste: eindScores[i], foute: vosPenalty)
        }

        scoreManager.saveGame(
            gameName: "Fifty Fifty",
            playerDetailedScores: detailedScores,
            winnerName: winnaarPlayer.name
        )

        activeGameManager.clearActiveGame()
        showWinnaarView = true
    }

    private var sortedSpelersResultaat: [Player] {
        let eindScores = spelers.indices.map { effectieveScore(voor: $0) }
        let geordendeIndices = spelers.indices.sorted { i1, i2 in
            let v1 = totaleVossen[i1]
            let v2 = totaleVossen[i2]
            if v1 != v2 {
                return v1 < v2
            }
            return eindScores[i1] < eindScores[i2]
        }
        return geordendIndicesToPlayers(geordendeIndices)
    }

    private func geordendIndicesToPlayers(_ indices: [Int]) -> [Player] {
        indices.map { Player(name: spelers[$0]) }
    }

    private var sortedScoresResultaat: [Int] {
        let eindScores = spelers.indices.map { effectieveScore(voor: $0) }
        let geordendeIndices = spelers.indices.sorted { i1, i2 in
            let v1 = totaleVossen[i1]
            let v2 = totaleVossen[i2]
            if v1 != v2 {
                return v1 < v2
            }
            return eindScores[i1] < eindScores[i2]
        }
        return geordendeIndices.map { eindScores[$0] }
    }

    private func resetGame() {
        totaleStrafkaarten = Array(repeating: 0, count: spelers.count)
        rondeStrafkaarten = Array(repeating: 0, count: spelers.count)
        heeftVosOpHand = Array(repeating: false, count: spelers.count)
        handmatigIngevuld.removeAll()
        automatischAangevuldIndex = nil
        rondeGeschiedenis.removeAll()
        huidigeRonde = 1
        activeGameManager.clearActiveGame()
    }

    // MARK: - Draft / Lopend Spel

    private func saveDraft() {
        let scoreSummary = spelers.indices.map { "\(spelers[$0]):\(effectieveScore(voor: $0))" }.joined(separator: ", ")
        let summary = "\(spelers.count) spelers • Ronde \(huidigeRonde) (\(scoreSummary))"

        var state: [String: String] = [:]
        state["ronde"] = "\(huidigeRonde)"
        state["totaleStrafkaarten"] = totaleStrafkaarten.map { "\($0)" }.joined(separator: ",")
        state["rondeStrafkaarten"] = rondeStrafkaarten.map { "\($0)" }.joined(separator: ",")
        state["heeftVosOpHand"] = heeftVosOpHand.map { $0 ? "1" : "0" }.joined(separator: ",")
        state["gameMode"] = gameMode.rawValue
        state["aantalRondesDoel"] = "\(aantalRondesDoel)"
        state["gebruikLimiet"] = gebruikLimiet ? "1" : "0"
        state["limietStrafkaarten"] = "\(limietStrafkaarten)"

        activeGameManager.saveActiveGame(
            gameName: "Fifty Fifty",
            playerNames: spelers,
            currentRound: huidigeRonde,
            summary: summary,
            state: state
        )
    }

    private func restoreDraftIfNeeded() {
        guard let draft = activeGameManager.activeSession,
              draft.gameName == "Fifty Fifty",
              draft.playerNames == spelers else { return }

        if let r = draft.stateData["ronde"], let rInt = Int(r) {
            self.huidigeRonde = rInt
        }
        if let t = draft.stateData["totaleStrafkaarten"] {
            let parts = t.split(separator: ",").compactMap { Int($0) }
            if parts.count == spelers.count {
                self.totaleStrafkaarten = parts
            }
        }
        if let rs = draft.stateData["rondeStrafkaarten"] {
            let parts = rs.split(separator: ",").compactMap { Int($0) }
            if parts.count == spelers.count {
                self.rondeStrafkaarten = parts
                for i in parts.indices where parts[i] > 0 {
                    self.handmatigIngevuld.insert(i)
                }
                controleerEnVulLaatsteSpelerIn()
            }
        }
        if let v = draft.stateData["heeftVosOpHand"] {
            let parts = v.split(separator: ",").map { $0 == "1" }
            if parts.count == spelers.count {
                self.heeftVosOpHand = parts
            }
        }
    }

    // MARK: - Geschiedenis Sheet

    private var historySheet: some View {
        NavigationStack {
            List {
                if rondeGeschiedenis.isEmpty {
                    Text("Nog geen voltooide rondes in dit potje.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Section(
                        header: Text("Voltooide Rondes (\(rondeGeschiedenis.count))"),
                        footer: Text("💡 Tik of houd een ronde ingedrukt om terug te keren naar dat moment.")
                    ) {
                        ForEach(rondeGeschiedenis.reversed()) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        Text("Ronde \(entry.ronde)")
                                            .font(.headline)
                                    }

                                    Spacer()
                                }

                                // Scores tabel
                                VStack(spacing: 4) {
                                    ForEach(spelers.indices, id: \.self) { i in
                                        HStack {
                                            Text(spelers[i])
                                                .font(.caption)
                                                .foregroundColor(.primary)

                                            if entry.vosOpHandDezeRonde[safe: i] == true {
                                                Text("🦊 Vos")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(.red)
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 1)
                                                    .background(Color.red.opacity(0.12))
                                                    .clipShape(Capsule())
                                            }

                                            Spacer()

                                            let rondeKaarten = entry.strafkaartenDezeRonde[safe: i] ?? 0
                                            let totaalKaarten = entry.totaleStrafkaartenNaRonde[safe: i] ?? 0

                                            HStack(spacing: 6) {
                                                Text("+\(rondeKaarten)")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)

                                                Text("\(totaalKaarten) pnt")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(totaalKaarten == 0 ? .green : .primary)
                                            }
                                        }
                                    }
                                }
                                .padding(8)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticManager.shared.light()
                                restoreTargetEntry = entry
                                showRestoreDialog = true
                            }
                            .contextMenu {
                                Button(action: {
                                    openPuntenWijzigenVanuitGeschiedenis()
                                }) {
                                    Label("Punten direct wijzigen", systemImage: "pencil.line")
                                }
                                Button(role: .destructive) {
                                    restoreTargetEntry = entry
                                    showRestoreDialog = true
                                } label: {
                                    Label("Herstel naar Ronde \(entry.ronde)", systemImage: "arrow.counterclockwise")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ronde Geschiedenis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        openPuntenWijzigenVanuitGeschiedenis()
                    }) {
                        Label("Punten wijzigen", systemImage: "pencil.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klaar") {
                        toonGeschiedenisSheet = false
                    }
                }
            }
        }
    }

    private func openPuntenWijzigenVanuitGeschiedenis() {
        toonGeschiedenisSheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showPuntenWijzigenSheet = true
        }
    }
}

// MARK: - Safe Array Indexing Helper
private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationStack {
        FiftyFiftyGameView(spelers: ["Niels", "Lisa", "Mark"])
    }
}
