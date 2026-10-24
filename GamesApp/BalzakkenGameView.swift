import SwiftUI

struct BalzakkenRondeEntry: Identifiable {
    var id: Int { ronde }
    let ronde: Int
    let starter: String
    let scoresDezeRonde: [Int]
    let totalenNaRonde: [Int]
    let specialeEvents: [String]
}

struct BalzakkenGameView: View {
    var spelers: [Player]
    var eindscore: Int = 100

    enum RondeBalzakStatus {
        case geen
        case juisteBalzak
        case valseBalzak
    }

    @State private var huidigeRonde: Int = 1
    @State private var rondeScores: [Int] = []
    @State private var totaleScores: [Int] = []
    @State private var juisteBalzakken: [Int] = []
    @State private var fouteBalzakken: [Int] = []
    @State private var rondeStatus: [RondeBalzakStatus] = []
    @State private var startSpelerIndex: Int = 0
    @State private var rondeGeschiedenis: [BalzakkenRondeEntry] = []
    @State private var toonGeschiedenisSheet: Bool = false
    @State private var isExpanded: [Bool] = []
    @State private var showWinnaarView: Bool = false
    @State private var winnaar: Player?

    // 69 en 99 speciale regels feedback
    @State private var showSpecialRuleAlert: Bool = false
    @State private var specialRuleMessage: String = ""

    var huidigeStarterIndex: Int {
        guard !spelers.isEmpty else { return 0 }
        return (startSpelerIndex + (huidigeRonde - 1)) % spelers.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 4) {
                    HStack(spacing: 10) {
                        if UIImage(named: "Balzakken") != nil {
                            Image("Balzakken")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 38, height: 38)
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                .shadow(color: .red.opacity(0.3), radius: 3, x: 0, y: 1)
                        } else {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.red)
                        }
                        Text("Balzakken")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    Text("Ronde \(huidigeRonde) • Einde bij 100 strafpunten")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)

                // Wie mag beginnen (Startspeler kaart)
                HStack(spacing: 10) {
                    Image(systemName: "dice.fill")
                        .font(.title2)
                        .foregroundColor(.red)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Begint deze ronde:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(spelers[safe: huidigeStarterIndex]?.name ?? "Speler 1")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    if huidigeRonde == 1 {
                        Button(action: {
                            withAnimation {
                                startSpelerIndex = Int.random(in: 0..<max(1, spelers.count))
                            }
                        }) {
                            Label("Willekeurig", systemImage: "arrow.triangle.2.circlepath")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.12))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                        }
                    } else {
                        Text("Om de beurt")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // Knop naar puntengeschiedenis van dit spel
                Button(action: {
                    toonGeschiedenisSheet = true
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Puntengeschiedenis (\(rondeGeschiedenis.count) \(rondeGeschiedenis.count == 1 ? "ronde" : "rondes"))")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                // Spelers lijst
                VStack(spacing: 10) {
                    ForEach(spelers.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 0) {
                            Button(action: {
                                if index < isExpanded.count {
                                    withAnimation {
                                        isExpanded[index].toggle()
                                    }
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(spelers[index].name)
                                                .font(.headline)

                                            if index == huidigeStarterIndex {
                                                HStack(spacing: 2) {
                                                    Image(systemName: "play.fill")
                                                        .font(.system(size: 8))
                                                    Text("Begint")
                                                        .font(.system(size: 10, weight: .bold))
                                                }
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(6)
                                            }
                                        }

                                        Text("Strafpunten: \(totaleScores[safe: index] ?? 0) / 100")
                                            .font(.caption)
                                            .foregroundColor((totaleScores[safe: index] ?? 0) >= 80 ? .red : .secondary)

                                        // Juiste en foute balzakken teller
                                        HStack(spacing: 8) {
                                            Text("🎯 \(juisteBalzakken[safe: index] ?? 0)")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                            Text("⚠️ \(fouteBalzakken[safe: index] ?? 0)")
                                                .font(.caption2)
                                                .foregroundColor(.red)

                                            if rondeStatus[safe: index] == .juisteBalzak {
                                                Text("• 👑 BALZAK! (0)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.yellow)
                                            } else if rondeStatus[safe: index] == .valseBalzak {
                                                Text("• ⚠️ Valse (+25)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("+\(rondeScores[safe: index] ?? 0)")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.red)
                                        Text("deze ronde")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                            }

                            if index < isExpanded.count && isExpanded[index] {
                                VStack(spacing: 12) {
                                    // Knoppen voor BALZAK en VALSE BALZAK
                                    HStack(spacing: 10) {
                                        Button(action: {
                                            if index < rondeScores.count && index < rondeStatus.count {
                                                if rondeStatus[index] == .juisteBalzak {
                                                    // Klik nogmaals om te deselecteren
                                                    rondeStatus[index] = .geen
                                                    rondeScores[index] = 0
                                                } else {
                                                    rondeScores[index] = 0
                                                    rondeStatus[index] = .juisteBalzak
                                                }
                                            }
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "crown.fill")
                                                Text("BALZAK! (0)")
                                                    .fontWeight(.bold)
                                                if rondeStatus[safe: index] == .juisteBalzak {
                                                    Image(systemName: "checkmark.circle.fill")
                                                }
                                            }
                                            .font(.footnote)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(rondeStatus[safe: index] == .juisteBalzak ? Color.yellow : Color.yellow.opacity(0.35))
                                            .foregroundColor(rondeStatus[safe: index] == .juisteBalzak ? Color.black : Color.primary)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(rondeStatus[safe: index] == .juisteBalzak ? Color.orange : Color.clear, lineWidth: 2)
                                            )
                                        }

                                        Button(action: {
                                            if index < rondeScores.count && index < rondeStatus.count {
                                                if rondeStatus[index] == .valseBalzak {
                                                    // Klik nogmaals om te deselecteren
                                                    rondeStatus[index] = .geen
                                                    rondeScores[index] = 0
                                                } else {
                                                    rondeScores[index] = 25
                                                    rondeStatus[index] = .valseBalzak
                                                }
                                            }
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                Text("Valse Balzak (+25)")
                                                    .fontWeight(.bold)
                                                if rondeStatus[safe: index] == .valseBalzak {
                                                    Image(systemName: "checkmark.circle.fill")
                                                }
                                            }
                                            .font(.footnote)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(rondeStatus[safe: index] == .valseBalzak ? Color.red : Color.red.opacity(0.2))
                                            .foregroundColor(rondeStatus[safe: index] == .valseBalzak ? Color.white : Color.red)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(rondeStatus[safe: index] == .valseBalzak ? Color.red : Color.clear, lineWidth: 2)
                                            )
                                        }
                                    }

                                    HStack {
                                        Text("Handkaarten score:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(rondeScores[safe: index] ?? 0) pt")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.red)

                                        if (rondeScores[safe: index] ?? 0) != 0 || rondeStatus[safe: index] != .geen {
                                            Button(action: {
                                                if index < rondeScores.count {
                                                    rondeScores[index] = 0
                                                }
                                                if index < rondeStatus.count {
                                                    rondeStatus[index] = .geen
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(.leading, 4)
                                        }
                                    }

                                    // Snelle knoppen voor kaartwaardes: ALLEEN CIJFERS (-1, +1, +5, +11)
                                    HStack(spacing: 10) {
                                        Button("-1") {
                                            if index < rondeScores.count {
                                                rondeScores[index] = max(-1, rondeScores[index] - 1)
                                            }
                                            if index < rondeStatus.count {
                                                rondeStatus[index] = .geen
                                            }
                                        }
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)

                                        Button("+1") {
                                            if index < rondeScores.count {
                                                rondeScores[index] += 1
                                            }
                                            if index < rondeStatus.count {
                                                rondeStatus[index] = .geen
                                            }
                                        }
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.red.opacity(0.85))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)

                                        Button("+5") {
                                            if index < rondeScores.count {
                                                rondeScores[index] += 5
                                            }
                                            if index < rondeStatus.count {
                                                rondeStatus[index] = .geen
                                            }
                                        }
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.red.opacity(0.95))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)

                                        Button("+11") {
                                            if index < rondeScores.count {
                                                rondeScores[index] += 11
                                            }
                                            if index < rondeStatus.count {
                                                rondeStatus[index] = .geen
                                            }
                                        }
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(10)
                                .padding(.horizontal, 4)
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 20)

                // Ronde beëindigen knop
                Button(action: {
                    volgendeRonde()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Ronde Beëindigen")
                            .fontWeight(.bold)
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onAppear {
            if rondeScores.isEmpty {
                rondeScores = Array(repeating: 0, count: spelers.count)
                totaleScores = Array(repeating: 0, count: spelers.count)
                juisteBalzakken = Array(repeating: 0, count: spelers.count)
                fouteBalzakken = Array(repeating: 0, count: spelers.count)
                rondeStatus = Array(repeating: .geen, count: spelers.count)
                isExpanded = Array(repeating: false, count: spelers.count)
                if !spelers.isEmpty {
                    startSpelerIndex = Int.random(in: 0..<spelers.count)
                }
            }
        }
        .sheet(isPresented: $toonGeschiedenisSheet) {
            puntengeschiedenisView
        }
        .alert("Lekkere Tussenstand! 🎉", isPresented: $showSpecialRuleAlert) {
            Button("Top!", role: .cancel) {
                controleerEindeSpel()
            }
        } message: {
            Text(specialRuleMessage)
        }
        .navigationDestination(isPresented: $showWinnaarView) {
            if let winnaar = winnaar {
                WinnaarView(
                    gameName: "Balzakken",
                    winnaar: winnaar,
                    sortedSpelers: spelers,
                    sortedScores: totaleScores,
                    isLowestScoreWins: true,
                    juisteBalzakken: juisteBalzakken,
                    fouteBalzakken: fouteBalzakken
                )
            }
        }
    }

    // MARK: - Puntengeschiedenis Modal van het huidige spel

    private var puntengeschiedenisView: some View {
        NavigationStack {
            List {
                if rondeGeschiedenis.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Nog geen rondes voltooid.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(rondeGeschiedenis.reversed()) { entry in
                        Section(header: Text("Ronde \(entry.ronde) • Begonnen door \(entry.starter)")) {
                            ForEach(spelers.indices, id: \.self) { sIdx in
                                HStack {
                                    Text(spelers[sIdx].name)
                                        .font(.headline)
                                    Spacer()
                                    let pts = entry.scoresDezeRonde[safe: sIdx] ?? 0
                                    Text("+\(pts) pt")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(pts > 0 ? .red : (pts == 0 ? .yellow : .blue))
                                    Text("(Totaal: \(entry.totalenNaRonde[safe: sIdx] ?? 0))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            if !entry.specialeEvents.isEmpty {
                                ForEach(entry.specialeEvents, id: \.self) { ev in
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(.orange)
                                        Text(ev)
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Puntenverloop Dit Spel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sluit") {
                        toonGeschiedenisSheet = false
                    }
                }
            }
        }
    }

    private func volgendeRonde() {
        var specialEvents: [String] = []

        let snapshotRondeScores = rondeScores

        for i in spelers.indices {
            if i < rondeScores.count && i < totaleScores.count {
                totaleScores[i] += rondeScores[i]

                // Alleen HIER bij het afronden van de ronde registreren we de balzakken voor de statistieken:
                if rondeStatus[safe: i] == .juisteBalzak {
                    if i < juisteBalzakken.count {
                        juisteBalzakken[i] += 1
                    }
                    specialEvents.append("🎯 \(spelers[i].name) had een Goeie Balzak! (0 pt)")
                } else if rondeStatus[safe: i] == .valseBalzak {
                    if i < fouteBalzakken.count {
                        fouteBalzakken[i] += 1
                    }
                    specialEvents.append("⚠️ \(spelers[i].name) had een Valse Balzak! (+25 pt)")
                }

                // Speciale regel: precies 69 punten -> terug naar 50 punten!
                if totaleScores[i] == 69 {
                    totaleScores[i] = 50
                    specialEvents.append("\(spelers[i].name) had exact 69 punten en gaat terug naar 50 punten!")
                }
                // Speciale regel: precies 99 punten -> terug naar 75 punten!
                else if totaleScores[i] == 99 {
                    totaleScores[i] = 75
                    specialEvents.append("\(spelers[i].name) had exact 99 punten en gaat terug naar 75 punten!")
                }
            }
        }

        // Sla de rondegeschiedenis van dit spel op
        let starter = spelers[safe: huidigeStarterIndex]?.name ?? "Speler 1"
        rondeGeschiedenis.append(
            BalzakkenRondeEntry(
                ronde: huidigeRonde,
                starter: starter,
                scoresDezeRonde: snapshotRondeScores,
                totalenNaRonde: totaleScores,
                specialeEvents: specialEvents
            )
        )

        huidigeRonde += 1
        rondeScores = Array(repeating: 0, count: spelers.count)
        rondeStatus = Array(repeating: .geen, count: spelers.count)
        withAnimation {
            isExpanded = Array(repeating: false, count: spelers.count)
        }

        if !specialEvents.isEmpty {
            specialRuleMessage = specialEvents.joined(separator: "\n\n")
            showSpecialRuleAlert = true
        } else {
            controleerEindeSpel()
        }
    }

    private func controleerEindeSpel() {
        // Balzakken stopt zodra een speler 100 strafpunten bereikt
        if let maxPenalty = totaleScores.max(), maxPenalty >= 100 {
            bepaalWinnaar()
            showWinnaarView = true
        }
    }

    private func bepaalWinnaar() {
        // Laagste score wint bij Balzakken!
        if let minScore = totaleScores.min(),
           let winnaarIndex = totaleScores.firstIndex(of: minScore) {
            winnaar = spelers[winnaarIndex]
        } else {
            winnaar = spelers.first
        }
    }
}

#Preview {
    BalzakkenGameView(spelers: [Player(name: "Speler 1"), Player(name: "Speler 2")])
}
