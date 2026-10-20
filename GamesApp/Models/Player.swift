import Foundation

struct Player: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var scores: [Int] = Array(repeating: 0, count: 5) // Scores per laag
} 