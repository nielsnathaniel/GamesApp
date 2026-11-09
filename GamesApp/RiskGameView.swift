import SwiftUI
import AudioToolbox

// MARK: - Modellen

struct RiskMission: Identifiable, Equatable {
    let id: Int
    let title: String
    let description: String
    let targetColor: RiskArmyColor?
}

struct RiskPlayer: Identifiable, Equatable {
    let id: UUID = UUID()
    var name: String
    var armyColor: RiskArmyColor
    var mission: RiskMission?
    var territoriesCount: Int = 0
    var isAlive: Bool = true
}

struct BattleComparison: Identifiable {
    let id = UUID()
    let attackerDie: Int
    let defenderDie: Int
    let attackerWon: Bool
}

struct RiskBattleResult {
    let attackerRolls: [Int]
    let defenderRolls: [Int]
    let attackerLosses: Int
    let defenderLosses: Int
    let comparisons: [BattleComparison]
}

struct RiskBlitzResult {
    let attackerInitial: Int
    let defenderInitial: Int
    let attackerRemaining: Int
    let defenderRemaining: Int
    let attackerWon: Bool
    let totalRounds: Int
}

enum RiskTab: String, CaseIterable, Identifiable {
    case battle = "Gevecht"
    case reinforcements = "Versterkingen"
    case missions = "Missies"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .battle: return "flame.fill"
        case .reinforcements: return "shield.lefthalf.filled"
        case .missions: return "scroll.fill"
        }
    }
}

// MARK: - Risk Game View

struct RiskGameView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @Environment(\.dismiss) private var dismiss

    @State var players: [RiskPlayer]
    let gameMode: RiskGameMode
    let progressiveCards: Bool

    @State private var selectedTab: RiskTab = .battle

    // MARK: - Gevecht State
    @State private var attackerIndex: Int = 0
    @State private var defenderIndex: Int = 1
    @State private var attackerDiceCount: Int = 3
    @State private var defenderDiceCount: Int = 2
    @State private var lastBattleResult: RiskBattleResult? = nil
    @State private var isRolling: Bool = false

    // Blitz State
    @State private var isBlitzMode: Bool = false
    @State private var blitzAttackerArmies: Int = 15
    @State private var blitzDefenderArmies: Int = 8
    @State private var lastBlitzResult: RiskBlitzResult? = nil

    // MARK: - Versterkingen State
    @State private var activePlayerIndex: Int = 0
    @State private var ownedTerritories: Int = 12
    @State private var northAmerica: Bool = false // +5
    @State private var southAmerica: Bool = false // +2
    @State private var europe: Bool = false       // +5
    @State private var africa: Bool = false       // +3
    @State private var asia: Bool = false         // +7
    @State private var australia: Bool = false    // +2
    @State private var cardSetIndex: Int = 0      // 0 = Geen, 1 = Set 1, 2 = Set 2...

    // MARK: - Missies State
    @State private var revealedMissionPlayerId: UUID? = nil
    @State private var missionTimer: Timer? = nil

    // MARK: - Finish Game State
    @State private var showFinishDialog: Bool = false
    @State private var winningPlayerIndex: Int = 0
    @State private var showWinnerScreen: Bool = false
    @State private var winningPlayerObj: Player = Player(name: "")

    var body: some View {
        VStack(spacing: 0) {
            // Tab Selector
            tabSelectorView
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 6)

            // Hoofdweergave op basis van geselecteerde tab
            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .battle:
                        battleSection
                    case .reinforcements:
                        reinforcementsSection
                    case .missions:
                        missionsSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Risk Assistent")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showFinishDialog = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("Winnaar")
                            .font(.subheadline.bold())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.yellow.opacity(0.18))
                    .cornerRadius(8)
                }
            }
        }
        .sheet(isPresented: $showFinishDialog) {
            finishGameSheet
        }
        .navigationDestination(isPresented: $showWinnerScreen) {
            WinnaarView(
                winnaar: winningPlayerObj,
                sortedSpelers: players.map { Player(name: $0.name) },
                sortedScores: players.indices.map { $0 == winningPlayerIndex ? 100 : 0 },
                gameName: "Risk",
                isLowestScoreWins: false,
                onReset: {
                    ActiveGameManager.shared.clearActiveGame()
                    dismiss()
                }
            )
        }
        .onAppear {
            assignSecretMissionsIfNeeded()
            saveDraft()
        }
    }

    // MARK: - Tab Selector
    private var tabSelectorView: some View {
        HStack(spacing: 8) {
            ForEach(RiskTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedTab == tab ? Color.red : Color(UIColor.secondarySystemGroupedBackground))
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                    .cornerRadius(12)
                    .shadow(color: selectedTab == tab ? Color.red.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                }
            }
        }
    }

    // MARK: - 1. GEVECHT SECTIE
    private var battleSection: some View {
        VStack(spacing: 16) {
            // Keuze Handmatig vs Blitz
            Picker("Gevechtstype", selection: $isBlitzMode) {
                Text("🎲 Dobbelen").tag(false)
                Text("⚡ Blitz Gevecht").tag(true)
            }
            .pickerStyle(.segmented)

            if !isBlitzMode {
                manualBattleView
            } else {
                blitzBattleView
            }
        }
    }

    // Handmatige Dobbelsteen Arena
    private var manualBattleView: some View {
        VStack(spacing: 16) {
            // Aanvaller & Verdediger Kiezers
            HStack(spacing: 12) {
                // Aanvaller kaart
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.red)
                        Text("AANVALLER")
                            .font(.caption2.bold())
                            .foregroundColor(.red)
                    }

                    if !players.isEmpty {
                        Menu {
                            ForEach(players.indices, id: \.self) { idx in
                                Button(players[idx].name) {
                                    attackerIndex = idx
                                    if defenderIndex == idx {
                                        defenderIndex = (idx + 1) % players.count
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Circle()
                                    .fill(players[attackerIndex].armyColor.color)
                                    .frame(width: 12, height: 12)
                                Text(players[attackerIndex].name)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                        }
                    }

                    // Aantal dobbelstenen (1, 2, 3)
                    HStack {
                        Text("Dobbelstenen:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("Aanvaller Dobbelstenen", selection: $attackerDiceCount) {
                            Text("1").tag(1)
                            Text("2").tag(2)
                            Text("3").tag(3)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 110)
                    }
                }
                .padding(12)
                .background(Color.red.opacity(0.08))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.3), lineWidth: 1))

                // Verdediger kaart
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.blue)
                        Text("VERDEDIGER")
                            .font(.caption2.bold())
                            .foregroundColor(.blue)
                    }

                    if !players.isEmpty {
                        Menu {
                            ForEach(players.indices, id: \.self) { idx in
                                Button(players[idx].name) {
                                    defenderIndex = idx
                                    if attackerIndex == idx {
                                        attackerIndex = (idx + 1) % players.count
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Circle()
                                    .fill(players[defenderIndex].armyColor.color)
                                    .frame(width: 12, height: 12)
                                Text(players[defenderIndex].name)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                        }
                    }

                    // Aantal dobbelstenen (1, 2)
                    HStack {
                        Text("Dobbelstenen:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("Verdediger Dobbelstenen", selection: $defenderDiceCount) {
                            Text("1").tag(1)
                            Text("2").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 80)
                    }
                }
                .padding(12)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.3), lineWidth: 1))
            }

            // Grote Dobbel Knop
            Button {
                rollDiceAction()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "dice.fill")
                        .font(.title3)
                    Text("Gooi Dobbelstenen!")
                        .font(.headline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LinearGradient(colors: [Color.red, Color(red: 0.8, green: 0.1, blue: 0.2)], startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: Color.red.opacity(0.35), radius: 6, x: 0, y: 3)
            }

            // Uitslag & Dobbelstenen Visualisatie
            if let result = lastBattleResult {
                VStack(spacing: 14) {
                    Text("Uitslag Gevecht")
                        .font(.headline)

                    // Dobbelstenen weergave
                    HStack(spacing: 24) {
                        // Aanvaller stenen
                        VStack(spacing: 6) {
                            Text("Aanvaller")
                                .font(.caption2.bold())
                                .foregroundColor(.red)
                            HStack(spacing: 8) {
                                ForEach(result.attackerRolls.indices, id: \.self) { i in
                                    RiskDieView(value: result.attackerRolls[i], isAttacker: true)
                                }
                            }
                        }

                        // VS scheiding
                        Text("VS")
                            .font(.caption.weight(.black))
                            .foregroundColor(.secondary)
                            .padding(.top, 14)

                        // Verdediger stenen
                        VStack(spacing: 6) {
                            Text("Verdediger")
                                .font(.caption2.bold())
                                .foregroundColor(.blue)
                            HStack(spacing: 8) {
                                ForEach(result.defenderRolls.indices, id: \.self) { i in
                                    RiskDieView(value: result.defenderRolls[i], isAttacker: false)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)

                    Divider()

                    // Vergelijking details
                    VStack(spacing: 8) {
                        ForEach(result.comparisons.indices, id: \.self) { idx in
                            let comp = result.comparisons[idx]
                            HStack {
                                Text("Vergelijking #\(idx + 1):")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(comp.attackerDie)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.red)
                                Text("vs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(comp.defenderDie)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.blue)

                                Spacer()

                                if comp.attackerWon {
                                    Text("🛡️ Verdediger -1 leger")
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                } else {
                                    Text("💀 Aanvaller -1 leger")
                                        .font(.caption.bold())
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }

                    // Totaal verlies badge
                    HStack(spacing: 16) {
                        HStack {
                            Text("Aanvaller verliest:")
                                .font(.caption)
                            Text("\(result.attackerLosses)")
                                .font(.subheadline.bold())
                                .foregroundColor(result.attackerLosses > 0 ? .red : .primary)
                        }
                        Divider().frame(height: 16)
                        HStack {
                            Text("Verdediger verliest:")
                                .font(.caption)
                            Text("\(result.defenderLosses)")
                                .font(.subheadline.bold())
                                .foregroundColor(result.defenderLosses > 0 ? .red : .primary)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
        }
    }

    // Blitz Gevecht Arena
    private var blitzBattleView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("⚡ Blitz Simulator (Vecht tot de dood)")
                    .font(.headline)
                Text("Simuleer direct een heel gevecht beurt voor beurt volgens de officiële Risk-regels tot één partij wint of de aanvaller niet meer kan aanvallen.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 14) {
                // Aanvaller legers stepper
                VStack(spacing: 6) {
                    Text("Aanvallende legers")
                        .font(.caption2.bold())
                        .foregroundColor(.red)

                    Text("\(blitzAttackerArmies)")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.red)

                    HStack(spacing: 10) {
                        Button {
                            if blitzAttackerArmies > 2 { blitzAttackerArmies -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }

                        Button {
                            blitzAttackerArmies += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                        }
                    }

                    HStack(spacing: 4) {
                        Button("+5") { blitzAttackerArmies += 5 }
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(4)
                        Button("+10") { blitzAttackerArmies += 10 }
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.red.opacity(0.07))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.3), lineWidth: 1))

                // Verdediger legers stepper
                VStack(spacing: 6) {
                    Text("Verdedigende legers")
                        .font(.caption2.bold())
                        .foregroundColor(.blue)

                    Text("\(blitzDefenderArmies)")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.blue)

                    HStack(spacing: 10) {
                        Button {
                            if blitzDefenderArmies > 1 { blitzDefenderArmies -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }

                        Button {
                            blitzDefenderArmies += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }

                    HStack(spacing: 4) {
                        Button("+5") { blitzDefenderArmies += 5 }
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(4)
                        Button("+10") { blitzDefenderArmies += 10 }
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.blue.opacity(0.07))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.3), lineWidth: 1))
            }

            // Start Blitz Knop
            Button {
                runBlitzSimulationAction()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                    Text("Start Blitz Simulatie!")
                        .font(.headline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LinearGradient(colors: [Color.orange, Color.red], startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: Color.orange.opacity(0.3), radius: 6, x: 0, y: 3)
            }

            // Blitz Resultaat
            if let blitz = lastBlitzResult {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: blitz.attackerWon ? "crown.fill" : "shield.lefthalf.filled")
                            .font(.title2)
                            .foregroundColor(blitz.attackerWon ? .green : .blue)
                        Text(blitz.attackerWon ? "Aanvaller Heeft Gewonnen!" : "Verdediger Houdt Stand!")
                            .font(.headline.bold())
                            .foregroundColor(blitz.attackerWon ? .green : .blue)
                    }

                    Text("Uitgevochten in \(blitz.totalRounds) gevechtsrondes.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("Aanvaller")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                            Text("\(blitz.attackerRemaining) over")
                                .font(.title3.bold())
                            Text("(-\(blitz.attackerInitial - blitz.attackerRemaining) verloren)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Divider().frame(height: 36)

                        VStack(spacing: 4) {
                            Text("Verdediger")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                            Text("\(blitz.defenderRemaining) over")
                                .font(.title3.bold())
                            Text("(-\(blitz.defenderInitial - blitz.defenderRemaining) verloren)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
        }
    }

    // MARK: - 2. VERSTERKINGEN CALCULATOR
    private var reinforcementsSection: some View {
        VStack(spacing: 16) {
            // Hero Kaart Totaal Legers
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nieuwe Legers Deze Beurt")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text("\(totalReinforcements) Legers")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.green)
                    Text("Plaats deze legers op jouw bezette gebieden.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)

            // Stap 1: Aantal Gebieden
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("1. Bezette Gebieden", systemImage: "map.fill")
                        .font(.headline)
                    Spacer()
                    Text("\(ownedTerritories) gebieden ➔ +\(max(3, ownedTerritories / 3)) legers")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                }

                Stepper(value: $ownedTerritories, in: 3...42) {
                    Text("Aantal gebieden in bezit: **\(ownedTerritories)**")
                        .font(.subheadline)
                }

                Text("Formule: aantal gebieden ÷ 3 (naar beneden afgerond, minimaal altijd 3 legers).")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)

            // Stap 2: Continent Bonussen
            VStack(alignment: .leading, spacing: 12) {
                Label("2. Continent Bonussen", systemImage: "globe.europe.africa.fill")
                    .font(.headline)

                Text("Selecteer continenten die je volledig in bezit hebt:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    continentToggle(name: "Noord-Amerika", bonus: "+5", isOn: $northAmerica)
                    continentToggle(name: "Zuid-Amerika", bonus: "+2", isOn: $southAmerica)
                    continentToggle(name: "Europa", bonus: "+5", isOn: $europe)
                    continentToggle(name: "Afrika", bonus: "+3", isOn: $africa)
                    continentToggle(name: "Azië", bonus: "+7", isOn: $asia)
                    continentToggle(name: "Australië", bonus: "+2", isOn: $australia)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)

            // Stap 3: Kaartensets Inleveren
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("3. Kaartenset Inleveren", systemImage: "square.stack.3d.up.fill")
                        .font(.headline)
                    Spacer()
                    Text("+\(cardsBonusArmies) legers")
                        .font(.caption.bold())
                        .foregroundColor(cardsBonusArmies > 0 ? .green : .secondary)
                }

                if progressiveCards {
                    Picker("Kaartenset", selection: $cardSetIndex) {
                        Text("Geen (0)").tag(0)
                        Text("1e set (+4)").tag(1)
                        Text("2e set (+6)").tag(2)
                        Text("3e set (+8)").tag(3)
                        Text("4e set (+10)").tag(4)
                        Text("5e set (+12)").tag(5)
                        Text("6e set (+15)").tag(6)
                        Text("7e set (+20)").tag(7)
                    }
                    .pickerStyle(.menu)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                } else {
                    Picker("Vaste Kaartenset", selection: $cardSetIndex) {
                        Text("Geen (0)").tag(0)
                        Text("3 Infanterie (+4)").tag(1)
                        Text("3 Cavalerie (+6)").tag(2)
                        Text("3 Artillerie (+8)").tag(3)
                        Text("1 van elk (+10)").tag(4)
                    }
                    .pickerStyle(.menu)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }

    private func continentToggle(name: String, bonus: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                    Text(bonus)
                        .font(.caption2.bold())
                        .foregroundColor(isOn.wrappedValue ? .green : .secondary)
                }
                Spacer()
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOn.wrappedValue ? .green : .secondary)
            }
            .padding(10)
            .background(isOn.wrappedValue ? Color.green.opacity(0.12) : Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isOn.wrappedValue ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
    }

    private var totalReinforcements: Int {
        let base = max(3, ownedTerritories / 3)
        var continentTotal = 0
        if northAmerica { continentTotal += 5 }
        if southAmerica { continentTotal += 2 }
        if europe { continentTotal += 5 }
        if africa { continentTotal += 3 }
        if asia { continentTotal += 7 }
        if australia { continentTotal += 2 }
        return base + continentTotal + cardsBonusArmies
    }

    private var cardsBonusArmies: Int {
        if cardSetIndex == 0 { return 0 }
        if progressiveCards {
            switch cardSetIndex {
            case 1: return 4
            case 2: return 6
            case 3: return 8
            case 4: return 10
            case 5: return 12
            case 6: return 15
            case 7: return 20
            default: return 20 + ((cardSetIndex - 7) * 5)
            }
        } else {
            switch cardSetIndex {
            case 1: return 4
            case 2: return 6
            case 3: return 8
            case 4: return 10
            default: return 0
            }
        }
    }

    // MARK: - 3. GEHEIME MISSIES SECTIE
    private var missionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Geheime Opdrachten", systemImage: "eye.slash.fill")
                    .font(.headline)
                Spacer()
                Text("🔒 Privacy Beveiligd")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
            }

            Text("Houd je vinger op een kaart ingedrukt om jouw geheime missie te bekijken. Laat los om direct weer te verbergen voor medespelers.")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(players.indices, id: \.self) { idx in
                let player = players[idx]
                let isRevealed = (revealedMissionPlayerId == player.id)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Circle()
                            .fill(player.armyColor.color)
                            .frame(width: 14, height: 14)
                        Text(player.name)
                            .font(.subheadline.bold())
                        Text("(\(player.armyColor.rawValue))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()

                        Text(isRevealed ? "ZICHTBAAR" : "VERBORGEN")
                            .font(.caption2.bold())
                            .foregroundColor(isRevealed ? .orange : .secondary)
                    }

                    if isRevealed, let mission = player.mission {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(mission.title)
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(mission.description)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(10)
                        .transition(.opacity.combined(with: .scale))
                    } else {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.blue)
                            Text("Houd ingedrukt om missie te bekijken")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 0.2, pressing: { isPressing in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        revealedMissionPlayerId = isPressing ? player.id : nil
                    }
                }, perform: {})
            }
        }
    }

    // MARK: - Afronden & Winnaar Opslaan Sheet
    private var finishGameSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "trophy.circle.fill")
                        .font(.system(size: 54))
                        .foregroundColor(.yellow)

                    Text("Kies de Winnaar")
                        .font(.title2.bold())

                    Text("Selecteer de speler die de geheime missie heeft volbracht of werelddominantie heeft bereikt.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)

                VStack(spacing: 10) {
                    ForEach(players.indices, id: \.self) { idx in
                        Button {
                            winningPlayerIndex = idx
                        } label: {
                            HStack {
                                Circle()
                                    .fill(players[idx].armyColor.color)
                                    .frame(width: 18, height: 18)
                                Text(players[idx].name)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                Spacer()
                                if winningPlayerIndex == idx {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title3)
                                }
                            }
                            .padding()
                            .background(winningPlayerIndex == idx ? Color.green.opacity(0.12) : Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(winningPlayerIndex == idx ? Color.green : Color.clear, lineWidth: 1.5)
                            )
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    saveFinishedGameAction()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Opslaan & Vieren!")
                            .font(.headline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient(colors: [Color.green, Color(red: 0.1, green: 0.6, blue: 0.3)], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal)
                    .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") { showFinishDialog = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Gevechtsacties

    private func rollDiceAction() {
        let attRolls = (0..<attackerDiceCount).map { _ in Int.random(in: 1...6) }.sorted(by: >)
        let defRolls = (0..<defenderDiceCount).map { _ in Int.random(in: 1...6) }.sorted(by: >)

        var attLoss = 0
        var defLoss = 0
        var comparisons: [BattleComparison] = []

        let compareCount = min(attRolls.count, defRolls.count)
        for i in 0..<compareCount {
            let att = attRolls[i]
            let def = defRolls[i]
            if att > def {
                defLoss += 1
                comparisons.append(BattleComparison(attackerDie: att, defenderDie: def, attackerWon: true))
            } else {
                attLoss += 1
                comparisons.append(BattleComparison(attackerDie: att, defenderDie: def, attackerWon: false))
            }
        }

        withAnimation(.spring()) {
            lastBattleResult = RiskBattleResult(
                attackerRolls: attRolls,
                defenderRolls: defRolls,
                attackerLosses: attLoss,
                defenderLosses: defLoss,
                comparisons: comparisons
            )
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(defLoss > attLoss ? .success : .warning)
    }

    private func runBlitzSimulationAction() {
        var att = blitzAttackerArmies
        var def = blitzDefenderArmies
        var rounds = 0

        while att > 1 && def > 0 {
            rounds += 1
            let aDice = min(3, att - 1)
            let dDice = min(2, def)

            let aRolls = (0..<aDice).map { _ in Int.random(in: 1...6) }.sorted(by: >)
            let dRolls = (0..<dDice).map { _ in Int.random(in: 1...6) }.sorted(by: >)

            let compareCount = min(aRolls.count, dRolls.count)
            for i in 0..<compareCount {
                if aRolls[i] > dRolls[i] {
                    def -= 1
                } else {
                    att -= 1
                }
            }
        }

        withAnimation(.spring()) {
            lastBlitzResult = RiskBlitzResult(
                attackerInitial: blitzAttackerArmies,
                defenderInitial: blitzDefenderArmies,
                attackerRemaining: att,
                defenderRemaining: def,
                attackerWon: def == 0,
                totalRounds: rounds
            )
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func saveFinishedGameAction() {
        let winnerName = players[winningPlayerIndex].name
        let detailedScores: [(name: String, score: Int, juiste: Int, foute: Int)] = players.indices.map { idx in
            let score = (idx == winningPlayerIndex) ? 100 : 0
            return (name: players[idx].name, score: score, juiste: score, foute: 0)
        }

        scoreManager.saveGame(
            gameName: "Risk",
            playerDetailedScores: detailedScores,
            winnerName: winnerName
        )

        winningPlayerObj = Player(name: winnerName)
        ActiveGameManager.shared.clearActiveGame()
        showFinishDialog = false
        showWinnerScreen = true
    }

    private func saveDraft() {
        let summary = "\(players.count) spelers • Risk (\(gameMode.rawValue))"
        ActiveGameManager.shared.saveActiveGame(
            gameName: "Risk",
            playerNames: players.map { $0.name },
            currentRound: 1,
            summary: summary,
            state: [
                "gameMode": gameMode.rawValue
            ]
        )
    }

    private func assignSecretMissionsIfNeeded() {
        if gameMode != .secretMissions { return }
        var missionsPool = generateAllRiskMissions().shuffled()

        for i in players.indices {
            if players[i].mission == nil && !missionsPool.isEmpty {
                players[i].mission = missionsPool.removeFirst()
            }
        }
    }

    private func generateAllRiskMissions() -> [RiskMission] {
        return [
            RiskMission(id: 1, title: "Europa & Australië", description: "Verover geheel Europa en Australië, plus een 3e continent naar keuze.", targetColor: nil),
            RiskMission(id: 2, title: "Europa & Zuid-Amerika", description: "Verover geheel Europa en Zuid-Amerika, plus een 3e continent naar keuze.", targetColor: nil),
            RiskMission(id: 3, title: "Noord-Amerika & Afrika", description: "Verover geheel Noord-Amerika en geheel Afrika.", targetColor: nil),
            RiskMission(id: 4, title: "Noord-Amerika & Australië", description: "Verover geheel Noord-Amerika en geheel Australië.", targetColor: nil),
            RiskMission(id: 5, title: "Azië & Zuid-Amerika", description: "Verover geheel Azië en geheel Zuid-Amerika.", targetColor: nil),
            RiskMission(id: 6, title: "Azië & Afrika", description: "Verover geheel Azië en geheel Afrika.", targetColor: nil),
            RiskMission(id: 7, title: "24 Gebieden", description: "Verover 24 gebieden naar keuze met minimaal 1 leger per gebied.", targetColor: nil),
            RiskMission(id: 8, title: "18 Gebieden (Bezetting)", description: "Verover 18 gebieden met minimaal 2 legers per gebied.", targetColor: nil),
            RiskMission(id: 9, title: "Vernietig Rood", description: "Vernietig alle legers van het Rode leger. (Als je zelf Rood bent of Rood niet meedoet: verover 24 gebieden).", targetColor: .red),
            RiskMission(id: 10, title: "Vernietig Blauw", description: "Vernietig alle legers van het Blauwe leger. (Als je zelf Blauw bent of Blauw niet meedoet: verover 24 gebieden).", targetColor: .blue),
            RiskMission(id: 11, title: "Vernietig Geel", description: "Vernietig alle legers van het Gele leger. (Als je zelf Geel bent of Geel niet meedoet: verover 24 gebieden).", targetColor: .yellow),
            RiskMission(id: 12, title: "Vernietig Groen", description: "Vernietig alle legers van het Groene leger. (Als je zelf Groen bent of Groen niet meedoet: verover 24 gebieden).", targetColor: .green),
            RiskMission(id: 13, title: "Vernietig Zwart", description: "Vernietig alle legers van het Zwarte leger. (Als je zelf Zwart bent of Zwart niet meedoet: verover 24 gebieden).", targetColor: .black),
            RiskMission(id: 14, title: "Vernietig Paars", description: "Vernietig alle legers van het Paarse leger. (Als je zelf Paars bent of Paars niet meedoet: verover 24 gebieden).", targetColor: .purple)
        ]
    }
}

// MARK: - Dobbelsteen Visuele Weergave

struct RiskDieView: View {
    let value: Int
    let isAttacker: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    isAttacker
                        ? LinearGradient(colors: [Color.red, Color(red: 0.75, green: 0.1, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.white, Color(white: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 44, height: 44)
                .shadow(color: isAttacker ? Color.red.opacity(0.3) : Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isAttacker ? Color.white.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
                )

            // Ogen
            dieDots
                .foregroundColor(isAttacker ? .white : .black)
        }
    }

    @ViewBuilder
    private var dieDots: some View {
        let dotSize: CGFloat = 6
        switch value {
        case 1:
            Circle().frame(width: dotSize, height: dotSize)
        case 2:
            VStack {
                HStack { Circle().frame(width: dotSize, height: dotSize); Spacer() }
                Spacer()
                HStack { Spacer(); Circle().frame(width: dotSize, height: dotSize) }
            }
            .padding(10)
        case 3:
            ZStack {
                VStack {
                    HStack { Circle().frame(width: dotSize, height: dotSize); Spacer() }
                    Spacer()
                    HStack { Spacer(); Circle().frame(width: dotSize, height: dotSize) }
                }
                Circle().frame(width: dotSize, height: dotSize)
            }
            .padding(10)
        case 4:
            VStack {
                HStack { Circle().frame(width: dotSize, height: dotSize); Spacer(); Circle().frame(width: dotSize, height: dotSize) }
                Spacer()
                HStack { Circle().frame(width: dotSize, height: dotSize); Spacer(); Circle().frame(width: dotSize, height: dotSize) }
            }
            .padding(10)
        case 5:
            ZStack {
                VStack {
                    HStack { Circle().frame(width: dotSize, height: dotSize); Spacer(); Circle().frame(width: dotSize, height: dotSize) }
                    Spacer()
                    HStack { Circle().frame(width: dotSize, height: dotSize); Spacer(); Circle().frame(width: dotSize, height: dotSize) }
                }
                Circle().frame(width: dotSize, height: dotSize)
            }
            .padding(10)
        case 6:
            VStack {
                HStack { Circle().frame(width: dotSize, height: dotSize); Spacer(); Circle().frame(width: dotSize, height: dotSize) }
                Spacer()
                HStack { Circle().frame(width: dotSize, height: dotSize); Spacer(); Circle().frame(width: dotSize, height: dotSize) }
                Spacer()
                HStack { Circle().frame(width: dotSize, height: dotSize); Spacer(); Circle().frame(width: dotSize, height: dotSize) }
            }
            .padding(9)
        default:
            EmptyView()
        }
    }
}
