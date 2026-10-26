import SwiftUI

struct LoveLetterCardInfo: Identifiable, Hashable {
    let id: String
    let value: Int
    let name: String
    let subtitle: String
    let copies: Int
    let icon: String
    let color: Color
}

let allLoveLetterCards: [LoveLetterCardInfo] = [
    LoveLetterCardInfo(id: "bisschop", value: 9, name: "Bisschop", subtitle: "Raad handkaart, verdien token als juist", copies: 1, icon: "cross.fill", color: .purple),
    LoveLetterCardInfo(id: "prinses", value: 9, name: "Prinses", subtitle: "Uitgeschakeld als je deze speelt of aflegt", copies: 1, icon: "crown.fill", color: .yellow),
    LoveLetterCardInfo(id: "gravin", value: 8, name: "Gravin", subtitle: "Verplicht spelen als je Koning of Prins hebt", copies: 1, icon: "person.crop.circle.fill", color: .pink),
    LoveLetterCardInfo(id: "koning", value: 7, name: "Koning", subtitle: "Ruil handkaarten met een medespeler", copies: 1, icon: "crown", color: .orange),
    LoveLetterCardInfo(id: "koningin", value: 7, name: "Koningin", subtitle: "Vergelijk handen, hoogste nummer ligt eruit", copies: 1, icon: "sparkles", color: .pink),
    LoveLetterCardInfo(id: "kanonnier", value: 6, name: "Kanonnier", subtitle: "Token als je afvalt met deze in aflegstapel", copies: 1, icon: "scope", color: .brown),
    LoveLetterCardInfo(id: "kanselier", value: 6, name: "Kanselier", subtitle: "Trek 2 kaarten, houd er 1, leg 2 onderop", copies: 2, icon: "scroll.fill", color: .indigo),
    LoveLetterCardInfo(id: "graaf", value: 5, name: "Graaf", subtitle: "+1 per graaf in aflegstapel bij eindtelling", copies: 2, icon: "shield.lefthalf.filled", color: .cyan),
    LoveLetterCardInfo(id: "prins", value: 5, name: "Prins", subtitle: "Handkaart afleggen en nieuwe kaart pakken", copies: 2, icon: "shield.fill", color: .blue),
    LoveLetterCardInfo(id: "kamermeisje", value: 4, name: "Kamermeisje", subtitle: "Bescherming tegen acties tot je volgende beurt", copies: 2, icon: "sparkle", color: .teal),
    LoveLetterCardInfo(id: "baron", value: 3, name: "Baron", subtitle: "Vergelijk handkaarten, de laagste ligt eruit", copies: 2, icon: "scalemass.fill", color: .purple),
    LoveLetterCardInfo(id: "kardinaal", value: 2, name: "Kardinaal", subtitle: "2 spelers wisselen hand, bekijk er één", copies: 2, icon: "arrow.triangle.swap", color: .indigo),
    LoveLetterCardInfo(id: "priester", value: 2, name: "Priester", subtitle: "Bekijk stiekem de handkaart van een ander", copies: 2, icon: "eye.fill", color: .mint),
    LoveLetterCardInfo(id: "wachter", value: 1, name: "Wachter", subtitle: "Raad handkaart; juist = speler ligt eruit", copies: 6, icon: "shield.checkered", color: .red),
    LoveLetterCardInfo(id: "joker", value: 0, name: "Joker / Nar", subtitle: "Kies speler, wint die speler verdien jij +1 token", copies: 1, icon: "theatermasks.fill", color: .orange),
    LoveLetterCardInfo(id: "moordenaar", value: 0, name: "Moordenaar", subtitle: "Speler die wachter tegen jou speelt ligt direct uit ronde", copies: 1, icon: "bolt.shield.fill", color: .black),
    LoveLetterCardInfo(id: "spion", value: 0, name: "Spion", subtitle: "+1 token als niemand anders spion speelt/aflegt", copies: 2, icon: "eyeglasses", color: .gray)
]

enum LoveLetterPreset: String, CaseIterable, Identifiable {
    case standaard = "Standaard"
    case premium = "Premium"
    case premiumPlus = "Premium +"
    case aangepast = "Aangepast"

    var id: String { rawValue }

    var cardIds: Set<String> {
        switch self {
        case .standaard:
            return ["prinses", "gravin", "koning", "kanselier", "prins", "kamermeisje", "baron", "priester", "wachter", "spion"]
        case .premium:
            return ["prinses", "gravin", "koning", "koningin", "kanonnier", "kanselier", "graaf", "prins", "kamermeisje", "baron", "kardinaal", "wachter", "joker", "moordenaar"]
        case .premiumPlus:
            return ["bisschop", "prinses", "gravin", "koning", "koningin", "kanonnier", "kanselier", "graaf", "prins", "kamermeisje", "baron", "kardinaal", "wachter", "spion"]
        case .aangepast:
            return []
        }
    }

    var description: String {
        switch self {
        case .standaard:
            return "Klassieke set voor 2-6 spelers (21 kaarten)"
        case .premium:
            return "Luxe set met o.a. Koningin, Kanonnier, Graaf, Joker & Moordenaar (25 kaarten)"
        case .premiumPlus:
            return "Complete set inclusief de krachtige Bisschop en Spionnen (26 kaarten)"
        case .aangepast:
            return "Aangepaste selectie van speelkaarten"
        }
    }
}

enum LoveLetterWinReason: String, CaseIterable, Identifiable {
    case enigeOver = "Enige overgebleven speler"
    case handenVergelijken = "Handen vergelijken"

    var id: String { rawValue }

    var detailDescription: String {
        switch self {
        case .enigeOver: return "Alle tegenspelers zijn tijdens de ronde afgevallen"
        case .handenVergelijken: return "De trekstapel was leeg; hoogste kaartwaarde wint"
        }
    }

    var icon: String {
        switch self {
        case .enigeOver: return "person.crop.circle.badge.checkmark"
        case .handenVergelijken: return "rectangle.portrait.on.rectangle.portrait.angled.fill"
        }
    }
}

struct LoveLetterRoundBonusResult {
    var spyPlayer: String? = nil
    var kanonnierPlayer: String? = nil
    var bisschopPlayer: String? = nil
    var jokerPlayer: String? = nil
}

struct LoveLetterRoundRecord: Identifiable, Codable {
    var id: UUID = UUID()
    let roundNumber: Int
    var starterName: String = ""
    let winnerName: String
    let reason: String
    let cardValue: Int
    let cardName: String
    let spyBonusPlayer: String?
    var kanonnierBonusPlayer: String? = nil
    var bisschopBonusPlayer: String? = nil
    var jokerBonusPlayer: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, roundNumber, starterName, winnerName, reason, cardValue, cardName
        case spyBonusPlayer, kanonnierBonusPlayer, bisschopBonusPlayer, jokerBonusPlayer
    }

    init(
        id: UUID = UUID(),
        roundNumber: Int,
        starterName: String = "",
        winnerName: String,
        reason: String,
        cardValue: Int,
        cardName: String,
        spyBonusPlayer: String?,
        kanonnierBonusPlayer: String? = nil,
        bisschopBonusPlayer: String? = nil,
        jokerBonusPlayer: String? = nil
    ) {
        self.id = id
        self.roundNumber = roundNumber
        self.starterName = starterName
        self.winnerName = winnerName
        self.reason = reason
        self.cardValue = cardValue
        self.cardName = cardName
        self.spyBonusPlayer = spyBonusPlayer
        self.kanonnierBonusPlayer = kanonnierBonusPlayer
        self.bisschopBonusPlayer = bisschopBonusPlayer
        self.jokerBonusPlayer = jokerBonusPlayer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.roundNumber = try container.decode(Int.self, forKey: .roundNumber)
        self.starterName = try container.decodeIfPresent(String.self, forKey: .starterName) ?? ""
        self.winnerName = try container.decode(String.self, forKey: .winnerName)
        self.reason = try container.decode(String.self, forKey: .reason)
        self.cardValue = try container.decode(Int.self, forKey: .cardValue)
        self.cardName = try container.decode(String.self, forKey: .cardName)
        self.spyBonusPlayer = try container.decodeIfPresent(String.self, forKey: .spyBonusPlayer)
        self.kanonnierBonusPlayer = try container.decodeIfPresent(String.self, forKey: .kanonnierBonusPlayer)
        self.bisschopBonusPlayer = try container.decodeIfPresent(String.self, forKey: .bisschopBonusPlayer)
        self.jokerBonusPlayer = try container.decodeIfPresent(String.self, forKey: .jokerBonusPlayer)
    }
}

struct LoveLetterGameView: View {
    let spelers: [String]
    let doelFiches: Int
    let actieveKaarten: [LoveLetterCardInfo]

    @ObservedObject private var scoreManager = ScoreManager.shared

    @State private var huidigeRonde: Int = 1
    @State private var fichesPerSpeler: [Int]
    @State private var rondeGeschiedenis: [LoveLetterRoundRecord] = []
    @State private var huidigeStarterIndex: Int = 0

    // Sheet voor invoeren ronde winst
    @State private var showRoundCompletionSheet: Bool = false
    @State private var showHistorySheet: Bool = false
    @State private var showCardsOverviewSheet: Bool = false
    @State private var restoreTargetRecord: LoveLetterRoundRecord? = nil
    @State private var showRestoreDialog: Bool = false
    @State private var showPuntenWijzigenSheet: Bool = false
    @State private var showWinnaarView: Bool = false
    @State private var winnaarPlayer: Player = Player(name: "")

    init(
        spelers: [String],
        doelFiches: Int,
        actieveKaarten: [LoveLetterCardInfo] = allLoveLetterCards.filter { LoveLetterPreset.standaard.cardIds.contains($0.id) }
    ) {
        self.spelers = spelers
        self.doelFiches = doelFiches
        self.actieveKaarten = actieveKaarten.isEmpty ? allLoveLetterCards.filter { LoveLetterPreset.standaard.cardIds.contains($0.id) } : actieveKaarten
        _fichesPerSpeler = State(initialValue: Array(repeating: 0, count: spelers.count))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                headerView

                // Startspeler indicator
                starterBanner

                // Spelers score overzicht
                playersListView

                // Ronde Voltooien Hoofdknop
                actionButtons
            }
            .padding(.vertical)
        }
        .navigationTitle("Love Letter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    Button(action: { showPuntenWijzigenSheet = true }) {
                        Image(systemName: "pencil.circle")
                    }

                    Button(action: { showCardsOverviewSheet = true }) {
                        Label("Kaarten", systemImage: "rectangle.portrait.on.rectangle.portrait.angled")
                    }

                    Button(action: { showHistorySheet = true }) {
                        Label("Geschiedenis", systemImage: "clock.arrow.circlepath")
                    }
                }
            }
        }
        .onAppear {
            if huidigeRonde == 1 && !spelers.isEmpty {
                huidigeStarterIndex = Int.random(in: 0..<spelers.count)
            }
        }
        .sheet(isPresented: $showRoundCompletionSheet) {
            LoveLetterRoundInputSheet(
                spelers: spelers,
                roundNumber: huidigeRonde,
                starterName: spelers[safe: huidigeStarterIndex] ?? "",
                actieveKaarten: actieveKaarten,
                onSave: { winnerName, reason, card, bonuses in
                    applyRoundResult(
                        winnerName: winnerName,
                        reason: reason,
                        card: card,
                        bonuses: bonuses
                    )
                }
            )
        }
        .sheet(isPresented: $showHistorySheet) {
            historySheetView
        }
        .sheet(isPresented: $showPuntenWijzigenSheet) {
            PuntenWijzigenSheet(
                spelers: spelers,
                huidigeScores: fichesPerSpeler,
                titel: "Love Letter Fiches Wijzigen",
                subtitel: "Pas het aantal fiches per speler direct aan.",
                isLowestScoreWins: false
            ) { nieuweScores in
                fichesPerSpeler = nieuweScores
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        .sheet(isPresented: $showCardsOverviewSheet) {
            cardsOverviewSheet
        }
        .navigationDestination(isPresented: $showWinnaarView) {
            WinnaarView(
                gameName: "Love Letter",
                winnaar: winnaarPlayer,
                sortedSpelers: sortedPlayers,
                sortedScores: sortedScores,
                isLowestScoreWins: false,
                scoreProgression: loveLetterScoreProgression,
                onReset: {
                    resetGame()
                }
            )
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                if UIImage(named: "LoveLetter") != nil {
                    Image("LoveLetter")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: .pink.opacity(0.3), radius: 3, x: 0, y: 1)
                } else {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                        .font(.system(size: 32))
                }

                Text("Love Letter")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }

            HStack(spacing: 6) {
                Text("Ronde \(huidigeRonde) • Eerste met \(doelFiches) fiches wint!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button(action: { showCardsOverviewSheet = true }) {
                    HStack(spacing: 3) {
                        Image(systemName: "info.circle")
                        Text("\(actieveKaarten.reduce(0) { $0 + $1.copies }) kaarten")
                    }
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.pink.opacity(0.12))
                    .foregroundColor(.pink)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Startspeler Banner

    private var starterBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "sparkle")
                    .foregroundColor(.pink)
                    .font(.system(size: 16, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Startspeler deze ronde:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(spelers[safe: huidigeStarterIndex] ?? "")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Spacer()

            Button(action: {
                withAnimation {
                    huidigeStarterIndex = (huidigeStarterIndex + 1) % max(1, spelers.count)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "die.face.5.fill")
                    Text("Wissel")
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

    // MARK: - Spelers Kaartenlijst

    private var playersListView: some View {
        VStack(spacing: 12) {
            ForEach(spelers.indices, id: \.self) { index in
                let player = spelers[index]
                let score = fichesPerSpeler[safe: index] ?? 0
                let isStarter = index == huidigeStarterIndex
                let isMatchPoint = score == doelFiches - 1

                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(isStarter ? Color.pink : Color.secondary.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Text(playerInitials(player))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(isStarter ? .white : .primary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(player)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                if isStarter {
                                    Text("Startspeler")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.pink)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }

                                if isMatchPoint {
                                    Text("Matchpoint!")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }

                            // Fiches Harten
                            HStack(spacing: 4) {
                                ForEach(0..<doelFiches, id: \.self) { heartIdx in
                                    Image(systemName: heartIdx < score ? "heart.fill" : "heart")
                                        .font(.system(size: 13))
                                        .foregroundColor(heartIdx < score ? .pink : .secondary.opacity(0.3))
                                }
                            }
                        }

                        Spacer()

                        // Score teller
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(score)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(score > 0 ? .pink : .secondary)
                                Text("/\(doelFiches)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text(score == 1 ? "1 fiche" : "\(score) fiches")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isMatchPoint ? Color.orange.opacity(0.5) : (isStarter ? Color.pink.opacity(0.4) : Color.clear), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Actieknoppen

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                showRoundCompletionSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                    Text("Ronde \(huidigeRonde) Uitslag Invoeren")
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

            if !rondeGeschiedenis.isEmpty {
                Button(action: { showHistorySheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet.clipboard.fill")
                        Text("Bekijk Rondelogboek (\(rondeGeschiedenis.count))")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Kaartenoverzicht Sheet

    private var cardsOverviewSheet: some View {
        NavigationStack {
            List {
                Section(
                    header: Text("In het spel (\(actieveKaarten.reduce(0) { $0 + $1.copies }) kaarten in de trekstapel)"),
                    footer: Text("💡 Tik op 'Gereed' om terug te keren naar het spel.")
                ) {
                    ForEach(actieveKaarten) { card in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(card.color.opacity(0.2))
                                    .frame(width: 38, height: 38)
                                Text("\(card.value)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(card.color)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(card.name)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)

                                    Text("(\(card.copies)x)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Image(systemName: card.icon)
                                        .foregroundColor(card.color)
                                        .font(.caption)
                                }

                                Text(card.subtitle)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Actieve Kaarten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Gereed") { showCardsOverviewSheet = false }
                }
            }
        }
    }

    // MARK: - Rondelogboek Sheet

    private var historySheetView: some View {
        NavigationStack {
            List {
                if rondeGeschiedenis.isEmpty {
                    Text("Er zijn nog geen rondes voltooid.")
                        .foregroundColor(.secondary)
                } else {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.yellow)
                            Text("Houd een ronde ingedrukt om de punten te herstellen.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    ForEach(rondeGeschiedenis.reversed()) { round in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ronde \(round.roundNumber)")
                                        .font(.headline)
                                    if !round.starterName.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "dice.fill")
                                                .foregroundColor(.pink)
                                                .font(.caption2)
                                            Text("Begonnen door \(round.starterName)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }

                                Spacer()

                                Button(action: {
                                    restoreTargetRecord = round
                                    showRestoreDialog = true
                                }) {
                                    Label("Herstel", systemImage: "arrow.uturn.backward.circle")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }

                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.pink)
                                        .font(.caption2)
                                    Text("+1 fiche")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.pink)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.pink.opacity(0.12))
                                .clipShape(Capsule())
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text("Winnaar: \(round.winnerName)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            HStack(spacing: 12) {
                                // Handkaart badge
                                HStack(spacing: 4) {
                                    Text("\(round.cardValue)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.pink.opacity(0.2))
                                        .cornerRadius(4)
                                    Text(round.cardName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }

                                // Reden
                                HStack(spacing: 4) {
                                    Image(systemName: round.reason.contains("over") ? "person.crop.circle.badge.checkmark" : "rectangle.portrait.on.rectangle.portrait.angled.fill")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(round.reason)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            if let spy = round.spyBonusPlayer, !spy.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "eyeglasses")
                                        .foregroundColor(.indigo)
                                        .font(.caption2)
                                    Text("Spion-bonus: \(spy) (+1 fiche)")
                                        .font(.caption2)
                                        .foregroundColor(.indigo)
                                }
                            }

                            if let kan = round.kanonnierBonusPlayer, !kan.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "scope")
                                        .foregroundColor(.brown)
                                        .font(.caption2)
                                    Text("Kanonnier-bonus: \(kan) (+1 fiche)")
                                        .font(.caption2)
                                        .foregroundColor(.brown)
                                }
                            }

                            if let bis = round.bisschopBonusPlayer, !bis.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "cross.fill")
                                        .foregroundColor(.purple)
                                        .font(.caption2)
                                    Text("Bisschop-bonus: \(bis) (+1 fiche)")
                                        .font(.caption2)
                                        .foregroundColor(.purple)
                                }
                            }

                            if let jok = round.jokerBonusPlayer, !jok.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "theatermasks.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption2)
                                    Text("Joker-bonus: \(jok) (+1 fiche)")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onLongPressGesture {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            restoreTargetRecord = round
                            showRestoreDialog = true
                        }
                        .contextMenu {
                            Button(action: {
                                openPuntenWijzigenVanuitGeschiedenis()
                            }) {
                                Label("Fiches direct wijzigen", systemImage: "pencil.line")
                            }
                            Button(role: .destructive, action: {
                                herstelNaarRonde(round, includeThisRound: false)
                            }) {
                                Label("Herstel naar stand vóór deze ronde", systemImage: "arrow.uturn.backward")
                            }
                            Button(action: {
                                herstelNaarRonde(round, includeThisRound: true)
                            }) {
                                Label("Zet stand terug naar na deze ronde", systemImage: "arrow.uturn.forward")
                            }
                        }
                    }
                    .onDelete { indexSet in
                        undoRounds(at: indexSet)
                    }
                }
            }
            .navigationTitle("Rondelogboek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        openPuntenWijzigenVanuitGeschiedenis()
                    }) {
                        Label("Fiches wijzigen", systemImage: "pencil.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klaar") { showHistorySheet = false }
                }
            }
            .confirmationDialog(
                "Herstel Ronde \(restoreTargetRecord?.roundNumber ?? 1)?",
                isPresented: $showRestoreDialog,
                titleVisibility: .visible
            ) {
                if let record = restoreTargetRecord {
                    Button("✏️ Fiches direct wijzigen...") {
                        openPuntenWijzigenVanuitGeschiedenis()
                    }
                    Button("Herstel naar stand vóór Ronde \(record.roundNumber) (Wis ronde)", role: .destructive) {
                        herstelNaarRonde(record, includeThisRound: false)
                    }
                    Button("Zet stand terug naar na Ronde \(record.roundNumber)") {
                        herstelNaarRonde(record, includeThisRound: true)
                    }
                    Button("Annuleren", role: .cancel) {}
                }
            } message: {
                if let record = restoreTargetRecord {
                    Text("Wil je de stand van ronde \(record.roundNumber) herstellen? Of pas de fiches direct aan.")
                }
            }
        }
    }

    private func openPuntenWijzigenVanuitGeschiedenis() {
        showHistorySheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showPuntenWijzigenSheet = true
        }
    }

    private func herstelNaarRonde(_ record: LoveLetterRoundRecord, includeThisRound: Bool) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        guard let idx = rondeGeschiedenis.firstIndex(where: { $0.id == record.id }) else { return }

        let keptRecords = includeThisRound ? Array(rondeGeschiedenis.prefix(idx + 1)) : Array(rondeGeschiedenis.prefix(idx))

        // Herbereken de fiches van alle spelers
        fichesPerSpeler = Array(repeating: 0, count: spelers.count)
        for r in keptRecords {
            if let wIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(r.winnerName) == .orderedSame }) {
                fichesPerSpeler[wIdx] += 1
            }
            if let spy = r.spyBonusPlayer, let sIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(spy) == .orderedSame }) {
                fichesPerSpeler[sIdx] += 1
            }
            if let kan = r.kanonnierBonusPlayer, let kIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(kan) == .orderedSame }) {
                fichesPerSpeler[kIdx] += 1
            }
            if let bis = r.bisschopBonusPlayer, let bIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(bis) == .orderedSame }) {
                fichesPerSpeler[bIdx] += 1
            }
            if let jok = r.jokerBonusPlayer, let jIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(jok) == .orderedSame }) {
                fichesPerSpeler[jIdx] += 1
            }
        }

        rondeGeschiedenis = keptRecords
        huidigeRonde = keptRecords.count + 1

        if let last = keptRecords.last,
           let wIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(last.winnerName) == .orderedSame }) {
            huidigeStarterIndex = wIdx
        }

        showHistorySheet = false
    }

    // MARK: - Ronde Verwerken & Opslaan

    private func applyRoundResult(
        winnerName: String,
        reason: LoveLetterWinReason,
        card: LoveLetterCardInfo,
        bonuses: LoveLetterRoundBonusResult
    ) {
        guard let winnerIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(winnerName) == .orderedSame }) else {
            return
        }

        // Startspeler van deze afgeronde ronde
        let currentStarter = spelers[safe: huidigeStarterIndex] ?? winnerName

        // Winnaar krijgt +1 fiche
        fichesPerSpeler[winnerIdx] += 1

        // Eventuele spion bonus
        if let spyName = bonuses.spyPlayer, !spyName.isEmpty,
           let spyIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(spyName) == .orderedSame }) {
            fichesPerSpeler[spyIdx] += 1
        }

        // Eventuele Kanonnier bonus
        if let kanName = bonuses.kanonnierPlayer, !kanName.isEmpty,
           let kanIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(kanName) == .orderedSame }) {
            fichesPerSpeler[kanIdx] += 1
        }

        // Eventuele Bisschop bonus
        if let bisName = bonuses.bisschopPlayer, !bisName.isEmpty,
           let bisIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(bisName) == .orderedSame }) {
            fichesPerSpeler[bisIdx] += 1
        }

        // Eventuele Joker bonus
        if let jokName = bonuses.jokerPlayer, !jokName.isEmpty,
           let jokIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(jokName) == .orderedSame }) {
            fichesPerSpeler[jokIdx] += 1
        }

        // Bewaar in rondelog
        let record = LoveLetterRoundRecord(
            roundNumber: huidigeRonde,
            starterName: currentStarter,
            winnerName: winnerName,
            reason: reason.rawValue,
            cardValue: card.value,
            cardName: card.name,
            spyBonusPlayer: bonuses.spyPlayer,
            kanonnierBonusPlayer: bonuses.kanonnierPlayer,
            bisschopBonusPlayer: bonuses.bisschopPlayer,
            jokerBonusPlayer: bonuses.jokerPlayer
        )
        rondeGeschiedenis.append(record)

        // De winnaar van de ronde is de startspeler voor de volgende ronde! (Officiële regel)
        huidigeStarterIndex = winnerIdx

        // Check of er een algehele winnaar is!
        let maxFiches = fichesPerSpeler.max() ?? 0
        if maxFiches >= doelFiches {
            let bestIdx = fichesPerSpeler.firstIndex(of: maxFiches) ?? winnerIdx
            finalizeGame(winnerName: spelers[bestIdx])
        } else {
            huidigeRonde += 1
        }
    }

    private func undoRounds(at offsets: IndexSet) {
        let reversedHistory = Array(rondeGeschiedenis.reversed())
        for idx in offsets {
            if idx < reversedHistory.count {
                let toRemove = reversedHistory[idx]
                rondeGeschiedenis.removeAll { $0.id == toRemove.id }

                // Trek fiches af
                if let wIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(toRemove.winnerName) == .orderedSame }) {
                    fichesPerSpeler[wIdx] = max(0, fichesPerSpeler[wIdx] - 1)
                }
                if let spy = toRemove.spyBonusPlayer, let sIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(spy) == .orderedSame }) {
                    fichesPerSpeler[sIdx] = max(0, fichesPerSpeler[sIdx] - 1)
                }
                if let kan = toRemove.kanonnierBonusPlayer, let kIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(kan) == .orderedSame }) {
                    fichesPerSpeler[kIdx] = max(0, fichesPerSpeler[kIdx] - 1)
                }
                if let bis = toRemove.bisschopBonusPlayer, let bIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(bis) == .orderedSame }) {
                    fichesPerSpeler[bIdx] = max(0, fichesPerSpeler[bIdx] - 1)
                }
                if let jok = toRemove.jokerBonusPlayer, let jIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(jok) == .orderedSame }) {
                    fichesPerSpeler[jIdx] = max(0, fichesPerSpeler[jIdx] - 1)
                }
            }
        }
        huidigeRonde = max(1, rondeGeschiedenis.count + 1)
        if let last = rondeGeschiedenis.last,
           let wIdx = spelers.firstIndex(where: { $0.caseInsensitiveCompare(last.winnerName) == .orderedSame }) {
            huidigeStarterIndex = wIdx
        }
    }

    private func finalizeGame(winnerName: String) {
        winnaarPlayer = Player(name: winnerName)
        showWinnaarView = true
    }

    private var loveLetterScoreProgression: [RoundScoreDataPoint] {
        var points: [RoundScoreDataPoint] = []
        var runningScores: [String: Int] = [:]
        for p in spelers {
            runningScores[p] = 0
            points.append(RoundScoreDataPoint(roundNumber: 0, roundLabel: "Start", playerName: p, score: 0))
        }

        for (idx, r) in rondeGeschiedenis.enumerated() {
            let roundNum = idx + 1
            if let w = spelers.first(where: { $0.caseInsensitiveCompare(r.winnerName) == .orderedSame }) {
                runningScores[w, default: 0] += 1
            }
            if let spy = r.spyBonusPlayer, let s = spelers.first(where: { $0.caseInsensitiveCompare(spy) == .orderedSame }) {
                runningScores[s, default: 0] += 1
            }
            if let kan = r.kanonnierBonusPlayer, let k = spelers.first(where: { $0.caseInsensitiveCompare(kan) == .orderedSame }) {
                runningScores[k, default: 0] += 1
            }
            if let bis = r.bisschopBonusPlayer, let b = spelers.first(where: { $0.caseInsensitiveCompare(bis) == .orderedSame }) {
                runningScores[b, default: 0] += 1
            }
            if let jok = r.jokerBonusPlayer, let j = spelers.first(where: { $0.caseInsensitiveCompare(jok) == .orderedSame }) {
                runningScores[j, default: 0] += 1
            }

            for p in spelers {
                points.append(RoundScoreDataPoint(
                    roundNumber: roundNum,
                    roundLabel: "Ronde \(roundNum)",
                    playerName: p,
                    score: runningScores[p, default: 0]
                ))
            }
        }
        return points
    }

    private var sortedPlayers: [Player] {
        let pairs = spelers.indices.map { i in
            (player: Player(name: spelers[i]), score: fichesPerSpeler[i])
        }
        return pairs.sorted { $0.score > $1.score }.map { $0.player }
    }

    private var sortedScores: [Int] {
        let pairs = spelers.indices.map { i in
            (player: Player(name: spelers[i]), score: fichesPerSpeler[i])
        }
        return pairs.sorted { $0.score > $1.score }.map { $0.score }
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

    private func resetGame() {
        fichesPerSpeler = Array(repeating: 0, count: spelers.count)
        huidigeRonde = 1
        huidigeStarterIndex = 0
        rondeGeschiedenis = []
        winnaarPlayer = Player(name: "")
        showWinnaarView = false
    }
}

// MARK: - Ronde Invoer Sheet

struct LoveLetterRoundInputSheet: View {
    let spelers: [String]
    let roundNumber: Int
    var starterName: String = ""
    let actieveKaarten: [LoveLetterCardInfo]
    let onSave: (String, LoveLetterWinReason, LoveLetterCardInfo, LoveLetterRoundBonusResult) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedWinner: String = ""
    @State private var selectedReason: LoveLetterWinReason = .enigeOver
    @State private var selectedCard: LoveLetterCardInfo = allLoveLetterCards[1] // default Prinses

    // Bonus toggles en geselecteerde spelers
    @State private var hasSpyBonus: Bool = false
    @State private var selectedSpyPlayer: String = ""

    @State private var hasKanonnierBonus: Bool = false
    @State private var selectedKanonnierPlayer: String = ""

    @State private var hasBisschopBonus: Bool = false
    @State private var selectedBisschopPlayer: String = ""

    @State private var hasJokerBonus: Bool = false
    @State private var selectedJokerPlayer: String = ""

    private var hasAnyBonusCards: Bool {
        actieveKaarten.contains { ["spion", "kanonnier", "bisschop", "joker"].contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Form {
                if !starterName.isEmpty {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "dice.fill")
                                .foregroundColor(.pink)
                            Text("Startspeler deze ronde:")
                                .foregroundColor(.secondary)
                            Text(starterName)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .font(.subheadline)
                    }
                }

                // 1. Wie heeft gewonnen?
                Section(header: Text("1. Wie heeft de ronde gewonnen?")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(spelers, id: \.self) { player in
                                let isSelected = selectedWinner == player
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedWinner = player
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "person.circle.fill")
                                        Text(player)
                                            .fontWeight(isSelected ? .bold : .medium)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.pink : Color(UIColor.secondarySystemGroupedBackground))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? Color.pink : Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // 2. Waarom / Hoe gewonnen?
                Section(header: Text("2. Hoe is de ronde gewonnen?")) {
                    Picker("Reden", selection: $selectedReason) {
                        ForEach(LoveLetterWinReason.allCases) { reason in
                            Label(reason.rawValue, systemImage: reason.icon).tag(reason)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()

                    Text(selectedReason.detailDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 3. Met welke handkaart eindigt de winnaar?
                Section(header: Text("3. Met welke handkaart eindigde de winnaar?")) {
                    ForEach(actieveKaarten) { card in
                        let isSelected = selectedCard.id == card.id
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedCard = card
                        }) {
                            HStack(spacing: 12) {
                                // Kaartwaarde badge
                                ZStack {
                                    Circle()
                                        .fill(card.color.opacity(0.2))
                                        .frame(width: 34, height: 34)
                                    Text("\(card.value)")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(card.color)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(card.name)
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Image(systemName: card.icon)
                                            .font(.caption2)
                                            .foregroundColor(card.color)
                                    }
                                    Text(card.subtitle)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.pink)
                                        .font(.title3)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // 4. Bonussen (+1 fiche per behaalde bonus)
                if hasAnyBonusCards {
                    Section(
                        header: Text("4. Bonussen (+1 fiche per bonus)"),
                        footer: Text("💡 Meerdere bonussen kunnen in dezelfde ronde door verschillende spelers behaald worden.")
                    ) {
                        // Spion Bonus
                        if actieveKaarten.contains(where: { $0.id == "spion" }) {
                            VStack(alignment: .leading, spacing: 6) {
                                Toggle(isOn: $hasSpyBonus) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "eyeglasses")
                                            .foregroundColor(.gray)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("Spion-bonus (+1)")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text("Als enige overlevende een spion gespeeld of afgelegd")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .tint(.pink)

                                if hasSpyBonus {
                                    Picker("Speler met Spion-bonus", selection: $selectedSpyPlayer) {
                                        Text("Kies speler").tag("")
                                        ForEach(spelers, id: \.self) { p in
                                            Text(p).tag(p)
                                        }
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                            .padding(.vertical, 2)
                        }

                        // Kanonnier Bonus
                        if actieveKaarten.contains(where: { $0.id == "kanonnier" }) {
                            VStack(alignment: .leading, spacing: 6) {
                                Toggle(isOn: $hasKanonnierBonus) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "scope")
                                            .foregroundColor(.brown)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("Kanonnier-bonus (+1)")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text("Uitgeschakeld met Kanonnier in eigen aflegstapel")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .tint(.brown)

                                if hasKanonnierBonus {
                                    Picker("Speler met Kanonnier-bonus", selection: $selectedKanonnierPlayer) {
                                        Text("Kies speler").tag("")
                                        ForEach(spelers, id: \.self) { p in
                                            Text(p).tag(p)
                                        }
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                            .padding(.vertical, 2)
                        }

                        // Bisschop Bonus
                        if actieveKaarten.contains(where: { $0.id == "bisschop" }) {
                            VStack(alignment: .leading, spacing: 6) {
                                Toggle(isOn: $hasBisschopBonus) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "cross.fill")
                                            .foregroundColor(.purple)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("Bisschop-bonus (+1)")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text("Juiste handkaart van medespeler geraden")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .tint(.purple)

                                if hasBisschopBonus {
                                    Picker("Speler met Bisschop-bonus", selection: $selectedBisschopPlayer) {
                                        Text("Kies speler").tag("")
                                        ForEach(spelers, id: \.self) { p in
                                            Text(p).tag(p)
                                        }
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                            .padding(.vertical, 2)
                        }

                        // Joker Bonus
                        if actieveKaarten.contains(where: { $0.id == "joker" }) {
                            VStack(alignment: .leading, spacing: 6) {
                                Toggle(isOn: $hasJokerBonus) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "theatermasks.fill")
                                            .foregroundColor(.orange)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("Joker / Nar-bonus (+1)")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text("Speler die winnaar correct heeft voorspeld")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .tint(.orange)

                                if hasJokerBonus {
                                    Picker("Speler met Joker-bonus", selection: $selectedJokerPlayer) {
                                        Text("Kies speler").tag("")
                                        ForEach(spelers, id: \.self) { p in
                                            Text(p).tag(p)
                                        }
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Uitslag Ronde \(roundNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Opslaan") {
                        let bonuses = LoveLetterRoundBonusResult(
                            spyPlayer: hasSpyBonus && !selectedSpyPlayer.isEmpty ? selectedSpyPlayer : nil,
                            kanonnierPlayer: hasKanonnierBonus && !selectedKanonnierPlayer.isEmpty ? selectedKanonnierPlayer : nil,
                            bisschopPlayer: hasBisschopBonus && !selectedBisschopPlayer.isEmpty ? selectedBisschopPlayer : nil,
                            jokerPlayer: hasJokerBonus && !selectedJokerPlayer.isEmpty ? selectedJokerPlayer : nil
                        )
                        onSave(selectedWinner, selectedReason, selectedCard, bonuses)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
                    .disabled(selectedWinner.isEmpty)
                }
            }
            .onAppear {
                if let defaultCard = actieveKaarten.first(where: { $0.id == "prinses" }) ?? actieveKaarten.first {
                    selectedCard = defaultCard
                }
                if let first = spelers.first {
                    selectedWinner = first
                    selectedSpyPlayer = first
                    selectedKanonnierPlayer = first
                    selectedBisschopPlayer = first
                    selectedJokerPlayer = first
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoveLetterGameView(spelers: ["Niels", "Lisa", "Tom"], doelFiches: 4)
    }
}
