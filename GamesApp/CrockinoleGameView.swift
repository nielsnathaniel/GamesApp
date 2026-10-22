import SwiftUI

struct CrockinoleGameView: View {
    var isTeamMode: Bool = false
    var teamWitNaam: String = "Wit"
    var teamWitSpelers: [String] = ["Wit"]
    var teamZwartNaam: String = "Zwart"
    var teamZwartSpelers: [String] = ["Zwart"]

    // Telwijze kan nu ook tijdens het spelen worden aangepast!
    @State private var puntenMethode: String

    // Ronde-invoer scores [Wit, Zwart]
    @State private var scores: [Int] = [0, 0]
    // Gewonnen sets [Wit, Zwart]
    @State private var setScores: [Int] = [0, 0]
    // Cumulatieve score in de huidige set [Wit, Zwart]
    @State private var totaleScores: [Int] = [0, 0]
    @State private var huidigeRonde: Int = 1
    @State private var showWinnaarView: Bool = false
    @State private var winnaarTeam: String?

    // Schietvolgorde (Wit 1 -> Zwart 1 -> Wit 2 -> Zwart 2)
    @State private var huidigeSchutterIndex: Int = 0

    // Selecties voor de score-invoer (0 = Wit, 1 = Zwart)
    @State private var selectedTeamIndex: Int = 0
    @State private var selectedPoints: Int = 5

    // Schijf-voor-schijf tellers per ring ("Berekend")
    @State private var schijvenWit20: Int = 0
    @State private var schijvenWit15: Int = 0
    @State private var schijvenWit10: Int = 0
    @State private var schijvenWit5: Int = 0

    @State private var schijvenZwart20: Int = 0
    @State private var schijvenZwart15: Int = 0
    @State private var schijvenZwart10: Int = 0
    @State private var schijvenZwart5: Int = 0

    let beschikbarePunten = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50]

    init(spelers: [String] = ["Wit", "Zwart"], puntenMethode: String = "Alles") {
        self.isTeamMode = false
        let w = spelers.indices.contains(0) ? spelers[0] : "Wit"
        let z = spelers.indices.contains(1) ? spelers[1] : "Zwart"
        self.teamWitNaam = w
        self.teamWitSpelers = [w]
        self.teamZwartNaam = z
        self.teamZwartSpelers = [z]
        _puntenMethode = State(initialValue: puntenMethode)
    }

    init(
        isTeamMode: Bool,
        teamWitNaam: String,
        teamWitSpelers: [String],
        teamZwartNaam: String,
        teamZwartSpelers: [String],
        puntenMethode: String = "Alles"
    ) {
        self.isTeamMode = isTeamMode
        self.teamWitNaam = teamWitNaam
        self.teamWitSpelers = teamWitSpelers
        self.teamZwartNaam = teamZwartNaam
        self.teamZwartSpelers = teamZwartSpelers
        _puntenMethode = State(initialValue: puntenMethode)
    }

    // Volgorde van schutters in een 2v2 potje
    private var schuttersVolgorde: [String] {
        if isTeamMode {
            var list: [String] = []
            if let w1 = teamWitSpelers[safe: 0] { list.append("\(w1) (⚪ Wit)") }
            if let z1 = teamZwartSpelers[safe: 0] { list.append("\(z1) (⚫ Zwart)") }
            if let w2 = teamWitSpelers[safe: 1] { list.append("\(w2) (⚪ Wit)") }
            if let z2 = teamZwartSpelers[safe: 1] { list.append("\(z2) (⚫ Zwart)") }
            return list
        } else {
            return ["\(teamWitNaam) (⚪ Wit)", "\(teamZwartNaam) (⚫ Zwart)"]
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "circle.circle.fill")
                            .foregroundColor(.blue)
                        Text("Crokinole")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    Text("Ronde \(huidigeRonde) • Eerste team met 3 sets wint!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)

                // Schietvolgorde Banner (als teammodus actief is)
                if isTeamMode {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Aan de beurt om te schieten:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(schuttersVolgorde[safe: huidigeSchutterIndex % max(1, schuttersVolgorde.count)] ?? "")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        Button(action: {
                            withAnimation {
                                huidigeSchutterIndex = (huidigeSchutterIndex + 1) % max(1, schuttersVolgorde.count)
                            }
                        }) {
                            Text("Volgende")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.12))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // 1. Team/Speler Tegels (Wit & Zwart)
                HStack(spacing: 14) {
                    teamTile(index: 0, isWit: true)
                    teamTile(index: 1, isWit: false)
                }
                .padding(.horizontal)

                // 2. Telwijze Selector (Tijdens het spel aanpasbaar!)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.blue)
                        Text("Telwijze")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(puntenMethode == "Alles" ? "Directe ronde-score invoer" : "Schijf voor schijf per ring")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }

                    Picker("Telwijze", selection: $puntenMethode) {
                        Text("Alles (Direct)").tag("Alles")
                        Text("Berekend (Per schijf)").tag("Berekend")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground).opacity(0.7))
                .cornerRadius(12)
                .padding(.horizontal)

                // 3. Invoersectie op basis van gekozen telwijze
                if puntenMethode == "Alles" {
                    directeInvoerSectie
                } else {
                    berekendeInvoerSectie
                }

                // 4. Knop Ronde beëindigen (Berekent het differentieel conform officiële regels)
                Button(action: {
                    berekenRondeEnBeëindig()
                }) {
                    HStack {
                        Image(systemName: "flag.checkered")
                        Text(rondeEindeKnopTekst)
                            .fontWeight(.bold)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal)
                .padding(.top, 4)

                Spacer(minLength: 20)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { withAnimation { puntenMethode = "Alles" } }) {
                        Label("Alles (Direct)", systemImage: puntenMethode == "Alles" ? "checkmark" : "")
                    }
                    Button(action: { withAnimation { puntenMethode = "Berekend" } }) {
                        Label("Berekend (Per schijf)", systemImage: puntenMethode == "Berekend" ? "checkmark" : "")
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationDestination(isPresented: $showWinnaarView) {
            if isTeamMode {
                let winnerName = (setScores[0] >= 3) ? teamWitNaam : teamZwartNaam
                let entries = [
                    WinnaarTeamEntry(
                        teamName: teamWitNaam,
                        playerNames: teamWitSpelers,
                        score: setScores[0],
                        isWinner: setScores[0] >= 3
                    ),
                    WinnaarTeamEntry(
                        teamName: teamZwartNaam,
                        playerNames: teamZwartSpelers,
                        score: setScores[1],
                        isWinner: setScores[1] >= 3
                    )
                ]
                WinnaarView(
                    gameName: "Crockinole",
                    winningTeamName: winnerName,
                    teams: entries,
                    isLowestScoreWins: false
                )
            } else {
                let winnerName = (setScores[0] >= 3) ? teamWitNaam : teamZwartNaam
                WinnaarView(
                    gameName: "Crockinole",
                    winnaarNaam: winnerName,
                    spelersNamen: [teamWitNaam, teamZwartNaam],
                    scores: setScores,
                    isLowestScoreWins: false
                )
            }
        }
    }

    // MARK: - Directe Invoer ("Alles")

    private var directeInvoerSectie: some View {
        VStack(spacing: 12) {
            // Statusbalkje met actieve selectie en reset-optie
            HStack {
                Text("Puntentoewijzing aan: ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                + Text(selectedTeamIndex == 0 ? teamWitNaam : teamZwartNaam)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                if scores[0] > 0 || scores[1] > 0 {
                    Button(action: {
                        resetRonde()
                    }) {
                        Label("Ronde wissen", systemImage: "arrow.counterclockwise")
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal)

            Divider()
                .padding(.horizontal)

            // Puntentegels
            VStack(alignment: .leading, spacing: 8) {
                Text("Kies punten van deze ronde")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                    ForEach(beschikbarePunten, id: \.self) { punten in
                        Button(action: {
                            selectedPoints = punten
                        }) {
                            Text("\(punten)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(selectedPoints == punten ? Color.blue : Color(UIColor.secondarySystemBackground))
                                .foregroundColor(selectedPoints == punten ? .white : .primary)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedPoints == punten ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Knoppen Punten Toevoegen / Aftrekken
            HStack(spacing: 12) {
                if scores[selectedTeamIndex] > 0 {
                    Button(action: {
                        if scores[selectedTeamIndex] >= selectedPoints {
                            scores[selectedTeamIndex] -= selectedPoints
                        } else {
                            scores[selectedTeamIndex] = 0
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                    }
                }

                Button(action: {
                    if selectedTeamIndex < scores.count {
                        scores[selectedTeamIndex] += selectedPoints
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("\(selectedPoints) pt toevoegen aan \(selectedTeamIndex == 0 ? teamWitNaam : teamZwartNaam)")
                            .fontWeight(.semibold)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(12)
                    .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Berekende Invoer ("Berekend" - Schijf voor schijf)

    private var berekendeInvoerSectie: some View {
        VStack(spacing: 12) {
            // Snelle teamkeuze knoppen
            HStack(spacing: 12) {
                Button(action: { selectedTeamIndex = 0 }) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                        Text(teamWitNaam)
                            .font(.subheadline)
                            .fontWeight(selectedTeamIndex == 0 ? .bold : .medium)
                        Spacer()
                        Text("\(scores[0]) pt")
                            .font(.footnote)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedTeamIndex == 0 ? Color.blue.opacity(0.18) : Color(UIColor.secondarySystemBackground))
                    .foregroundColor(selectedTeamIndex == 0 ? .blue : .primary)
                    .cornerRadius(10)
                }

                Button(action: { selectedTeamIndex = 1 }) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 14, height: 14)
                        Text(teamZwartNaam)
                            .font(.subheadline)
                            .fontWeight(selectedTeamIndex == 1 ? .bold : .medium)
                        Spacer()
                        Text("\(scores[1]) pt")
                            .font(.footnote)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedTeamIndex == 1 ? Color.orange.opacity(0.18) : Color(UIColor.secondarySystemBackground))
                    .foregroundColor(selectedTeamIndex == 1 ? .orange : .primary)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)

            // Header van actieve teamtelling
            HStack {
                Text("Schijven van \(selectedTeamIndex == 0 ? teamWitNaam : teamZwartNaam)")
                    .font(.headline)

                Spacer()

                if scores[0] > 0 || scores[1] > 0 {
                    Button(action: {
                        resetRonde()
                    }) {
                        Label("Ronde wissen", systemImage: "arrow.counterclockwise")
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal)

            // Ring-tellers voor actieve speler/team
            VStack(spacing: 8) {
                discCounterRow(
                    label: "Centrum (Gat)",
                    ringPoints: 20,
                    icon: "record.circle",
                    color: .red,
                    count: selectedTeamIndex == 0 ? $schijvenWit20 : $schijvenZwart20
                )

                discCounterRow(
                    label: "Binnenste ring",
                    ringPoints: 15,
                    icon: "circle.inset.filled",
                    color: .orange,
                    count: selectedTeamIndex == 0 ? $schijvenWit15 : $schijvenZwart15
                )

                discCounterRow(
                    label: "Middelste ring",
                    ringPoints: 10,
                    icon: "circle.circle",
                    color: .blue,
                    count: selectedTeamIndex == 0 ? $schijvenWit10 : $schijvenZwart10
                )

                discCounterRow(
                    label: "Buitenste ring",
                    ringPoints: 5,
                    icon: "circle",
                    color: .green,
                    count: selectedTeamIndex == 0 ? $schijvenWit5 : $schijvenZwart5
                )
            }
            .padding(.horizontal)
        }
    }

    private func discCounterRow(
        label: String,
        ringPoints: Int,
        icon: String,
        color: Color,
        count: Binding<Int>
    ) -> some View {
        HStack {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(ringPoints) pt per schijf")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Stepper: [-] count [+]
            HStack(spacing: 12) {
                Button(action: {
                    if count.wrappedValue > 0 {
                        count.wrappedValue -= 1
                        herberekenBerekendeScores()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(count.wrappedValue > 0 ? .red : .gray.opacity(0.3))
                }
                .disabled(count.wrappedValue <= 0)

                Text("\(count.wrappedValue)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(minWidth: 26, alignment: .center)

                Button(action: {
                    count.wrappedValue += 1
                    herberekenBerekendeScores()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(10)

            // Subtotaal
            Text("\(count.wrappedValue * ringPoints) pt")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 48, alignment: .trailing)
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    // Tekst op de ronde beëindigen knop met differentieel preview
    private var rondeEindeKnopTekst: String {
        let score0 = scores.indices.contains(0) ? scores[0] : 0
        let score1 = scores.indices.contains(1) ? scores[1] : 0

        if score0 > score1 {
            return "Ronde beëindigen (+\(score0 - score1) pt voor \(teamWitNaam))"
        } else if score1 > score0 {
            return "Ronde beëindigen (+\(score1 - score0) pt voor \(teamZwartNaam))"
        } else if score0 > 0 {
            return "Ronde beëindigen (Gelijkspel: 0 pt)"
        } else {
            return "Ronde beëindigen"
        }
    }

    // Team / Speler Tegel
    private func teamTile(index: Int, isWit: Bool) -> some View {
        let isSelected = selectedTeamIndex == index
        let title = isWit ? teamWitNaam : teamZwartNaam
        let players = isWit ? teamWitSpelers : teamZwartSpelers

        return Button(action: {
            selectedTeamIndex = index
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(isWit ? Color.white : Color.black)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        if isTeamMode {
                            Text(players.joined(separator: " & "))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Deze ronde")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(scores[safe: index] ?? 0) pt")
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Set-voortgang:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(totaleScores[safe: index] ?? 0) / 100 pt")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Sets gewonnen:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(setScores[safe: index] ?? 0) / 3")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.2) : Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
    }

    private func herberekenBerekendeScores() {
        scores[0] = (schijvenWit20 * 20) + (schijvenWit15 * 15) + (schijvenWit10 * 10) + (schijvenWit5 * 5)
        scores[1] = (schijvenZwart20 * 20) + (schijvenZwart15 * 15) + (schijvenZwart10 * 10) + (schijvenZwart5 * 5)
    }

    private func resetSchijven() {
        schijvenWit20 = 0
        schijvenWit15 = 0
        schijvenWit10 = 0
        schijvenWit5 = 0
        schijvenZwart20 = 0
        schijvenZwart15 = 0
        schijvenZwart10 = 0
        schijvenZwart5 = 0
    }

    private func resetRonde() {
        scores = [0, 0]
        resetSchijven()
    }

    // Crokinole differentieel puntentelling conform regels
    private func berekenRondeEnBeëindig() {
        let score0 = scores.indices.contains(0) ? scores[0] : 0
        let score1 = scores.indices.contains(1) ? scores[1] : 0

        if score0 > score1 {
            let diff = score0 - score1
            totaleScores[0] += diff
        } else if score1 > score0 {
            let diff = score1 - score0
            totaleScores[1] += diff
        }

        // Controleer of een team 100 punten heeft bereikt in de set
        for i in 0..<2 {
            if totaleScores[i] >= 100 {
                setScores[i] += 1
                totaleScores[i] = 0
            }
        }

        // Controleer of een team 3 sets heeft gewonnen
        if setScores.contains(where: { $0 >= 3 }) {
            winnaarTeam = (setScores[0] >= 3) ? teamWitNaam : teamZwartNaam
            showWinnaarView = true
        }

        // Reset ronde-invoer voor de volgende ronde
        resetRonde()
        huidigeRonde += 1

        if isTeamMode {
            huidigeSchutterIndex = (huidigeSchutterIndex + 1) % max(1, schuttersVolgorde.count)
        }
    }
}

#Preview {
    NavigationStack {
        CrockinoleGameView(
            isTeamMode: true,
            teamWitNaam: "The Aces",
            teamWitSpelers: ["Niels", "Tom"],
            teamZwartNaam: "The Kings",
            teamZwartSpelers: ["Lisa", "Sam"],
            puntenMethode: "Berekend"
        )
    }
}
