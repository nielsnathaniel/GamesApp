import SwiftUI

struct LiveGameLeadIndicatorView: View {
    let playerScores: [(name: String, score: Int)]
    let isLowestScoreWins: Bool

    @State private var isPulsing: Bool = false

    private var sortedPlayers: [(name: String, score: Int)] {
        if isLowestScoreWins {
            return playerScores.sorted { $0.score < $1.score }
        } else {
            return playerScores.sorted { $0.score > $1.score }
        }
    }

    var body: some View {
        if sortedPlayers.count >= 2 {
            let leader = sortedPlayers[0]
            let runnerUp = sortedPlayers[1]
            let gap = abs(leader.score - runnerUp.score)

            HStack(spacing: 8) {
                // Icoon met lichte pulse animatie
                Image(systemName: gap == 0 ? "equal.circle.fill" : "flame.fill")
                    .font(.caption)
                    .foregroundColor(gap == 0 ? .yellow : .orange)
                    .scaleEffect(isPulsing ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsing)

                VStack(alignment: .leading, spacing: 2) {
                    if gap == 0 {
                        Text("Gelijke stand! \(leader.name) en \(runnerUp.name) delen P1 (\(leader.score) pt)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primary)
                    } else {
                        HStack(spacing: 4) {
                            Text("\(leader.name) leidt")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.primary)

                            Text("(+\(gap) pt voorsprong)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(isLowestScoreWins ? .green : .orange)
                        }

                        let needed = gap + 1
                        Text("\(runnerUp.name) heeft \(isLowestScoreWins ? "\(gap) pt minder" : "\(needed) pt") nodig voor de leiding")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Mini ranglijst pill
                HStack(spacing: 3) {
                    Text("P1")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.yellow)
                    PlayerAvatarView(name: leader.name, size: 18)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(UIColor.tertiarySystemFill))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                    )
            )
            .onAppear {
                isPulsing = true
            }
        }
    }
}
