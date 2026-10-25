import SwiftUI
import Charts

/// Datapunt voor één speler in een specifieke ronde
struct RoundScoreDataPoint: Identifiable, Codable {
    var id: String = UUID().uuidString
    let round: Int
    let playerName: String
    let cumulativeScore: Int

    enum CodingKeys: String, CodingKey {
        case round, playerName, cumulativeScore
    }

    init(id: String = UUID().uuidString, round: Int, playerName: String, cumulativeScore: Int) {
        self.id = id
        self.round = round
        self.playerName = playerName
        self.cumulativeScore = cumulativeScore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID().uuidString
        self.round = try container.decode(Int.self, forKey: .round)
        self.playerName = try container.decode(String.self, forKey: .playerName)
        self.cumulativeScore = try container.decode(Int.self, forKey: .cumulativeScore)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(round, forKey: .round)
        try container.encode(playerName, forKey: .playerName)
        try container.encode(cumulativeScore, forKey: .cumulativeScore)
    }
}

/// Grafiek die het verloop van de scores over alle rondes weergeeft (Swift Charts)
struct ScoreProgressionChartView: View {
    let title: String
    let dataPoints: [RoundScoreDataPoint]
    let playerNames: [String]
    var chartHeight: CGFloat = 220

    private let chartColors: [Color] = [
        .blue, .orange, .green, .purple, .red, .pink, .teal, .indigo, .yellow, .mint
    ]

    private func color(for player: String) -> Color {
        guard let index = playerNames.firstIndex(of: player) else { return .blue }
        return chartColors[index % chartColors.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.blue)
                    .font(.headline)
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("Cumulatieve score")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if dataPoints.isEmpty {
                Text("Nog niet genoeg data voor een grafiek.")
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
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                        PointMark(
                            x: .value("Ronde", point.round),
                            y: .value("Score", point.cumulativeScore)
                        )
                        .foregroundStyle(by: .value("Speler", point.playerName))
                        .symbolSize(45)
                    }
                }
                .chartForegroundStyleScale(domain: playerNames, range: playerNames.map { color(for: $0) })
                .chartXScale(domain: minRound...maxRound)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: min(6, maxRound - minRound + 1))) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        AxisTick()
                        if let intVal = value.as(Int.self) {
                            AxisValueLabel(intVal == 0 ? "Start" : "R\(intVal)")
                        }
                    }
                }
                .frame(height: chartHeight)
                .padding(.vertical, 6)

                // Legenda met spelers en score
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(playerNames, id: \.self) { name in
                            let lastScore = dataPoints.filter { $0.playerName == name }.last?.cumulativeScore ?? 0
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(color(for: name))
                                    .frame(width: 10, height: 10)
                                Text(name)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text("(\(lastScore))")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private var minRound: Int {
        dataPoints.map { $0.round }.min() ?? 0
    }

    private var maxRound: Int {
        let mx = dataPoints.map { $0.round }.max() ?? 1
        return max(minRound + 1, mx)
    }
}
