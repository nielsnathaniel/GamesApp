import SwiftUI

struct CrockinoleGameView: View {
    var isTeamMode: Bool = false
    var teamWitNaam: String = "Wit"
    var teamWitSpelers: [String] = ["Wit"]
    var teamZwartNaam: String = "Zwart"
    var teamZwartSpelers: [String] = ["Zwart"]
    var puntenMethode: String = "Alles"

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

    let beschikbarePunten = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50]

    init(spelers: [String] = ["Wit", "Zwart"], puntenMethode: String = "Alles") {
        self.isTeamMode = false
        self.teamWitNaam = spelers.indices.contains(0) ? spelers[0] : "Wit"
        self.teamWitSpelers = [self.teamWitNaam]
        self.teamZwartNaam = spelers.indices.contains(1) ? spelers[1] : "Zwart"
        self.teamZwartSpelers = [self.teamZwartNaam]
        self.puntenMethode = puntenMethode
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
        self.puntenMethode = puntenMethode
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
                            scores = [0, 0]
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

                // 2. Puntentegels
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

                // 3. Knop Punten Toevoegen
                Button(action: {
                    if selectedTeamIndex < scores.count {
                        scores[selectedTeamIndex] += selectedPoints
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("\(selectedPoints) punten toevoegen aan \(selectedTeamIndex == 0 ? teamWitNaam : teamZwartNaam)")
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
                .padding(.horizontal)

                // 4. Knop Ronde beëindigen (Berekent het differentieel conform officiële regels)
                Button(action: {
                    berekenRondeEnBeëindig()
                }) {
                    HStack {
                        Image(systemName: "flag.checkered")
                        Text("Ronde beëindigen")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
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
        scores = [0, 0]
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
            teamZwartSpelers: ["Lisa", "Sam"]
        )
    }
}
