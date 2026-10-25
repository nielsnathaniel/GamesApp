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
    case beurtInvoer = "Beurt voor beurt"
    case eindstand = "Eindstand"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .beurtInvoer: return "hand.tap.fill"
        case .eindstand: return "square.grid.4x4.fill"
        }
    }
}

struct RegenwormenGameView: View {
    var spelers: [Player]

    @ObservedObject private var scoreManager = ScoreManager.shared
    @ObservedObject private var activeGameManager = ActiveGameManager.shared

    // Huidige geselecteerde weergave tab
    @State private var geselecteerdeTab: RegenwormenViewTab

    // Geselecteerde speler voor directe eindstand invoer
    @State private var geselecteerdeSpelerIndexVoorEindstand: Int = 0

    // Actieve speler en beurt (voor beurt-voor-beurt invoer)
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

    // Dialogen en sheets
    @State private var toonGeschiedenisSheet: Bool = false
    @State private var restoreTargetEntry: RegenwormenTurnSnapshot? = nil
    @State private var showRestoreDialog: Bool = false
    @State private var showConfirmMisluktDialog: Bool = false
    @State private var showResetDialog: Bool = false
    @State private var transferPending: (steen: Int, van: Int, naar: Int)? = nil
    @State private var showTransferDialog: Bool = false
    @State private var showWinnaarView: Bool = false
    @State private var winnaar: Player?
    @State private var laatsteMelding: String? = nil

    // Kleurenpalet voor spelers (duidelijk herkenbaar per steen)
    private let spelerKleuren: [Color] = [
        Color(red: 0.18, green: 0.65, blue: 1.00), // Sky Blue
        Color(red: 1.00, green: 0.50, blue: 0.15), // Coral Orange
        Color(red: 0.65, green: 0.30, blue: 0.95), // Purple
        Color(red: 0.18, green: 0.80, blue: 0.44), // Emerald Green
        Color(red: 0.95, green: 0.25, blue: 0.45), // Pink/Red
        Color(red: 0.10, green: 0.85, blue: 0.85), // Cyan
        Color(red: 1.00, green: 0.78, blue: 0.15)  // Amber / Sun Yellow
    ]

    init(spelers: [Player], initialTab: RegenwormenViewTab = .beurtInvoer) {
        self.spelers = spelers
        _geselecteerdeTab = State(initialValue: initialTab)
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
                // Tab Switcher (Eindstand, Beurt Invoer, Scoreverloop Grafiek)
                Picker("Weergave", selection: $geselecteerdeTab) {
                    ForEach(RegenwormenViewTab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Laatste actie / feedback snackbar
                if let melding = laatsteMelding {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(melding)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .transition(.opacity)
                }

                // Huidige weergave
                switch geselecteerdeTab {
                case .beurtInvoer:
                    beurtInvoerView
                case .eindstand:
                    eindstandStenenView
                }

                Spacer(minLength: 16)

                // Spel afronden knop
                finishButton
            }
            .padding(.vertical)
        }
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) {
            if geselecteerdeTab == .beurtInvoer {
                activePlayerStickyHeader
            }
        }
        .background(
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if geselecteerdeTab == .beurtInvoer {
                    LinearGradient(
                        colors: [
                            actieveKleur.opacity(0.25),
                            actieveKleur.opacity(0.14),
                            actieveKleur.opacity(0.04),
                            Color(UIColor.systemGroupedBackground)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.35), value: actieveSpelerIndex)
                } else {
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.14),
                            Color.orange.opacity(0.03),
                            Color(UIColor.systemGroupedBackground)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
            }
        )
        .navigationTitle(geselecteerdeTab == .beurtInvoer ? "Regenwormen • \(actieveSpeler.name)" : "Regenwormen")
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
            "Steen overdragen?",
            isPresented: $showTransferDialog,
            titleVisibility: .visible
        ) {
            if let p = transferPending {
                Button("Verplaats naar \(spelers[p.naar].name)") {
                    bevestigTransfer()
                }
            }
            Button("Annuleren", role: .cancel) {
                transferPending = nil
            }
        } message: {
            if let p = transferPending {
                Text("Steen \(p.steen) is momenteel van \(spelers[p.van].name). Wil je deze toewijzen aan \(spelers[p.naar].name)?")
            }
        }
        .confirmationDialog(
            "Alle stenen wissen?",
            isPresented: $showResetDialog,
            titleVisibility: .visible
        ) {
            Button("Alles wissen", role: .destructive) {
                resetGame()
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            Text("Alle stenen worden weer vrijgegeven.")
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
                Text("De bovenste steen (\(topSteen)) van \(actieveSpeler.name) gaat terug naar de tafel. De hoogste open steen op tafel wordt omgedraaid.")
            } else {
                Text("\(actieveSpeler.name) heeft geen stenen. De hoogste open steen op tafel wordt omgedraaid.")
            }
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
                    scoreProgression: scoreDataPoints,
                    onReset: resetGame
                )
            }
        }
        .onAppear {
            restoreDraftIfNeeded()
        }
    }

    // MARK: - Sticky Pinned Header voor Beurt-Invoer

    private var activePlayerStickyHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Avatar met spelerskleur en puls
                ZStack {
                    Circle()
                        .fill(actieveKleur)
                        .frame(width: 44, height: 44)
                        .shadow(color: actieveKleur.opacity(0.45), radius: 4, x: 0, y: 2)

                    Text(playerInitials(actieveSpeler.name))
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("PUNTEN INVOEREN VOOR:")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(actieveKleur)
                            .tracking(0.6)

                        Text("• Beurt \(beurtNummer)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }

                    Text(actieveSpeler.name)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Spacer()

                // Wissel knop menu om snel van beurt/speler te wisselen indien nodig
                Menu {
                    ForEach(spelers.indices, id: \.self) { idx in
                        Button(action: {
                            withAnimation {
                                actieveSpelerIndex = idx
                            }
                        }) {
                            HStack {
                                Text(spelers[idx].name)
                                if idx == actieveSpelerIndex {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(actieveKleur)
                        .padding(7)
                        .background(actieveKleur.opacity(0.12))
                        .clipShape(Circle())
                }

                // Aantal stenen van deze actieve speler (wormen blijven geheim tijdens het spel)
                let stoneCount = spelerStapels[safe: actieveSpelerIndex]?.count ?? 0
                HStack(spacing: 5) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 13))
                        .foregroundColor(actieveKleur)

                    Text("\(stoneCount)")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(actieveKleur)

                    Text(stoneCount == 1 ? "steen" : "stenen")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(actieveKleur.opacity(0.14))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(actieveKleur.opacity(0.4), lineWidth: 1)
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Color(UIColor.secondarySystemGroupedBackground)
                    .overlay(actieveKleur.opacity(0.12))
            )

            // Dikke gekleurde accent-lijn onderaan
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [actieveKleur, actieveKleur.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .shadow(color: actieveKleur.opacity(0.35), radius: 2, x: 0, y: 1)
        }
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.25), value: actieveSpelerIndex)
    }

    private func playerInitials(_ name: String) -> String {
        let parts = name.split(separator: " ").map { String($0) }
        if parts.count >= 2, let first = parts.first?.first, let second = parts[1].first {
            return "\(first)\(second)".uppercased()
        } else if let first = name.first {
            return String(first).uppercased()
        }
        return "?"
    }

    // MARK: - Modus 1: Eindstand (Stenen invullen per speler)

    private var eindstandStenenView: some View {
        VStack(spacing: 16) {
            // Speler Selector Kaarten
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Kies speler om stenen toe te wijzen:")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("Tik op een steen hieronder")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(spelers.indices, id: \.self) { idx in
                            let player = spelers[idx]
                            let isSelected = geselecteerdeSpelerIndexVoorEindstand == idx
                            let playerColor = kleur(voor: idx)
                            let count = spelerStapels[idx].count

                            Button(action: {
                                HapticManager.shared.selection()
                                geselecteerdeSpelerIndexVoorEindstand = idx
                            }) {
                                VStack(spacing: 4) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(playerColor)
                                            .frame(width: 10, height: 10)
                                        Text(player.name)
                                            .font(.headline)
                                            .foregroundColor(isSelected ? .white : .primary)
                                            .lineLimit(1)
                                    }

                                    HStack(spacing: 4) {
                                        Image(systemName: "square.stack.3d.up.fill")
                                            .font(.caption2)
                                        Text("\(count) \(count == 1 ? "steen" : "stenen")")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(isSelected ? .white : playerColor)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? playerColor : Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(playerColor, lineWidth: isSelected ? 2.5 : 1)
                                )
                                .shadow(color: isSelected ? playerColor.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Indicatie actieve toewijzing & tip
            let activePlayer = spelers[geselecteerdeSpelerIndexVoorEindstand]
            let activeCol = kleur(voor: geselecteerdeSpelerIndexVoorEindstand)
            HStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                    .foregroundColor(activeCol)
                Text("Stenen toewijzen aan ")
                    .foregroundColor(.secondary)
                + Text(activePlayer.name)
                    .bold()
                    .foregroundColor(activeCol)
                + Text(" • Kleurt mee!")
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(activeCol.opacity(0.12))
            .cornerRadius(8)
            .padding(.horizontal)

            // Laatste actie / feedback snackbar
            if let melding = laatsteMelding {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(melding)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .transition(.opacity)
            }

            // Stenen Raster (21 t/m 36)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Regenwormen Stenen (21 t/m 36)", systemImage: "square.grid.4x4.fill")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Spacer()
                    Text("Elke steen max 1x!")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(21...36, id: \.self) { nummer in
                        let info = eigenaar(van: nummer)
                        let wCount = wormen(voor: nummer)

                        Button(action: {
                            toggleSteenVoorEindstand(nummer)
                        }) {
                            VStack(spacing: 3) {
                                Text("\(nummer)")
                                    .font(.title3)
                                    .fontWeight(.black)
                                    .foregroundColor(info != nil ? .primary : Color.primary.opacity(0.85))

                                HStack(spacing: 1.5) {
                                    ForEach(0..<wCount, id: \.self) { _ in
                                        Text("🪱")
                                            .font(.system(size: 9))
                                    }
                                }

                                // Eigenaar Capsule of Vrij
                                if let eig = info {
                                    let eigKleur = kleur(voor: eig.spelerIndex)
                                    Text(spelers[eig.spelerIndex].name)
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1.5)
                                        .background(eigKleur)
                                        .clipShape(Capsule())
                                } else {
                                    Text("Vrij")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1.5)
                                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                Group {
                                    if let eig = info {
                                        kleur(voor: eig.spelerIndex).opacity(0.18)
                                    } else {
                                        Color(UIColor.secondarySystemBackground)
                                    }
                                }
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        info != nil ? kleur(voor: info!.spelerIndex) : Color.orange.opacity(0.3),
                                        lineWidth: info != nil ? 2.5 : 1
                                    )
                            )
                            .shadow(
                                color: info != nil ? kleur(voor: info!.spelerIndex).opacity(0.2) : Color.black.opacity(0.03),
                                radius: 3,
                                x: 0,
                                y: 1
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal)
            }

            Divider()
                .padding(.horizontal)

            // Overzicht per speler met bezeten stenen
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Overzicht Stenen per Speler")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        showResetDialog = true
                    }) {
                        Text("Alles wissen")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 8) {
                    ForEach(spelers.indices, id: \.self) { idx in
                        let player = spelers[idx]
                        let pColor = kleur(voor: idx)
                        let stapel = spelerStapels[idx].sorted()

                        HStack(spacing: 10) {
                            Circle()
                                .fill(pColor)
                                .frame(width: 10, height: 10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name)
                                    .font(.subheadline)
                                    .fontWeight(.bold)

                                if stapel.isEmpty {
                                    Text("Nog geen stenen gekozen")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Stenen: " + stapel.map { "\($0)" }.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Text("\(stapel.count)")
                                    .font(.headline)
                                    .fontWeight(.black)
                                    .foregroundColor(pColor)
                                Text(stapel.count == 1 ? "steen" : "stenen")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    /// Steen aanklikken in de eindstand weergave
    private func toggleSteenVoorEindstand(_ nummer: Int) {
        if let eig = eigenaar(van: nummer) {
            if eig.spelerIndex == geselecteerdeSpelerIndexVoorEindstand {
                // Eigenaar tikt eigen steen aan: ontkoppel steen (maak weer vrij)
                HapticManager.shared.light()
                spelerStapels[geselecteerdeSpelerIndexVoorEindstand].removeAll { $0 == nummer }
                if !tafelStenen.contains(nummer) {
                    tafelStenen.append(nummer)
                    tafelStenen.sort()
                }
                let spelerNaam = spelers[geselecteerdeSpelerIndexVoorEindstand].name
                laatsteMelding = "Steen \(nummer) ontkoppeld van \(spelerNaam)"
                saveDraft()
            } else {
                // Steen is van een andere speler: vraag bevestiging voor overdracht
                HapticManager.shared.warning()
                transferPending = (steen: nummer, van: eig.spelerIndex, naar: geselecteerdeSpelerIndexVoorEindstand)
                showTransferDialog = true
            }
        } else {
            // Steen is nog vrij: wijs toe aan huidige speler
            HapticManager.shared.light()
            tafelStenen.removeAll { $0 == nummer }
            omgedraaideStenen.remove(nummer)
            spelerStapels[geselecteerdeSpelerIndexVoorEindstand].append(nummer)
            let spelerNaam = spelers[geselecteerdeSpelerIndexVoorEindstand].name
            laatsteMelding = "\(spelerNaam) krijgt steen \(nummer)"
            saveDraft()
        }
    }

    private func bevestigTransfer() {
        guard let pending = transferPending else { return }
        HapticManager.shared.medium()
        spelerStapels[pending.van].removeAll { $0 == pending.steen }
        spelerStapels[pending.naar].append(pending.steen)
        let vanNaam = spelers[pending.van].name
        let naarNaam = spelers[pending.naar].name
        laatsteMelding = "Steen \(pending.steen) verplaatst van \(vanNaam) naar \(naarNaam)"
        transferPending = nil
        saveDraft()
    }

    // MARK: - Modus 2: Beurt Invoer (Stenen op tafel + Bovenste steen afpakken)

    private var beurtInvoerView: some View {
        VStack(spacing: 20) {
            // SECTIE 1: Stenen op tafel
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Stenen op tafel", systemImage: "flame.fill")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .lineLimit(1)

                    Spacer()

                    Text("\(tafelStenen.count) open stenen")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal)

                // Duidelijke actieve speler instructie banner (op 1 regel)
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(actieveKleur)
                        .font(.system(size: 12, weight: .semibold))
                    Text("Tik op een steen om te pakken voor ")
                        .foregroundColor(.secondary)
                    + Text(actieveSpeler.name)
                        .bold()
                        .foregroundColor(actieveKleur)
                }
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(actieveKleur.opacity(0.14))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(actieveKleur.opacity(0.35), lineWidth: 1)
                )
                .padding(.horizontal)

                if tafelStenen.isEmpty {
                    VStack(spacing: 6) {
                        Text("🔥 De barbecue is leeg!")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("Er liggen geen stenen meer op tafel. Het spel kan worden afgerond!")
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

            // SECTIE 2: Steen afpakken
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Steen afpakken", systemImage: "hand.raised.fill")
                        .font(.headline)
                        .foregroundColor(.purple)
                        .lineLimit(1)

                    Spacer()

                    Text("Alleen bovenste steen zichtbaar")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal)

                // Duidelijke actieve speler instructie banner voor afpakken (op 1 regel)
                HStack(spacing: 6) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(actieveKleur)
                        .font(.system(size: 12, weight: .semibold))
                    Text("Tik op de bovenste steen om af te pakken voor ")
                        .foregroundColor(.secondary)
                    + Text(actieveSpeler.name)
                        .bold()
                        .foregroundColor(actieveKleur)
                }
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(actieveKleur.opacity(0.14))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(actieveKleur.opacity(0.35), lineWidth: 1)
                )
                .padding(.horizontal)

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

                                    HStack(spacing: 4) {
                                        Image(systemName: "square.stack.3d.up.fill")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("\(otherStapel.count) \(otherStapel.count == 1 ? "steen" : "stenen")")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                // Alleen de LAATSTE (bovenste) steen mag gezien en afgepakt worden!
                                if let steen = topSteen {
                                    Button(action: {
                                        steelSteenVanMedespeler(van: otherIdx, steenNummer: steen)
                                    }) {
                                        miniSteenBadge(nummer: steen, wormenAantal: wormen(voor: steen), tint: otherKleur)
                                            .padding(4)
                                            .background(actieveKleur.opacity(0.14))
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(actieveKleur.opacity(0.4), lineWidth: 1.5)
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

            // SECTIE 3: Mislukte Worp
            VStack(spacing: 8) {
                Button(action: {
                    HapticManager.shared.light()
                    showConfirmMisluktDialog = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "xmark.octagon.fill")
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mislukte Worp (\(actieveSpeler.name))")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Bovenste steen terugleggen & hoogste open steen omdraaien")
                                .font(.caption2)
                                .foregroundColor(.red.opacity(0.85))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.6))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.35), lineWidth: 1.5)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Scoreverloop Datapunten voor Eindstand & Geschiedenis

    private var scoreDataPoints: [RoundScoreDataPoint] {
        var points: [RoundScoreDataPoint] = []

        // Startpunt bij ronde 0 (iedereen 0 wormen)
        for p in spelers {
            points.append(RoundScoreDataPoint(round: 0, playerName: p.name, cumulativeScore: 0))
        }

        // Voeg punten toe uit elke geregistreerde beurt in de geschiedenis
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

        // Huidig punt
        let currentRound = max(1, beurtNummer)
        for (idx, p) in spelers.enumerated() {
            points.append(RoundScoreDataPoint(
                round: currentRound,
                playerName: p.name,
                cumulativeScore: totaleWormen(voor: idx)
            ))
        }

        return points
    }

    // MARK: - Spelacties (Beurt-voor-Beurt)

    /// Actieve speler pakt een steen van de barbecue
    private func pakSteenVanTafel(_ nummer: Int) {
        HapticManager.shared.success()

        // 1. Verwijder van tafel
        tafelStenen.removeAll { $0 == nummer }

        // 2. Leg bovenop stapel van actieve speler
        spelerStapels[actieveSpelerIndex].append(nummer)

        let omschrijving = "\(actieveSpeler.name) pakt steen \(nummer) van tafel"
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
        let omschrijving = "\(actieveSpeler.name) pakt steen \(steenNummer) af van \(targetNaam)!"
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

        if tafelStenen.isEmpty {
            laatsteMelding = "Alle stenen zijn van tafel! Het spel is afgelopen."
            finishGame()
            return
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

        // Automatisch opslaan in ScoreManager INCLUSIEF scoreverloop!
        let playerScoresDetailed = spelers.indices.map { i in
            (player: spelers[i], score: scoresNu[i])
        }
        scoreManager.saveGame(
            gameName: "Regenwormen",
            playerScores: playerScoresDetailed,
            winner: winnaar,
            scoreProgression: scoreDataPoints
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
        let summary = "\(spelers.count) spelers • Stand: \(scoreSummary)"

        var state: [String: String] = [:]
        state["beurtNummer"] = "\(beurtNummer)"
        state["actieveSpelerIndex"] = "\(actieveSpelerIndex)"
        state["tafelStenen"] = tafelStenen.map { "\($0)" }.joined(separator: ",")
        state["omgedraaideStenen"] = Array(omgedraaideStenen).map { "\($0)" }.joined(separator: ",")

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
            HapticManager.shared.celebration()
            finishGame()
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

                                HStack(spacing: 8) {
                                    ForEach(spelers.indices, id: \.self) { i in
                                        let s = entry.spelerStapels[safe: i]?.count ?? 0
                                        Text("\(spelers[i].name): \(s) st")
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
