//
//  GamesAppTests.swift
//  GamesAppTests
//
//  Created by Niels Pronk on 23/11/2024.
//

import Testing
import Foundation
@testable import GamesApp

struct GamesAppTests {

    @Test func scoreManagerPersistenceAndClear() async throws {
        let manager = ScoreManager()
        manager.clearHistory()
        #expect(manager.fetchScores().isEmpty)
        #expect(manager.fetchGames().isEmpty)

        let p1 = Player(name: "Alice")
        let p2 = Player(name: "Bob")
        manager.saveGame(gameName: "Nmbr9", players: [p1, p2], scores: [120, 95], winner: p1)

        let savedGames = manager.fetchGames()
        #expect(savedGames.count == 1)
        #expect(savedGames.first?.gameName == "Nmbr9")
        #expect(savedGames.first?.winner == "Alice")
        #expect(savedGames.first?.scores.count == 2)

        let scores = manager.fetchScores()
        #expect(scores.count == 2)

        manager.clearHistory()
        #expect(manager.fetchScores().isEmpty)
        #expect(manager.fetchGames().isEmpty)
    }

    @Test func winnaarRankingBeverbendeVsOthers() async throws {
        let scores = [100, 40, 75]

        // Beverbende: lowest score wins (<)
        let beverbendeOrder = scores.indices.sorted(by: { scores[$0] < scores[$1] })
        #expect(beverbendeOrder == [1, 2, 0]) // 40, 75, 100

        // Nmbr9 / Duizenden / Crokinole: highest score wins (>)
        let normalOrder = scores.indices.sorted(by: { scores[$0] > scores[$1] })
        #expect(normalOrder == [0, 2, 1]) // 100, 75, 40
    }

    @Test func duizendenCardValues() async throws {
        func cardVal(_ sym: String) -> Int {
            switch sym {
            case "3": return 5
            case "K", "Q": return 10
            case "A": return 20
            case "JO": return 25
            default: return 0
            }
        }

        #expect(cardVal("3") == 5)
        #expect(cardVal("K") == 10)
        #expect(cardVal("Q") == 10)
        #expect(cardVal("A") == 20)
        #expect(cardVal("JO") == 25)
    }

    @Test func crokinoleDifferenceCalculation() async throws {
        let score0 = 60
        let score1 = 45
        var total0 = 0
        var total1 = 0

        if score0 > score1 {
            total0 += (score0 - score1)
        } else if score1 > score0 {
            total1 += (score1 - score0)
        }

        #expect(total0 == 15)
        #expect(total1 == 0)
    }

    @Test func nmbr9LayerMultipliers() async throws {
        let factor = { (laag: Int) -> Int in laag }
        #expect(factor(0) == 0) // Begane grond
        #expect(factor(1) == 1) // Laag 1
        #expect(factor(2) == 2) // Laag 2
        #expect(factor(3) == 3) // Laag 3
        #expect(factor(4) == 4) // Laag 4
    }

    @Test func balzakkenRules() async throws {
        // Valse balzak
        let valseBalzakPunten = 25
        #expect(valseBalzakPunten == 25)

        // 69 -> 50
        func applyBalzakkenSpecialRule(_ score: inout Int) {
            if score == 69 { score = 50 }
            else if score == 99 { score = 75 }
        }

        var scoreA = 44 + 25 // 69
        applyBalzakkenSpecialRule(&scoreA)
        #expect(scoreA == 50)

        var scoreB = 94 + 5 // 99
        applyBalzakkenSpecialRule(&scoreB)
        #expect(scoreB == 75)

        // Eindscore = 100, laagste wint
        let scores = [102, 65, 88]
        let gameOver = scores.contains(where: { $0 >= 100 })
        #expect(gameOver == true)
        let winnerIndex = scores.indices.min(by: { scores[$0] < scores[$1] })
        #expect(winnerIndex == 1) // 65 wint
    }
}
