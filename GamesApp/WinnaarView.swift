import SwiftUI

struct WinnaarView: View {
    var winnaar: Player
    var sortedSpelers: [Player]
    var sortedScores: [Int]
    var gameName: String = "Nmbr9"
    var isLowestScoreWins: Bool = false
    var juisteBalzakken: [Int]? = nil
    var fouteBalzakken: [Int]? = nil

    @State private var isScoreOpgeslagen = false
    @Environment(\.dismiss) private var dismiss
    private let scoreManager = ScoreManager.shared

    init(
        winnaar: Player,
        sortedSpelers: [Player],
        sortedScores: [Int],
        gameName: String = "Nmbr9",
        isLowestScoreWins: Bool = false
    ) {
        self.winnaar = winnaar
        self.sortedSpelers = sortedSpelers
        self.sortedScores = sortedScores
        self.gameName = gameName
        self.isLowestScoreWins = isLowestScoreWins
    }

    init(
        gameName: String,
        winnaar: Player,
        sortedSpelers: [Player],
        sortedScores: [Int],
        isLowestScoreWins: Bool = false,
        juisteBalzakken: [Int]? = nil,
        fouteBalzakken: [Int]? = nil
    ) {
        self.gameName = gameName
        self.winnaar = winnaar
        self.sortedSpelers = sortedSpelers
        self.sortedScores = sortedScores
        self.isLowestScoreWins = isLowestScoreWins
        self.juisteBalzakken = juisteBalzakken
        self.fouteBalzakken = fouteBalzakken
    }

    init(
        gameName: String,
        winnaarNaam: String,
        spelersNamen: [String],
        scores: [Int],
        isLowestScoreWins: Bool = false
    ) {
        self.gameName = gameName
        self.winnaar = Player(name: winnaarNaam)
        self.sortedSpelers = spelersNamen.map { Player(name: $0) }
        self.sortedScores = scores
        self.isLowestScoreWins = isLowestScoreWins
    }

    private var rankedIndices: [Int] {
        sortedSpelers.indices.sorted { i, j in
            let scoreI = i < sortedScores.count ? sortedScores[i] : 0
            let scoreJ = j < sortedScores.count ? sortedScores[j] : 0
            if isLowestScoreWins {
                return scoreI < scoreJ
            } else {
                return scoreI > scoreJ
            }
        }
    }

    var body: some View {
        VStack {
            Text(gameName)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 10)

            Text("Winnaar: \(winnaar.name)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
                .background(Color.yellow)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.top, 10)

            List {
                ForEach(rankedIndices, id: \.self) { index in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(sortedSpelers[index].name)
                                .font(.headline)
                            if let j = juisteBalzakken?[safe: index], let f = fouteBalzakken?[safe: index], (j > 0 || f > 0) {
                                Text("🎯 \(j) Balzak\(j == 1 ? "" : "ken") • ⚠️ \(f) Valse")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Text("\(sortedScores[safe: index] ?? 0) punten")
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.top, 20)

            Spacer()

            VStack(spacing: 12) {
                Button(action: {
                    isScoreOpgeslagen = true
                    scoreManager.saveGame(
                        gameName: gameName,
                        players: sortedSpelers,
                        scores: sortedScores,
                        winner: winnaar,
                        juisteBalzakken: juisteBalzakken,
                        fouteBalzakken: fouteBalzakken
                    )
                }) {
                    Text(isScoreOpgeslagen ? "Score succesvol opgeslagen!" : "Score opslaan")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isScoreOpgeslagen ? Color.gray : Color.green)
                        .cornerRadius(10)
                }
                .disabled(isScoreOpgeslagen)

                Button(action: {
                    dismiss()
                }) {
                    Text("Opnieuw")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }

                Button(action: {
                    dismiss()
                }) {
                    Text("Klaar")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    WinnaarView(
        winnaar: Player(name: "Speler 1"),
        sortedSpelers: [Player(name: "Speler 1"), Player(name: "Speler 2")],
        sortedScores: [100, 80],
        gameName: "Nmbr9",
        isLowestScoreWins: false
    )
}
