import SwiftUI

struct PigHoleActionEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    let ronde: Int
    let beurtSpeler: String
    let beurtIndex: Int
    let worpenDezeBeurt: Int
    let actie: String
    let varkensStand: [Int]
    let bordStatus: [Int: Int]
    let varkensgatTotaal: Int

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        ronde: Int,
        beurtSpeler: String,
        beurtIndex: Int,
        worpenDezeBeurt: Int,
        actie: String,
        varkensStand: [Int],
        bordStatus: [Int: Int],
        varkensgatTotaal: Int
    ) {
        self.id = id
        self.timestamp = timestamp
        self.ronde = ronde
        self.beurtSpeler = beurtSpeler
        self.beurtIndex = beurtIndex
        self.worpenDezeBeurt = worpenDezeBeurt
        self.actie = actie
        self.varkensStand = varkensStand
        self.bordStatus = bordStatus
        self.varkensgatTotaal = varkensgatTotaal
    }
}

struct PigHoleGameView: View {
    let spelers: [String]
    let startVarkens: Int
    var penaltyRule: PigHolePenaltyRule = .vakje

    @ObservedObject private var scoreManager = ScoreManager.shared
    private let activeGameManager = ActiveGameManager.shared

    @State private var varkens: [Int]
    @State private var huidigeRonde: Int = 1
    @State private var beurtIndex: Int = 0
    @State private var worpenDezeBeurt: Int = 0
    @State private var bordStatus: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
    @State private var varkensgatTotaal: Int = 0

    @State private var laatsteWorpMelding: String? = nil
    @State private var laatsteWorpCijfer: Int? = nil

    @State private var geschiedenis: [PigHoleActionEntry] = []
    @State private var toonGeschiedenisSheet: Bool = false
    @State private var restoreTargetEntry: PigHoleActionEntry? = nil
    @State private var showRestoreDialog: Bool = false
    @State private var showPuntenWijzigenSheet: Bool = false
    @State private var showWinnaarView: Bool = false
    @State private var winnaarPlayer: Player = Player(name: "")
    @State private var showFinishConfirm: Bool = false

    init(spelers: [String], startVarkens: Int, penaltyRule: PigHolePenaltyRule = .vakje) {
        self.spelers = spelers
        self.startVarkens = startVarkens
        self.penaltyRule = penaltyRule
        _varkens = State(initialValue: Array(repeating: startVarkens, count: spelers.count))
    }

    private var actieveSpelerNaam: String {
        spelers[safe: beurtIndex] ?? "Speler"
    }

    private var volgendeSpelerNaam: String {
        let nextIdx = (beurtIndex + 1) % max(1, spelers.count)
        return spelers[safe: nextIdx] ?? "Volgende"
    }

    private var totaalVarkensOpBord: Int {
        bordStatus.values.reduce(0, +)
    }

    private var rondeRegelTekst: String {
        switch huidigeRonde {
        case 1: return "Ronde 1 • Maximaal 1x gooien per speler"
        case 2: return "Ronde 2 • Maximaal 2x gooien per speler"
        default: return "Ronde \(huidigeRonde) • Gooi zovaak door als je durft!"
        }
    }

    private var magVrijwilligStoppen: Bool {
        if huidigeRonde == 1 {
            return false // Ronde 1 is altijd 1 worp
        } else if huidigeRonde == 2 {
            return worpenDezeBeurt >= 1 // Na 1e worp mag je al stoppen in ronde 2
        } else {
            return worpenDezeBeurt >= 1 // In ronde 3+ mag je na minstens 1 worp altijd stoppen
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                headerView

                // Ronde & Worp Regel Banner
                roundRuleBanner

                // Speelbord Status Kaart
                speelbordStatusCard

                // Dobbelsteen Invoer Kaart (Cijfers 1 t/m 6)
                dobbelsteenInvoerCard

                // Spelers Kaartenlijst
                playersList

                Spacer(minLength: 20)

                // Afronden Knop
                finishButton
            }
            .padding(.vertical)
        }
        .navigationTitle("Pig Hole")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showWinnaarView) {
            WinnaarView(
                gameName: "Pig Hole",
                winnaar: winnaarPlayer,
                sortedSpelers: sortedPlayers,
                sortedScores: sortedScores,
                isLowestScoreWins: true,
                scoreProgression: pigHoleScoreProgression,
                onReset: {
                    resetGame()
                }
            )
        }
        .confirmationDialog("Spel beëindigen?", isPresented: $showFinishConfirm, titleVisibility: .visible) {
            Button("Uitslag opslaan & bekijken") {
                finalizeGame()
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            Text("De speler met de minste overgebleven varkentjes (idealiter 0) wint!")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    Button(action: {
                        showPuntenWijzigenSheet = true
                    }) {
                        Image(systemName: "pencil.circle")
                    }
                    Button(action: {
                        toonGeschiedenisSheet = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
        }
        .sheet(isPresented: $toonGeschiedenisSheet) {
            historySheetView
        }
        .sheet(isPresented: $showPuntenWijzigenSheet) {
            PuntenWijzigenSheet(
                spelers: spelers,
                huidigeScores: varkens,
                titel: "Pig Hole Stand Wijzigen",
                subtitel: "Pas het aantal varkens per speler direct aan.",
                isLowestScoreWins: true
            ) { nieuweScores in
                varkens = nieuweScores
                recordAction(player: "Handmatig", actie: "Stand handmatig gecorrigeerd")
                HapticManager.shared.success()
                saveDraft()
            }
        }
        .confirmationDialog(
            "Herstel actie / ronde?",
            isPresented: $showRestoreDialog,
            titleVisibility: .visible
        ) {
            Button("✏️ Varkens/punten direct wijzigen...") {
                openPuntenWijzigenVanuitGeschiedenis()
            }
            if let entry = restoreTargetEntry {
                Button("Herstel vóór deze actie (Wis deze actie)", role: .destructive) {
                    herstelNaarActie(entry, includeThisAction: false)
                }
                Button("Herstel t/m deze actie") {
                    herstelNaarActie(entry, includeThisAction: true)
                }
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            if let entry = restoreTargetEntry {
                Text("Wil je de stand van het spel terugzetten naar: \(entry.actie) (Ronde \(entry.ronde))? Of pas het aantal varkens direct aan.")
            }
        }
        .onAppear {
            restoreDraftIfNeeded()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            if UIImage(named: "PigHole") != nil {
                Image("PigHole")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: .pink.opacity(0.3), radius: 3, x: 0, y: 1)
            } else {
                Image(systemName: "circle.circle.fill")
                    .foregroundColor(.pink)
                    .font(.system(size: 32))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Pig Hole")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Wie als eerste al zijn varkentjes kwijt is, wint!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // MARK: - Ronde Regel Banner

    private var roundRuleBanner: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.pink)
            Text(rondeRegelTekst)
                .font(.caption)
                .fontWeight(.medium)

            Spacer()

            Button(action: {
                withAnimation {
                    huidigeRonde += 1
                    worpenDezeBeurt = 0
                    recordAction(player: actieveSpelerNaam, actie: "Start Ronde \(huidigeRonde)")
                    HapticManager.shared.light()
                    saveDraft()
                }
            }) {
                HStack(spacing: 4) {
                    Text("Volgende ronde")
                    Image(systemName: "chevron.right")
                }
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.pink)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.pink.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    // MARK: - Speelbord Status Kaart

    private var speelbordStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Speelbord Status", systemImage: "square.grid.3x2.fill")
                    .font(.headline)
                    .foregroundColor(.pink)
                Spacer()
                Text("\(totaalVarkensOpBord) 🐷 op tafel • \(varkensgatTotaal) 🕳️ in gat")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            // Raster van de 6 posities (1 t/m 5 + Gat 6)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(1...5, id: \.self) { nummer in
                    let isBezet = (bordStatus[nummer] ?? 0) > 0

                    Button(action: {
                        // Manuele toggle voor uitzonderingen
                        HapticManager.shared.light()
                        withAnimation {
                            bordStatus[nummer] = isBezet ? 0 : 1
                            saveDraft()
                        }
                    }) {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: diceSymbolName(for: nummer))
                                    .font(.subheadline)
                                Text("Vakje \(nummer)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(isBezet ? .pink : .primary)

                            Text(isBezet ? "🐷 Bezet" : "⚪️ Vrij")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isBezet ? .white : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(isBezet ? Color.pink : Color(UIColor.tertiarySystemGroupedBackground))
                                .clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isBezet ? Color.pink.opacity(0.12) : Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isBezet ? Color.pink : Color.pink.opacity(0.2), lineWidth: isBezet ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Positie 6: Het Varkensgat
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "die.face.6.fill")
                            .font(.subheadline)
                        Text("Pig Hole 6")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.purple)

                    Text("🕳️ \(varkensgatTotaal) kwijt")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.purple)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.purple.opacity(0.12))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.purple.opacity(0.5), lineWidth: 1.5)
                )
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    // MARK: - Dobbelsteen Invoer Kaart

    private var dobbelsteenInvoerCard: some View {
        VStack(spacing: 12) {
            // Beurt & Worp Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: "die.face.5.fill")
                        .foregroundColor(.pink)
                        .font(.system(size: 18, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(actieveSpelerNaam)
                            .font(.headline)
                            .fontWeight(.black)
                        Text("(\(varkens[safe: beurtIndex] ?? 0) 🐷 in hand)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("Worp \(worpenDezeBeurt + 1)\(worpLimietTekst)")
                        .font(.caption2)
                        .foregroundColor(.pink)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Beurt doorgeven knop
                if magVrijwilligStoppen {
                    Button(action: {
                        vrijwilligBeurtStoppen()
                    }) {
                        HStack(spacing: 4) {
                            Text("Beurt stoppen")
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                } else {
                    Button(action: {
                        volgendeSpelerHandmatig()
                    }) {
                        HStack(spacing: 3) {
                            Text("Doorgeven")
                            Image(systemName: "arrow.right.circle")
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(6)
                    }
                }
            }

            Divider()

            // Cijfer Keuzeknoppen (1 t/m 6)
            VStack(alignment: .leading, spacing: 6) {
                Text("Wat heeft \(actieveSpelerNaam) gegooid?")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(1...6, id: \.self) { getal in
                        diceButton(for: getal)
                    }
                }
            }

            // Melding van de laatste worp
            if let melding = laatsteWorpMelding {
                HStack(spacing: 8) {
                    Image(systemName: melding.contains("Pech") ? "exclamationmark.triangle.fill" : (melding.contains("Pig Hole") ? "star.fill" : "checkmark.seal.fill"))
                        .foregroundColor(melding.contains("Pech") ? .orange : (melding.contains("Pig Hole") ? .purple : .green))
                        .font(.caption)

                    Text(melding)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Spacer()

                    // Undo knop direct bij de hand
                    if !geschiedenis.isEmpty {
                        Button(action: {
                            undoLaatsteWorp()
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Herstel")
                            }
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        }
                    }
                }
                .padding(10)
                .background(melding.contains("Pech") ? Color.orange.opacity(0.12) : Color.pink.opacity(0.08))
                .cornerRadius(10)
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.pink.opacity(0.35), lineWidth: 1.5)
        )
        .padding(.horizontal)
    }

    private func diceButton(for getal: Int) -> some View {
        let isHole6 = getal == 6
        let isBezet = (bordStatus[getal] ?? 0) > 0

        return Button(action: {
            voerWorpIn(getal)
        }) {
            VStack(spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: diceSymbolName(for: getal))
                        .font(.title3)
                    Text("\(getal)")
                        .font(.headline)
                        .fontWeight(.black)
                }
                .foregroundColor(isHole6 ? .purple : (isBezet ? .orange : .pink))

                // Status Badge
                if isHole6 {
                    Text("Gat in (-1)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.purple)
                } else if isBezet {
                    Text(penaltyRule == .bord ? "Pak bord!" : "Pakken (+1)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.orange)
                } else {
                    Text("Neerleggen (-1)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isHole6 ? Color.purple.opacity(0.08) : (isBezet ? Color.orange.opacity(0.12) : Color(UIColor.systemBackground)))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHole6 ? Color.purple.opacity(0.4) : (isBezet ? Color.orange.opacity(0.6) : Color.pink.opacity(0.2)), lineWidth: isBezet ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var worpLimietTekst: String {
        switch huidigeRonde {
        case 1: return " (max 1 worp)"
        case 2: return " (max 2 worpen)"
        default: return " (onbeperkt)"
        }
    }

    private func diceSymbolName(for number: Int) -> String {
        switch number {
        case 1: return "die.face.1.fill"
        case 2: return "die.face.2.fill"
        case 3: return "die.face.3.fill"
        case 4: return "die.face.4.fill"
        case 5: return "die.face.5.fill"
        default: return "die.face.6.fill"
        }
    }

    // MARK: - Worp Logica

    private func voerWorpIn(_ getal: Int) {
        guard beurtIndex < spelers.count else { return }
        let spelerNaam = spelers[beurtIndex]
        laatsteWorpCijfer = getal

        if getal == 6 {
            // Varkensgat: permanent kwijt
            HapticManager.shared.medium()
            varkens[beurtIndex] = max(0, varkens[beurtIndex] - 1)
            varkensgatTotaal += 1
            worpenDezeBeurt += 1

            let over = varkens[beurtIndex]
            let omschrijving = "\(spelerNaam) gooit 6! 🎯 Varkentje verdwijnt in het Pig Hole (\(over) over)!"
            laatsteWorpMelding = omschrijving
            recordAction(player: spelerNaam, actie: omschrijving)
            saveDraft()

            if over == 0 {
                HapticManager.shared.celebration()
                finalizeGame()
                return
            }

            // Automatisch beurt wisselen als de rondelimiet bereikt is
            controleerRondeLimiet()

        } else if (1...5).contains(getal) {
            let isBezet = (bordStatus[getal] ?? 0) > 0

            if !isBezet {
                // Vrij vakje: varkentje neerleggen (-1)
                HapticManager.shared.medium()
                varkens[beurtIndex] = max(0, varkens[beurtIndex] - 1)
                bordStatus[getal] = 1
                worpenDezeBeurt += 1

                let over = varkens[beurtIndex]
                let omschrijving = "\(spelerNaam) gooit \(getal). Vakje was vrij: varkentje geplaatst (\(over) over)!"
                laatsteWorpMelding = omschrijving
                recordAction(player: spelerNaam, actie: omschrijving)
                saveDraft()

                if over == 0 {
                    HapticManager.shared.celebration()
                    finalizeGame()
                    return
                }

                controleerRondeLimiet()

            } else {
                // Bezet vakje: PECH! Pak varkens op en beurt is voorbij
                HapticManager.shared.warning()

                let aantalTePakken: Int
                if penaltyRule == .bord {
                    let bordTotaal = bordStatus.values.reduce(0, +)
                    aantalTePakken = max(1, bordTotaal)
                    for k in bordStatus.keys {
                        bordStatus[k] = 0
                    }
                } else {
                    aantalTePakken = bordStatus[getal] ?? 1
                    bordStatus[getal] = 0
                }

                varkens[beurtIndex] += aantalTePakken
                let over = varkens[beurtIndex]
                let omschrijving = "⚠️ Pech! Vakje \(getal) was bezet. \(spelerNaam) moet \(aantalTePakken) \(aantalTePakken == 1 ? "varkentje" : "varkentjes") pakken (\(over) totaal)! Beurt voorbij."
                laatsteWorpMelding = omschrijving
                recordAction(player: spelerNaam, actie: omschrijving)
                saveDraft()

                // Beurt is direct verplicht voorbij
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation {
                        volgendeSpelerNaarVolgende()
                    }
                }
            }
        }
    }

    private func controleerRondeLimiet() {
        if huidigeRonde == 1 && worpenDezeBeurt >= 1 {
            // Ronde 1: max 1 worp
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    volgendeSpelerNaarVolgende()
                }
            }
        } else if huidigeRonde == 2 && worpenDezeBeurt >= 2 {
            // Ronde 2: max 2 worpen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    volgendeSpelerNaarVolgende()
                }
            }
        }
    }

    private func vrijwilligBeurtStoppen() {
        HapticManager.shared.light()
        laatsteWorpMelding = "\(actieveSpelerNaam) stopt de beurt veilig. Nu is \(volgendeSpelerNaam) aan de beurt!"
        withAnimation {
            volgendeSpelerNaarVolgende()
        }
    }

    private func volgendeSpelerHandmatig() {
        HapticManager.shared.light()
        withAnimation {
            volgendeSpelerNaarVolgende()
        }
    }

    private func volgendeSpelerNaarVolgende() {
        worpenDezeBeurt = 0
        let volgendeIndex = (beurtIndex + 1) % max(1, spelers.count)
        if volgendeIndex == 0 {
            huidigeRonde += 1
        }
        beurtIndex = volgendeIndex
        saveDraft()
    }

    private func undoLaatsteWorp() {
        guard let last = geschiedenis.popLast() else { return }
        HapticManager.shared.medium()
        withAnimation {
            varkens = last.varkensStand
            bordStatus = last.bordStatus
            varkensgatTotaal = last.varkensgatTotaal
            huidigeRonde = last.ronde
            beurtIndex = last.beurtIndex
            worpenDezeBeurt = last.worpenDezeBeurt
            laatsteWorpMelding = "Worp ongedaan gemaakt"
            saveDraft()
        }
    }

    // MARK: - Spelers Kaarten

    private var playersList: some View {
        VStack(spacing: 12) {
            ForEach(spelers.indices, id: \.self) { idx in
                let count = varkens[idx]
                let isWinner = count == 0
                let isCurrentTurn = idx == beurtIndex

                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(spelers[idx])
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                if isWinner {
                                    Text("🏆 GEWONNEN!")
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.yellow)
                                        .foregroundColor(.black)
                                        .clipShape(Capsule())
                                } else if isCurrentTurn {
                                    Text("Aan de beurt")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.pink)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }

                            Text(count == 0 ? "Alle varkentjes kwijt!" : "\(count) \(count == 1 ? "varkentje" : "varkentjes") over")
                                .font(.caption2)
                                .foregroundColor(count == 0 ? .green : .secondary)
                        }

                        Spacer()

                        // Grote varkensteller
                        HStack(spacing: 4) {
                            Text("\(count)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(count == 0 ? .green : .primary)
                            Text("🐷")
                                .font(.title2)
                        }
                    }

                    Divider()

                    // Handmatige correctieknoppen
                    HStack(spacing: 8) {
                        Button(action: {
                            if varkens[idx] > 0 {
                                HapticManager.shared.medium()
                                withAnimation {
                                    varkens[idx] -= 1
                                    recordAction(player: spelers[idx], actie: "-1 varken (handmatig)")
                                    saveDraft()
                                    if varkens[idx] == 0 {
                                        finalizeGame()
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "minus.circle.fill")
                                Text("-1 Kwijt")
                            }
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                        .disabled(count <= 0)

                        Button(action: {
                            HapticManager.shared.light()
                            withAnimation {
                                varkens[idx] += 1
                                recordAction(player: spelers[idx], actie: "+1 varken (handmatig)")
                                saveDraft()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("+1 Bezet")
                            }
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Color.orange)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isWinner ? Color.yellow : (isCurrentTurn ? Color.pink.opacity(0.6) : Color.clear), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Afronden Knop

    private var finishButton: some View {
        Button(action: {
            showFinishConfirm = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                Text("Spel Voltooien & Uitslag Bekijken")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.pink)
            .cornerRadius(14)
            .shadow(color: Color.pink.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .padding(.horizontal)
    }

    private func finalizeGame() {
        guard let winner = sortedPlayers.first else { return }
        winnaarPlayer = winner
        activeGameManager.clearActiveGame()
        showWinnaarView = true
    }

    private var pigHoleScoreProgression: [RoundScoreDataPoint] {
        var points: [RoundScoreDataPoint] = []
        for p in spelers {
            points.append(RoundScoreDataPoint(round: 0, playerName: p, cumulativeScore: startVarkens))
        }
        for (idx, entry) in geschiedenis.enumerated() {
            let step = idx + 1
            for (pIdx, p) in spelers.enumerated() {
                let count = entry.varkensStand[safe: pIdx] ?? startVarkens
                points.append(RoundScoreDataPoint(
                    round: step,
                    playerName: p,
                    cumulativeScore: count
                ))
            }
        }
        return points
    }

    private var sortedPlayers: [Player] {
        let pairs = spelers.indices.map { i in
            (player: Player(name: spelers[i]), score: varkens[i])
        }
        return pairs.sorted { $0.score < $1.score }.map { $0.player }
    }

    private var sortedScores: [Int] {
        let pairs = spelers.indices.map { i in
            (player: Player(name: spelers[i]), score: varkens[i])
        }
        return pairs.sorted { $0.score < $1.score }.map { $0.score }
    }

    // MARK: - Draft Bewaren & Herstellen

    private func saveDraft() {
        let scoreSummary = spelers.indices.map { "\(spelers[$0]):\(varkens[$0])" }.joined(separator: ", ")
        let summary = "Ronde \(huidigeRonde) • \(actieveSpelerNaam) • Stand: \(scoreSummary)"

        var state: [String: String] = [:]
        state["huidigeRonde"] = "\(huidigeRonde)"
        state["beurtIndex"] = "\(beurtIndex)"
        state["worpenDezeBeurt"] = "\(worpenDezeBeurt)"
        state["varkensgatTotaal"] = "\(varkensgatTotaal)"
        state["penaltyRule"] = penaltyRule.rawValue
        state["varkens"] = varkens.map { "\($0)" }.joined(separator: ",")
        state["bordStatus"] = (1...5).map { "\($0):\(bordStatus[$0] ?? 0)" }.joined(separator: ",")
        if let melding = laatsteWorpMelding {
            state["laatsteWorpMelding"] = melding
        }

        activeGameManager.saveActiveGame(
            gameName: "Pig Hole",
            playerNames: spelers,
            currentRound: huidigeRonde,
            summary: summary,
            state: state
        )
    }

    private func restoreDraftIfNeeded() {
        guard let draft = activeGameManager.activeSession,
              draft.gameName == "Pig Hole",
              draft.playerNames == spelers else { return }

        if let r = draft.stateData["huidigeRonde"], let rInt = Int(r) {
            self.huidigeRonde = rInt
        }
        if let b = draft.stateData["beurtIndex"], let bInt = Int(b) {
            self.beurtIndex = bInt
        }
        if let w = draft.stateData["worpenDezeBeurt"], let wInt = Int(w) {
            self.worpenDezeBeurt = wInt
        }
        if let g = draft.stateData["varkensgatTotaal"], let gInt = Int(g) {
            self.varkensgatTotaal = gInt
        }
        if let pr = draft.stateData["penaltyRule"], let rule = PigHolePenaltyRule(rawValue: pr) {
            self.penaltyRule = rule
        }
        if let v = draft.stateData["varkens"] {
            let list = v.split(separator: ",").compactMap { Int($0) }
            if list.count == spelers.count {
                self.varkens = list
            }
        }
        if let bs = draft.stateData["bordStatus"] {
            var restoredBord: [Int: Int] = [:]
            for pair in bs.split(separator: ",") {
                let parts = pair.split(separator: ":")
                if parts.count == 2, let k = Int(parts[0]), let val = Int(parts[1]) {
                    restoredBord[k] = val
                }
            }
            if !restoredBord.isEmpty {
                self.bordStatus = restoredBord
            }
        }
        if let m = draft.stateData["laatsteWorpMelding"] {
            self.laatsteWorpMelding = m
        }
    }

    // MARK: - Geschiedenis & Herstel

    private func recordAction(player: String, actie: String) {
        let entry = PigHoleActionEntry(
            ronde: huidigeRonde,
            beurtSpeler: player,
            beurtIndex: beurtIndex,
            worpenDezeBeurt: worpenDezeBeurt,
            actie: actie,
            varkensStand: varkens,
            bordStatus: bordStatus,
            varkensgatTotaal: varkensgatTotaal
        )
        geschiedenis.append(entry)
    }

    private var historySheetView: some View {
        NavigationStack {
            List {
                if geschiedenis.isEmpty {
                    Text("Er zijn nog geen beurten of worpen geregistreerd.")
                        .foregroundColor(.secondary)
                } else {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.yellow)
                            Text("Houd een beurt ingedrukt om de stand daarnaartoe te herstellen.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    ForEach(geschiedenis) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Ronde \(entry.ronde) • \(entry.beurtSpeler)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text(entry.actie)
                                    .font(.caption)
                                    .foregroundColor(.pink)
                                Button(action: {
                                    restoreTargetEntry = entry
                                    showRestoreDialog = true
                                }) {
                                    Image(systemName: "arrow.uturn.backward.circle")
                                        .font(.title3)
                                        .foregroundColor(.orange)
                                }
                                .buttonStyle(.plain)
                            }

                            HStack(spacing: 8) {
                                ForEach(spelers.indices, id: \.self) { idx in
                                    Text("\(spelers[idx]): \(entry.varkensStand[safe: idx] ?? 0)🐷")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onLongPressGesture {
                            HapticManager.shared.medium()
                            restoreTargetEntry = entry
                            showRestoreDialog = true
                        }
                        .contextMenu {
                            Button(action: {
                                openPuntenWijzigenVanuitGeschiedenis()
                            }) {
                                Label("Varkens/stand direct wijzigen", systemImage: "pencil.line")
                            }
                            Button(role: .destructive, action: {
                                herstelNaarActie(entry, includeThisAction: false)
                            }) {
                                Label("Herstel vóór deze actie", systemImage: "arrow.uturn.backward")
                            }
                            Button(action: {
                                herstelNaarActie(entry, includeThisAction: true)
                            }) {
                                Label("Herstel t/m deze actie", systemImage: "arrow.uturn.forward")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rondegeschiedenis")
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

    private func herstelNaarActie(_ entry: PigHoleActionEntry, includeThisAction: Bool) {
        HapticManager.shared.medium()
        guard let idx = geschiedenis.firstIndex(where: { $0.id == entry.id }) else { return }
        let cutoff = includeThisAction ? idx + 1 : idx
        let kept = Array(geschiedenis.prefix(cutoff))

        if let target = includeThisAction ? entry : kept.last {
            varkens = target.varkensStand
            bordStatus = target.bordStatus
            varkensgatTotaal = target.varkensgatTotaal
            huidigeRonde = target.ronde
            beurtIndex = target.beurtIndex
            worpenDezeBeurt = target.worpenDezeBeurt
        } else {
            varkens = Array(repeating: startVarkens, count: spelers.count)
            bordStatus = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
            varkensgatTotaal = 0
            huidigeRonde = 1
            beurtIndex = 0
            worpenDezeBeurt = 0
        }
        geschiedenis = kept
        toonGeschiedenisSheet = false
        saveDraft()
    }

    private func resetGame() {
        varkens = Array(repeating: startVarkens, count: spelers.count)
        bordStatus = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        varkensgatTotaal = 0
        huidigeRonde = 1
        beurtIndex = 0
        worpenDezeBeurt = 0
        geschiedenis = []
        winnaarPlayer = Player(name: "")
        showWinnaarView = false
        activeGameManager.clearActiveGame()
    }
}
