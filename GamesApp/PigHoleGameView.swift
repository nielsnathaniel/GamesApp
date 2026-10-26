import SwiftUI

struct PigHoleActionEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    let ronde: Int
    let beurtSpeler: String
    let actie: String
    let varkensStand: [Int]

    init(id: UUID = UUID(), timestamp: Date = Date(), ronde: Int, beurtSpeler: String, actie: String, varkensStand: [Int]) {
        self.id = id
        self.timestamp = timestamp
        self.ronde = ronde
        self.beurtSpeler = beurtSpeler
        self.actie = actie
        self.varkensStand = varkensStand
    }
}

struct PigHoleGameView: View {
    let spelers: [String]
    let startVarkens: Int

    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var varkens: [Int]
    @State private var huidigeRonde: Int = 1
    @State private var beurtIndex: Int = 0
    @State private var geschiedenis: [PigHoleActionEntry] = []
    @State private var toonGeschiedenisSheet: Bool = false
    @State private var restoreTargetEntry: PigHoleActionEntry? = nil
    @State private var showRestoreDialog: Bool = false
    @State private var showPuntenWijzigenSheet: Bool = false
    @State private var showWinnaarView: Bool = false
    @State private var winnaarPlayer: Player = Player(name: "")
    @State private var showFinishConfirm: Bool = false

    init(spelers: [String], startVarkens: Int) {
        self.spelers = spelers
        self.startVarkens = startVarkens
        _varkens = State(initialValue: Array(repeating: startVarkens, count: spelers.count))
    }

    private var rondeRegelTekst: String {
        switch huidigeRonde {
        case 1: return "Ronde 1 • Maximaal 1x gooien per speler"
        case 2: return "Ronde 2 • Maximaal 2x gooien per speler"
        default: return "Ronde \(huidigeRonde) • Gooi zovaak door als je durft!"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                headerView

                // Ronde & Worp Regel Banner
                roundRuleBanner

                // Actieve Speler Banner
                turnBanner

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
                let entry = PigHoleActionEntry(
                    id: UUID(),
                    ronde: huidigeRonde,
                    beurtSpeler: "Handmatige correctie",
                    actie: "Stand handmatig aangepast",
                    varkensStand: nieuweScores
                )
                geschiedenis.append(entry)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
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
                    recordAction(player: spelers[safe: beurtIndex] ?? "", actie: "Start Ronde \(huidigeRonde)")
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

    // MARK: - Beurt Banner

    private var turnBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "die.face.5.fill")
                    .foregroundColor(.pink)
                    .font(.system(size: 16, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Aan de beurt om te dobbelen:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(spelers[safe: beurtIndex] ?? "")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Spacer()

            Button(action: {
                withAnimation {
                    beurtIndex = (beurtIndex + 1) % max(1, spelers.count)
                }
            }) {
                HStack(spacing: 4) {
                    Text("Volgende speler")
                    Image(systemName: "arrow.right.circle.fill")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.pink)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.pink.opacity(0.12))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
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

                    // Actieknoppen voor de speler
                    HStack(spacing: 8) {
                        // Kwijt / Gat (-1)
                        Button(action: {
                            if varkens[idx] > 0 {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation {
                                    varkens[idx] -= 1
                                    recordAction(player: spelers[idx], actie: "-1 varken (kwijt)")
                                    if varkens[idx] == 0 {
                                        finalizeGame()
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "minus.circle.fill")
                                Text("-1 (Kwijt)")
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                        .disabled(count <= 0)

                        // Vakje bezet / gepakt (+1)
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation {
                                varkens[idx] += 1
                                recordAction(player: spelers[idx], actie: "+1 varken")
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("+1")
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .cornerRadius(8)
                        }

                        // Vakje bezet / gepakt (+2)
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation {
                                varkens[idx] += 2
                                recordAction(player: spelers[idx], actie: "+2 varkens")
                            }
                        }) {
                            Text("+2")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.85))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isWinner ? Color.yellow : (isCurrentTurn ? Color.pink.opacity(0.5) : Color.clear), lineWidth: 2)
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
        showWinnaarView = true
    }

    private var pigHoleScoreProgression: [RoundScoreDataPoint] {
        var points: [RoundScoreDataPoint] = []
        for p in spelers {
            points.append(RoundScoreDataPoint(roundNumber: 0, roundLabel: "Start", playerName: p, score: startVarkens))
        }
        for (idx, entry) in geschiedenis.enumerated() {
            let step = idx + 1
            for (pIdx, p) in spelers.enumerated() {
                let count = entry.varkensStand[safe: pIdx] ?? startVarkens
                points.append(RoundScoreDataPoint(
                    roundNumber: step,
                    roundLabel: "Ronde \(entry.ronde)",
                    playerName: p,
                    score: count
                ))
            }
        }
        return points
    }

    // In Pig Hole: de speler met de MINSTE overgebleven varkentjes (0) wint!
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

    // MARK: - Geschiedenis & Herstel

    private func recordAction(player: String, actie: String) {
        let entry = PigHoleActionEntry(
            ronde: huidigeRonde,
            beurtSpeler: player,
            actie: actie,
            varkensStand: varkens
        )
        geschiedenis.append(entry)
    }

    private var historySheetView: some View {
        NavigationStack {
            List {
                if geschiedenis.isEmpty {
                    Text("Er zijn nog geen beurten of acties geregistreerd.")
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
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        guard let idx = geschiedenis.firstIndex(where: { $0.id == entry.id }) else { return }
        let cutoff = includeThisAction ? idx + 1 : idx
        let kept = Array(geschiedenis.prefix(cutoff))

        if let target = includeThisAction ? entry : kept.last {
            varkens = target.varkensStand
            huidigeRonde = target.ronde
            if let sIdx = spelers.firstIndex(of: target.beurtSpeler) {
                beurtIndex = sIdx
            }
        } else {
            varkens = Array(repeating: startVarkens, count: spelers.count)
            huidigeRonde = 1
            beurtIndex = 0
        }
        geschiedenis = kept
        toonGeschiedenisSheet = false
    }

    private func resetGame() {
        varkens = Array(repeating: startVarkens, count: spelers.count)
        huidigeRonde = 1
        beurtIndex = 0
        geschiedenis = []
        winnaarPlayer = Player(name: "")
        showWinnaarView = false
    }
}

#Preview {
    NavigationStack {
        PigHoleGameView(spelers: ["Niels", "Lisa", "Tom"], startVarkens: 15)
    }
}
