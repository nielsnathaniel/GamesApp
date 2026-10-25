import SwiftUI
import Charts

/// Model voor één beurt-snapshot (voor geschiedenis, herstellen en de scoreverloop-grafiek)
struct RegenwormenTurnSnapshot: Identifiable {
    let id: UUID
    let beurtNummer: Int
    let spelerIndex: Int
    let spelerNaam: String
    let actieOmschrijving: String
    let tafelStenen: [Int]
    let omgedraaideStenen: Set<Int>
    let spelerStapels: [[Int]]
    let scoresNaBeurt: [Int] // Aantal wormen per speler na deze beurt

    init(
        id: UUID = UUID(),
        beurtNummer: Int,
        spelerIndex: Int,
        spelerNaam: String,
        actieOmschrijving: String,
        tafelStenen: [Int],
        omgedraaideStenen: Set<Int>,
        spelerStapels: [[Int]],
        scoresNaBeurt: [Int]
    ) {
        self.id = id
        self.beurtNummer = beurtNummer
        self.spelerIndex = spelerIndex
        self.spelerNaam = spelerNaam
        self.actieOmschrijving = actieOmschrijving
        self.tafelStenen = tafelStenen
        self.omgedraaideStenen = omgedraaideStenen
        self.spelerStapels = spelerStapels
        self.scoresNaBeurt = scoresNaBeurt
    }
}

enum RegenwormenViewTab: String, CaseIterable, Identifiable {
    case beurtInvoer = "Beurt Invoer"
    case alleStenen = "Stenen Overzicht"
    case scoreGrafiek = "Scoreverloop"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .beurtInvoer: return "hand.tap.fill"
        case .alleStenen: return "square.grid.4x4.fill"
        case .scoreGrafiek: return "chart.xyaxis.line"
        }
    }
}

struct RegenwormenGameView: View {
    var spelers: [Player]

    @ObservedObject private var scoreManager = ScoreManager.shared
    @ObservedObject private var activeGameManager = ActiveGameManager.shared

    // Huidige geselecteerde tab
    @State private var geselecteerdeTab: RegenwormenViewTab = .beurtInvoer

    // Actieve speler en beurt
    @State private var actieveSpelerIndex: Int = 0
    @State private var beurtNummer: Int = 1

    // Staat van de stenen (21..36)
    // Tafelstenen: stenen die nog open op de barbecue liggen (gesorteerd)
    @State private var tafelStenen: [Int] = Array(21...36)
    // Omgedraaide stenen: stenen die na een mislukte worp omgedraaid zijn (uit het spel)
    @State private var omgedraaideStenen: Set<Int> = []
    // Stapel stenen per speler (onderste steen op index 0, bovenste steen op .last)
    @State private var spelerStapels: [[Int]]

    // Geschiedenis van beurten (voor herstel en grafiek)
    @State private var geschiedenis: [RegenwormenTurnSnapshot] = []

    // Dialogen en schermen
    @State private var toonGeschiedenisSheet: Bool = false
    @State private var restoreTargetEntry: RegenwormenTurnSnapshot? = nil
    @State private var showRestoreDialog: Bool = false
    @State private var showConfirmMisluktDialog: Bool = false
    @State private var showConfirmFinishDialog: Bool = false
    @State private var showWinnaarView: Bool = false
    @State private var winnaar: Player?
    @State private var laatsteMelding: String? = nil

    // Kleurenpalet voor spelers
    private let spelerKleuren: [Color] = [
        Color(red: 0.18, green: 0.65, blue: 1.00), // Sky Blue
        Color(red: 1.00, green: 0.50, blue: 0.15), // Coral Orange
        Color(red: 0.65, green: 0.30, blue: 0.95), // Purple
        Color(red: 0.18, green: 0.80, blue: 0.44), // Emerald Green
        Color(red: 0.95, green: 0.25, blue: 0.45), // Pink/Red
        Color(red: 0.10, green: 0.85, blue: 0.85), // Cyan
        Color(red: 1.00, green: 0.78, blue: 0.15)  // Amber / Sun Yellow
    ]

    init(spelers: [Player]) {
        self.spelers = spelers
        _spelerStapels = State(initialValue: Array(repeating: [Int](), count: spelers.count))
    }

    private func kleur(voor spelerIndex: Int) -> Color {
        spelerKleuren[spelerIndex % spelerKleuren.count]
    }

    // Wormwaarde per steen (21..36)
    private func wormen(voor steenNummer: Int) -> Int {
        switch steenNummer {
        case 21...24: return 1
        case 25...28: return 2
        case 29...32: return 3
        default: return 4
        }
    }

    // Totaal aantal wormen voor een speler
    private func totaleWormen(voor spelerIndex: Int) -> Int {
        guard spelerIndex < spelerStapels.count else { return 0 }
        return spelerStapels[spelerIndex].reduce(0) { $0 + wormen(voor: $1) }
    }

    // Eigenaar van een steen (speler-index + of het de bovenste steen is)
    private func eigenaar(van steenNummer: Int) -> (spelerIndex: Int, isBovenste: Bool)? {
        for (idx, stapel) in spelerStapels.enumerated() {
            if let pos = stapel.firstIndex(of: steenNummer) {
                return (spelerIndex: idx, isBovenste: pos == stapel.count - 1)
            }
        }
        return nil
    }

    private var actieveSpeler: Player {
        guard !spelers.isEmpty else { return Player(name: "") }
        return spelers[actieveSpelerIndex % spelers.count]
    }

    private var actieveKleur: Color {
        kleur(voor: actieveSpelerIndex)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header met actieve spelersstatus
                headerView

                // Tab Switcher (Beurt Invoer, Stenen Overzicht, Scoreverloop Grafiek)
                Picker("Weergave", selection: $geselecteerdeTab) {
                    ForEach(RegenwormenViewTab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Huidige geselecteerde weergave
                switch geselecteerdeTab {
                case .beurtInvoer:
                    beurtInvoerView
                case .alleStenen:
                    alleStenenOverzichtView
                case .scoreGrafiek:
                    scoreGrafiekView
                }

                Spacer(minLength: 16)

                // Spel afronden knop
                finishButton
            }
            .padding(.vertical)
        }
        .navigationTitle("Regenwormen")
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
            geschiedenisSheetView
        }
        .confirmationDialog(
            "Mislukte worp?",
            isPresented: $showConfirmMisluktDialog,
            titleVisibility: .visible
        ) {
            Button("Mislukte Worp (Bovenste steen terugleggen)", role: .destructive) {
                voerMislukteWorpUit()
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            if let topSteen = spelerStapels[safe: actieveSpelerIndex]?.last {
                Text("De bovenste steen (\(topSteen), \(wormen(voor: topSteen)) wormen) van \(actieveSpeler.name) gaat terug naar de barbecue. De hoogste open steen op tafel wordt omgedraaid.")
            } else {
                Text("\(actieveSpeler.name) heeft geen stenen. De hoogste open steen op de barbecue wordt omgedraaid.")
            }
        }
        .confirmationDialog(
            "Spel Nu Afronden?",
            isPresented: $showConfirmFinishDialog,
            titleVisibility: .visible
        ) {
            Button("Afronden en Winnaar Bekijken") {
                finishGame()
            }
            Button("Verder Spelen", role: .cancel) {}
        } message: {
            Text("De speler met de meeste regenwormen wint het spel!")
        }
        .confirmationDialog(
            "Beurt herstellen?",
            isPresented: $showRestoreDialog,
            titleVisibility: .visible
        ) {
            if let entry = restoreTargetEntry {
                Button("Herstel naar Beurt \(entry.beurtNummer)", role: .destructive) {
                    herstelNaarBeurt(entry)
                }
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            if let entry = restoreTargetEntry {
                Text("De stand wordt exact teruggezet naar beurt \(entry.beurtNummer) (\(entry.actieOmschrijving)).")
            }
        }
        .navigationDestination(isPresented: $showWinnaarView) {
            if let winnaar = winnaar {
                WinnaarView(
                    gameName: "Regenwormen",
                    winnaar: winnaar,
                    sortedSpelers: sortedSpelersResultaat,
                    sortedScores: sortedScoresResultaat,
                    isLowestScoreWins: false,
                    onReset: resetGame
                )
            }
        }
        .onAppear {
            restoreDraftIfNeeded()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 12) {
            // Live banner actieve speler
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(actieveKleur.opacity(0.2))
                        .frame(width: 46, height: 46)

                    Image(systemName: "dice.fill")
                        .font(.system(size: 24))
                        .foregroundColor(actieveKleur)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Beurt \(beurtNummer)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        Circle()
                            .fill(actieveKleur)
                            .frame(width: 8, height: 8)
                    }

                    Text(actieveSpeler.name)
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Huidige wormen van de actieve speler
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(totaleWormen(voor: actieveSpelerIndex))")
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(actieveKleur)
                        Text("🪱")
                            .font(.title3)
                    }
                    Text("\(spelerStapels[safe: actieveSpelerIndex]?.count ?? 0) stenen")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(actieveKleur.opacity(0.12))
                .cornerRadius(12)
            }
            .padding(.horizontal)

            // Laatste actie / snackbar
            if let melding = laatsteMelding {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(melding)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Tab 1: Beurt Invoer (Stenen op tafel + Afpakken van medespelers)

    private var beurtInvoerView: some View {
        VStack(spacing: 20) {
            // SECTIE 1: Stenen op tafel (De Barbecue / Grill)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Stenen op tafel (Barbecue)", systemImage: "flame.fill")
                        .font(.headline)
                        .foregroundColor(.orange)

                    Spacer()

                    Text("\(tafelStenen.count) open stenen")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                if tafelStenen.isEmpty {
                    VStack(spacing: 6) {
                        Text("🔥 De barbecue is leeg!")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("Er liggen geen stenen meer op tafel. Het spel is klaar om af te ronden!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(tafelStenen, id: \.self) { nummer in
                            Button(action: {
                                pakSteenVanTafel(nummer)
                            }) {
                                dominoTileView(
                                    nummer: nummer,
                                    wormenAantal: wormen(voor: nummer),
                                    accentKleur: .orange,
                                    badgeText: "Op tafel"
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // SECTIE 2: Bovenste stenen van medespelers (Afpakken!)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Bovenste stenen medespelers (Afpakken)", systemImage: "hand.raised.fill")
                        .font(.headline)
                        .foregroundColor(.purple)

                    Spacer()

                    Text("Alleen bovenste steen zichtbaar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Lijst van medespelers
                let medespelers = spelers.indices.filter { $0 != actieveSpelerIndex }
                if medespelers.isEmpty {
                    Text("Geen medespelers")
                        .font(.caption)
                        .padding(.horizontal)
                } else {
                    VStack(spacing: 10) {
                        ForEach(medespelers, id: \.self) { otherIdx in
                            let otherPlayer = spelers[otherIdx]
                            let otherKleur = kleur(voor: otherIdx)
                            let otherStapel = spelerStapels[otherIdx]
                            let topSteen = otherStapel.last
                            let totalWorms = totaleWormen(voor: otherIdx)

                            HStack(spacing: 12) {
                                // Speler info
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(otherKleur)
                                            .frame(width: 8, height: 8)
                                        Text(otherPlayer.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }

                                    HStack(spacing: 6) {
                                        Text("\(totalWorms) 🪱")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(otherKleur)
                                        Text("• \(otherStapel.count) \(otherStapel.count == 1 ? "steen" : "stenen")")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                // Alleen de LAATSTE (bovenste) steen mag gezien en afgepakt worden!
                                if let steen = topSteen {
                                    Button(action: {
                                        steelSteenVanMedespeler(van: otherIdx, steenNummer: steen)
                                    }) {
                                        HStack(spacing: 8) {
                                            VStack(alignment: .trailing, spacing: 1) {
                                                Text("Tik om af te pakken!")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(.purple)
                                                Text("Bovenop: steen \(steen)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }

                                            miniSteenBadge(nummer: steen, wormenAantal: wormen(voor: steen), tint: otherKleur)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.12))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                } else {
                                    Text("Geen stenen")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(12)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
            }

            // SECTIE 3: Snelle beurt acties (Mislukte worp / Pas)
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // Mislukte worp knop
                    Button(action: {
                        HapticManager.shared.light()
                        showConfirmMisluktDialog = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Mislukte Worp")
                        }
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(10)
                    }

                    // Pas / Geen steen beurt
                    Button(action: {
                        HapticManager.shared.light()
                        volgendeBeurt(actieOmschrijving: "\(actieveSpeler.name) past (geen steen)")
                    }) {
                        HStack(spacing: 6) {
                            Text("Pas / Volgende")
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Tab 2: Alle Stenen Overzicht (Wie heeft welke steen?)

    private var alleStenenOverzichtView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Alle 16 Regenwormen Stenen")
                        .font(.headline)
                    Text("Kleur toont wie de steen bezit • Maximaal 1x in heel het spel!")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(21...36, id: \.self) { nummer in
                    let info = eigenaar(van: nummer)
                    let isOmgedraaid = omgedraaideStenen.contains(nummer)

                    VStack(spacing: 2) {
                        Text("\(nummer)")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundColor(isOmgedraaid ? .secondary : .primary)

                        HStack(spacing: 2) {
                            ForEach(0..<wormen(voor: nummer), id: \.self) { _ in
                                Text("🪱")
                                    .font(.system(size: 8))
                            }
                        }

                        // Status / Eigenaar label
                        if let eig = info {
                            let eigKleur = kleur(voor: eig.spelerIndex)
                            Text(spelers[eig.spelerIndex].name)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(eigKleur)
                                .clipShape(Capsule())
                        } else if isOmgedraaid {
                            Text("Omgedraaid")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Op tafel")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Group {
                            if let eig = info {
                                kleur(voor: eig.spelerIndex).opacity(0.18)
                            } else if isOmgedraaid {
                                Color(UIColor.tertiarySystemGroupedBackground)
                            } else {
                                Color.orange.opacity(0.1)
                            }
                        }
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                info != nil ? kleur(voor: info!.spelerIndex) : (isOmgedraaid ? Color.gray.opacity(0.3) : Color.orange.opacity(0.4)),
                                lineWidth: info?.isBovenste == true ? 2 : 1
                            )
                    )
                }
            }
            .padding(.horizontal)

            Divider()
                .padding(.horizontal)

            // Stapels per speler overzicht
            VStack(alignment: .leading, spacing: 8) {
                Text("Stapels per Speler")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 10) {
                    ForEach(spelers.indices, id: \.self) { idx in
                        let player = spelers[idx]
                        let playerKleur = kleur(voor: idx)
                        let stapel = spelerStapels[idx]

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(playerKleur)
                                        .frame(width: 10, height: 10)
                                    Text(player.name)
                                        .font(.headline)
                                }

                                Spacer()

                                Text("\(totaleWormen(voor: idx)) wormen")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(playerKleur)
                            }

                            if stapel.isEmpty {
                                Text("Nog geen stenen gepakt")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(stapel.indices, id: \.self) { sIdx in
                                            let stNum = stapel[sIdx]
                                            let isTop = sIdx == stapel.count - 1
                                            VStack(spacing: 1) {
                                                Text("\(stNum)")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                Text("\(wormen(voor: stNum))🪱")
                                                    .font(.system(size: 8))
                                                if isTop {
                                                    Text("Bovenop")
                                                        .font(.system(size: 7, weight: .bold))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 2)
                                                        .background(playerKleur)
                                                        .clipShape(Capsule())
                                                }
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(playerKleur.opacity(isTop ? 0.25 : 0.12))
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(playerKleur, lineWidth: isTop ? 1.5 : 0.5)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Tab 3: Scoreverloop Grafiek

    private var scoreGrafiekView: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScoreProgressionChartView(
                title: "Regenwormen Scoreverloop",
                dataPoints: scoreDataPoints,
                playerNames: spelers.map { $0.name }
            )
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.orange)
                    Text("Live Scoreverloop per beurt")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                Text("Zie precies wanneer stenen zijn gepakt of afgepakt van medespelers!")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
    }

    private var scoreDataPoints: [RoundScoreDataPoint] {
        var points: [RoundScoreDataPoint] = []

        // Startpunt bij ronde 0 (allemaal 0 wormen)
        for p in spelers {
            points.append(RoundScoreDataPoint(round: 0, playerName: p.name, cumulativeScore: 0))
        }

        // Voeg punten toe uit elke geregistreerde beurt
        for snap in geschiedenis {
            for (idx, p) in spelers.enumerated() {
                let wormScore = snap.scoresNaBeurt[safe: idx] ?? 0
                points.append(RoundScoreDataPoint(
                    round: snap.beurtNummer,
                    playerName: p.name,
                    cumulativeScore: wormScore
                ))
            }
        }

        // Huidige beurtpunt
        for (idx, p) in spelers.enumerated() {
            points.append(RoundScoreDataPoint(
                round: beurtNummer,
                playerName: p.name,
                cumulativeScore: totaleWormen(voor: idx)
            ))
        }

        return points
    }

    // MARK: - Spelacties

    /// Actieve speler pakt een steen van de barbecue
    private func pakSteenVanTafel(_ nummer: Int) {
        HapticManager.shared.success()

        // 1. Verwijder van tafel
        tafelStenen.removeAll { $0 == nummer }

        // 2. Leg bovenop stapel van actieve speler
        spelerStapels[actieveSpelerIndex].append(nummer)

        let wCount = wormen(voor: nummer)
        let omschrijving = "\(actieveSpeler.name) pakt steen \(nummer) (+\(wCount) 🪱) van tafel"
        laatsteMelding = omschrijving

        // 3. Volgende beurt registreren
        volgendeBeurt(actieOmschrijving: omschrijving)
    }

    /// Actieve speler steelt de bovenste steen van een medespeler
    private func steelSteenVanMedespeler(van targetIndex: Int, steenNummer: Int) {
        guard targetIndex < spelerStapels.count,
              let lastSteen = spelerStapels[targetIndex].last,
              lastSteen == steenNummer else { return }

        HapticManager.shared.medium()

        // 1. Haal van bovenkant van medespeler
        spelerStapels[targetIndex].removeLast()

        // 2. Leg bovenop stapel van actieve speler
        spelerStapels[actieveSpelerIndex].append(steenNummer)

        let targetNaam = spelers[targetIndex].name
        let omschrijving = "🪱 \(actieveSpeler.name) steelt steen \(steenNummer) van \(targetNaam)!"
        laatsteMelding = omschrijving

        // 3. Volgende beurt registreren
        volgendeBeurt(actieOmschrijving: omschrijving)
    }

    /// Mislukte worp: leg bovenste steen terug op tafel + draai hoogste steen om
    private func voerMislukteWorpUit() {
        HapticManager.shared.warning()

        var omschrijving = "Mislukte worp van \(actieveSpeler.name)"

        // 1. Als de speler stenen heeft: bovenste steen terug op tafel
        if let top = spelerStapels[actieveSpelerIndex].popLast() {
            if !tafelStenen.contains(top) {
                tafelStenen.append(top)
                tafelStenen.sort()
            }
            omschrijving += ": steen \(top) terug op tafel"
        }

        // 2. Draai de hoogste open steen op tafel om (conform officiële regels)
        if let hoogsteOpen = tafelStenen.max() {
            tafelStenen.removeAll { $0 == hoogsteOpen }
            omgedraaideStenen.insert(hoogsteOpen)
            omschrijving += ", steen \(hoogsteOpen) omgedraaid"
        }

        laatsteMelding = omschrijving
        volgendeBeurt(actieOmschrijving: omschrijving)
    }

    /// Registreert snapshot en schuift beurt door
    private func volgendeBeurt(actieOmschrijving: String) {
        let scoresNu = spelers.indices.map { totaleWormen(voor: $0) }

        let snapshot = RegenwormenTurnSnapshot(
            beurtNummer: beurtNummer,
            spelerIndex: actieveSpelerIndex,
            spelerNaam: actieveSpeler.name,
            actieOmschrijving: actieOmschrijving,
            tafelStenen: tafelStenen,
            omgedraaideStenen: omgedraaideStenen,
            spelerStapels: spelerStapels,
            scoresNaBeurt: scoresNu
        )
        geschiedenis.append(snapshot)

        // Volgende speler
        actieveSpelerIndex = (actieveSpelerIndex + 1) % spelers.count
        beurtNummer += 1
        saveDraft()

        // Als er geen open stenen meer op tafel liggen, meld einde spel
        if tafelStenen.isEmpty {
            laatsteMelding = "Alle stenen zijn van tafel! Het spel is afgelopen."
        }
    }

    /// Herstelt naar een eerdere beurt
    private func herstelNaarBeurt(_ entry: RegenwormenTurnSnapshot) {
        HapticManager.shared.medium()
        withAnimation {
            tafelStenen = entry.tafelStenen
            omgedraaideStenen = entry.omgedraaideStenen
            spelerStapels = entry.spelerStapels
            actieveSpelerIndex = entry.spelerIndex
            beurtNummer = entry.beurtNummer
            laatsteMelding = "Hersteld naar beurt \(entry.beurtNummer)"
            geschiedenis.removeAll { $0.beurtNummer >= entry.beurtNummer }
            toonGeschiedenisSheet = false
            saveDraft()
        }
    }

    // MARK: - Afronden & Winnaar

    private func finishGame() {
        HapticManager.shared.celebration()

        let scoresNu = spelers.indices.map { totaleWormen(voor: $0) }
        let maxScore = scoresNu.max() ?? 0

        // Bepaal winnaar: meeste wormen. Bij gelijkspel: hoogste steen in bezit
        let kandidaten = spelers.indices.filter { scoresNu[$0] == maxScore }
        var winnaarIdx = kandidaten.first ?? 0

        if kandidaten.count > 1 {
            // Tie-breaker: wie heeft de hoogste individuele steen?
            var hoogsteSteen = 0
            for c in kandidaten {
                if let maxSteen = spelerStapels[c].max(), maxSteen > hoogsteSteen {
                    hoogsteSteen = maxSteen
                    winnaarIdx = c
                }
            }
        }

        winnaar = spelers[winnaarIdx]

        // Opslaan in ScoreManager
        let playerScoresDetailed = spelers.indices.map { i in
            (player: spelers[i], score: scoresNu[i])
        }
        scoreManager.saveGame(
            gameName: "Regenwormen",
            playerScores: playerScoresDetailed,
            winner: winnaar
        )

        activeGameManager.clearActiveGame()
        showWinnaarView = true
    }

    private var sortedSpelersResultaat: [Player] {
        let scoresNu = spelers.indices.map { totaleWormen(voor: $0) }
        let geordend = spelers.indices.sorted { scoresNu[$0] > scoresNu[$1] }
        return geordend.map { spelers[$0] }
    }

    private var sortedScoresResultaat: [Int] {
        let scoresNu = spelers.indices.map { totaleWormen(voor: $0) }
        return scoresNu.sorted(by: >)
    }

    private func resetGame() {
        tafelStenen = Array(21...36)
        omgedraaideStenen.removeAll()
        spelerStapels = Array(repeating: [Int](), count: spelers.count)
        geschiedenis.removeAll()
        actieveSpelerIndex = 0
        beurtNummer = 1
        laatsteMelding = nil
        activeGameManager.clearActiveGame()
    }

    // MARK: - Draft / Lopend Spel Bewaren

    private func saveDraft() {
        let scoreSummary = spelers.indices.map { "\(spelers[$0].name):\(totaleWormen(voor: $0))" }.joined(separator: ", ")
        let summary = "\(spelers.count) spelers • Beurt \(beurtNummer) (\(scoreSummary))"

        var state: [String: String] = [:]
        state["beurtNummer"] = "\(beurtNummer)"
        state["actieveSpelerIndex"] = "\(actieveSpelerIndex)"
        state["tafelStenen"] = tafelStenen.map { "\($0)" }.joined(separator: ",")
        state["omgedraaideStenen"] = Array(omgedraaideStenen).map { "\($0)" }.joined(separator: ",")

        // Stapels serialiseren
        for i in spelers.indices {
            state["stapel_\(i)"] = spelerStapels[i].map { "\($0)" }.joined(separator: ",")
        }

        activeGameManager.saveActiveGame(
            gameName: "Regenwormen",
            playerNames: spelers.map { $0.name },
            currentRound: beurtNummer,
            summary: summary,
            state: state
        )
    }

    private func restoreDraftIfNeeded() {
        guard let draft = activeGameManager.activeSession,
              draft.gameName == "Regenwormen",
              draft.playerNames == spelers.map({ $0.name }) else { return }

        if let b = draft.stateData["beurtNummer"], let bInt = Int(b) {
            self.beurtNummer = bInt
        }
        if let a = draft.stateData["actieveSpelerIndex"], let aInt = Int(a) {
            self.actieveSpelerIndex = aInt
        }
        if let t = draft.stateData["tafelStenen"] {
            self.tafelStenen = t.split(separator: ",").compactMap { Int($0) }
        }
        if let o = draft.stateData["omgedraaideStenen"] {
            self.omgedraaideStenen = Set(o.split(separator: ",").compactMap { Int($0) })
        }

        var hersteldeStapels: [[Int]] = []
        for i in spelers.indices {
            if let st = draft.stateData["stapel_\(i)"] {
                let stenen = st.split(separator: ",").compactMap { Int($0) }
                hersteldeStapels.append(stenen)
            } else {
                hersteldeStapels.append([])
            }
        }
        if hersteldeStapels.count == spelers.count {
            self.spelerStapels = hersteldeStapels
        }
    }

    // MARK: - UI Helpers

    private func dominoTileView(
        nummer: Int,
        wormenAantal: Int,
        accentKleur: Color,
        badgeText: String?
    ) -> some View {
        VStack(spacing: 3) {
            Text("\(nummer)")
                .font(.title2)
                .fontWeight(.black)
                .foregroundColor(.primary)

            HStack(spacing: 2) {
                ForEach(0..<wormenAantal, id: \.self) { _ in
                    Text("🪱")
                        .font(.caption2)
                }
            }

            if let badge = badgeText {
                Text(badge)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(accentKleur)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(accentKleur.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentKleur.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 2)
    }

    private func miniSteenBadge(nummer: Int, wormenAantal: Int, tint: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(nummer)")
                .font(.subheadline)
                .fontWeight(.black)
                .foregroundColor(.white)

            HStack(spacing: 1) {
                ForEach(0..<wormenAantal, id: \.self) { _ in
                    Text("🪱")
                        .font(.system(size: 8))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint)
        .cornerRadius(8)
        .shadow(color: tint.opacity(0.4), radius: 3, x: 0, y: 1)
    }

    private var finishButton: some View {
        Button(action: {
            HapticManager.shared.medium()
            showConfirmFinishDialog = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "flag.checkered")
                Text("Spel Afronden & Winnaar Bekijken")
            }
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .cornerRadius(12)
            .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .padding(.horizontal)
    }

    // MARK: - Geschiedenis & Herstel Sheet

    private var geschiedenisSheetView: some View {
        NavigationStack {
            List {
                if geschiedenis.isEmpty {
                    Text("Nog geen beurten geregistreerd.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Section(
                        header: Text("Beurtenverloop (\(geschiedenis.count))"),
                        footer: Text("💡 Tik op een beurt of houd ingedrukt om de stand daarnaartoe te herstellen.")
                    ) {
                        ForEach(geschiedenis.reversed()) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        Text("Beurt \(entry.beurtNummer)")
                                            .font(.headline)
                                    }

                                    Spacer()

                                    Text(entry.spelerNaam)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                }

                                Text(entry.actieOmschrijving)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)

                                // Scores stand na die beurt
                                HStack(spacing: 8) {
                                    ForEach(spelers.indices, id: \.self) { i in
                                        let w = entry.scoresNaBeurt[safe: i] ?? 0
                                        Text("\(spelers[i].name): \(w)🪱")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticManager.shared.light()
                                restoreTargetEntry = entry
                                showRestoreDialog = true
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    restoreTargetEntry = entry
                                    showRestoreDialog = true
                                } label: {
                                    Label("Herstel naar Beurt \(entry.beurtNummer)", systemImage: "arrow.counterclockwise")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Beurtengeschiedenis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klaar") {
                        toonGeschiedenisSheet = false
                    }
                }
            }
        }
    }
}

// MARK: - UI Button Style
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
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
        RegenwormenGameView(spelers: [Player(name: "Niels"), Player(name: "Lisa"), Player(name: "Mark")])
    }
}
