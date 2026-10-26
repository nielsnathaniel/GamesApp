import Foundation
import SwiftUI

struct BoardgameAchievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let game: String
}

struct PlayerAchievementProgress: Identifiable {
    var id: String { achievement.id }
    let achievement: BoardgameAchievement
    let isUnlocked: Bool
    let progressText: String
    let unlockedDate: Date?
}

final class AchievementManager {
    static let shared = AchievementManager()

    private init() {}

    let allAchievements: [BoardgameAchievement] = [
        BoardgameAchievement(
            id: "streak_master",
            title: "Streak Master",
            description: "Behaal een ongeslagen reeks van minstens 3 overwinningen op rij",
            icon: "🔥",
            game: "Algemeen"
        ),
        BoardgameAchievement(
            id: "night_owl",
            title: "Nachtbraker",
            description: "Voltooi en win een gezellig potje na middernacht (00:00 - 05:00)",
            icon: "🌙",
            game: "Algemeen"
        ),
        BoardgameAchievement(
            id: "flying_start",
            title: "De Vliegende Start",
            description: "Win een potje waarbij je vanaf ronde 1 onafgebroken aan de leiding stond",
            icon: "🥇",
            game: "Algemeen"
        ),
        BoardgameAchievement(
            id: "balzak_keizer",
            title: "De Balzakken Keizer",
            description: "Roep 3 of meer foutloze Balzakken in één enkel potje",
            icon: "👑",
            game: "Balzakken"
        ),
        BoardgameAchievement(
            id: "worm_magnate",
            title: "Wormenmagnaat",
            description: "Verover 25 of meer wormen in een potje Regenwormen",
            icon: "🪱",
            game: "Regenwormen"
        ),
        BoardgameAchievement(
            id: "railway_baron",
            title: "Spoorwegbaron",
            description: "Win een potje Ticket to Ride met minstens 90 punten",
            icon: "🚂",
            game: "Ticket to Ride"
        ),
        BoardgameAchievement(
            id: "sharpshooter",
            title: "Scherpschutter",
            description: "Scoor 80 of meer punten in een wedstrijd Crockinole",
            icon: "🎯",
            game: "Crockinole"
        ),
        BoardgameAchievement(
            id: "brain_champion",
            title: "Breinkampioen",
            description: "Win een teamwedstrijd in Cranium of 30 Seconds",
            icon: "🧠",
            game: "30 Seconds / Cranium"
        ),
        BoardgameAchievement(
            id: "lightning_fast",
            title: "Bliksemsnel",
            description: "Win een potje Quickstop met minder dan 15 strafpunten",
            icon: "⚡️",
            game: "Quickstop"
        ),
        BoardgameAchievement(
            id: "dice_virtuoso",
            title: "Dobbelvirtuoos",
            description: "Win een potje Qwixx met meer dan 75 punten",
            icon: "🎲",
            game: "Qwixx"
        )
    ]

    func evaluateAchievements(for playerName: String, in scoreManager: ScoreManager) -> [PlayerAchievementProgress] {
        let pName = playerName.lowercased()
        let games = scoreManager.playedGames

        return allAchievements.map { badge in
            var unlocked = false
            var progress = "Nog niet behaald"
            var date: Date? = nil

            switch badge.id {
            case "streak_master":
                let streaks = scoreManager.playerWinStreak(for: playerName)
                let maxStreak = streaks.best
                if maxStreak >= 3 {
                    unlocked = true
                    progress = "\(maxStreak) overwinningen op rij!"
                } else {
                    progress = "\(maxStreak) / 3 op rij"
                }

            case "night_owl":
                for g in games {
                    let isPWinner = g.winner.lowercased().contains(pName) ||
                                    g.scores.contains(where: { $0.playerName.lowercased() == pName && $0.isWinner })
                    if isPWinner {
                        let hour = Calendar.current.component(.hour, from: g.date)
                        if hour >= 0 && hour < 5 {
                            unlocked = true
                            date = g.date
                            progress = "Middernacht overwinning!"
                            break
                        }
                    }
                }

            case "flying_start":
                for g in games {
                    let isPWinner = g.winner.lowercased().contains(pName) ||
                                    g.scores.contains(where: { $0.playerName.lowercased() == pName && $0.isWinner })
                    if isPWinner, let points = g.scoreProgression, !points.isEmpty {
                        // Check if round 1 had this player in 1st place
                        let r1Points = points.filter { $0.round == 1 }
                        if let r1Top = r1Points.max(by: { $0.cumulativeScore < $1.cumulativeScore }),
                           r1Top.playerName.lowercased() == pName {
                            unlocked = true
                            date = g.date
                            progress = "Ronde 1 t/m einde aan kop!"
                            break
                        }
                    }
                }

            case "balzak_keizer":
                for g in games where g.gameName.lowercased().contains("balzak") {
                    if let pScore = g.scores.first(where: { $0.playerName.lowercased() == pName }),
                       (pScore.juisteBalzakken ?? 0) >= 3 {
                        unlocked = true
                        date = g.date
                        progress = "\(pScore.juisteBalzakken ?? 0) Balzakken in 1 potje!"
                        break
                    }
                }

            case "worm_magnate":
                for g in games where g.gameName.lowercased().contains("regenworm") {
                    if let pScore = g.scores.first(where: { $0.playerName.lowercased() == pName }),
                       pScore.score >= 25 {
                        unlocked = true
                        date = g.date
                        progress = "\(pScore.score) wormen veroverd!"
                        break
                    }
                }

            case "railway_baron":
                for g in games where g.gameName.lowercased().contains("ticket") {
                    if let pScore = g.scores.first(where: { $0.playerName.lowercased() == pName }),
                       pScore.isWinner && pScore.score >= 90 {
                        unlocked = true
                        date = g.date
                        progress = "\(pScore.score) pt gescoord!"
                        break
                    }
                }

            case "sharpshooter":
                for g in games where g.gameName.lowercased().contains("crok") {
                    if let pScore = g.scores.first(where: { $0.playerName.lowercased() == pName }),
                       pScore.score >= 80 {
                        unlocked = true
                        date = g.date
                        progress = "\(pScore.score) pt in Crockinole!"
                        break
                    }
                }

            case "brain_champion":
                for g in games where g.gameName.contains("30 Seconds") || g.gameName.contains("Cranium") {
                    if g.winner.lowercased().contains(pName) ||
                       g.scores.contains(where: { $0.playerName.lowercased() == pName && $0.isWinner }) {
                        unlocked = true
                        date = g.date
                        progress = "Gewonnen in \(g.gameName)!"
                        break
                    }
                }

            case "lightning_fast":
                for g in games where g.gameName.lowercased().contains("quickstop") {
                    if let pScore = g.scores.first(where: { $0.playerName.lowercased() == pName }),
                       pScore.isWinner && pScore.score <= 15 {
                        unlocked = true
                        date = g.date
                        progress = "Gewonnen met slechts \(pScore.score) strafpt!"
                        break
                    }
                }

            case "dice_virtuoso":
                for g in games where g.gameName.lowercased().contains("qwixx") {
                    if let pScore = g.scores.first(where: { $0.playerName.lowercased() == pName }),
                       pScore.isWinner && pScore.score >= 75 {
                        unlocked = true
                        date = g.date
                        progress = "\(pScore.score) pt in Qwixx!"
                        break
                    }
                }

            default:
                break
            }

            return PlayerAchievementProgress(
                achievement: badge,
                isUnlocked: unlocked,
                progressText: progress,
                unlockedDate: date
            )
        }
    }
}
