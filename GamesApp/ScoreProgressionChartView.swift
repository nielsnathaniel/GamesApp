import SwiftUI
import Charts

/// Datapunt voor één speler in een specifieke ronde
struct RoundScoreDataPoint: Identifiable, Codable {
    var id: String { "\(playerName)_\(round)" }
    let round: Int
    let playerName: String
    let cumulativeScore: Int

    enum CodingKeys: String, CodingKey {
        case round, playerName, cumulativeScore
    }
}

/// Grafiek die het verloop van de scores over alle rondes weergeeft (Swift Charts)
struct ScoreProgressionChartView: View {
    let title: String
    let dataPoints: [RoundScoreDataPoint]
    let playerNames: [String]

    private let chartColors: [Color] = [
        .blue, .orange, .green, .purple, .red, .pink, .teal, .indigo, .yellow, .mint
    ]

    private func color(for player: String) -> Color {
        guard let index = playerNames.firstIndex(of: player) else { return .blue }
        return chartColors[index % chartColors.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("Cumulatieve score")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if dataPoints.isEmpty {
                Text("Nog niet genoeg rondes gespeeld voor een grafiek.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            } else {
                Chart {
                    ForEach(dataPoints) { point in
                        LineMark(
                            x: .value("Ronde", point.round),
                            y: .value("Score", point.cumulativeScore)
                        )
                        .foregroundStyle(by: .value("Speler", point.playerName))
                        .interpolationMethod(.monotone)

                        PointMark(
                            x: .value("Ronde", point.round),
                            y: .value("Score", point.cumulativeScore)
                        )
                        .foregroundStyle(by: .value("Speler", point.playerName))
                    }
                }
                .chartXScale(domain: minRound...maxRound)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(6, maxRound - minRound + 1))) { value in
                        AxisGridLine()
                        AxisTick()
                        if let intVal = value.as(Int.self) {
                            AxisValueLabel("R\(intVal)")
                        }
                    }
                }
                .frame(height: 180)
                .padding(.vertical, 4)

                // Legenda
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(playerNames, id: \.self) { name in
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(color(for: name))
                                    .frame(width: 8, height: 8)
                                Text(name)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
    }

    private var minRound: Int {
        dataPoints.map { $0.round }.min() ?? 0
    }

    private var maxRound: Int {
        let mx = dataPoints.map { $0.round }.max() ?? 1
        return max(minRound + 1, mx)
    }
}
