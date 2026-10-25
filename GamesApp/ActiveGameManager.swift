import Foundation
import SwiftUI
import Combine

/// Model voor een niet-afgerond spel dat kan worden hervat
struct ActiveGameSession: Codable, Identifiable {
    var id: UUID = UUID()
    let gameName: String
    let dateStarted: Date
    let playerNames: [String]
    let currentRound: Int
    let summary: String
    let stateData: [String: String]
}

/// Centrale beheerder voor crash-bescherming en het bewaren/hervatten van lopende spelsessies
final class ActiveGameManager: ObservableObject {
    static let shared = ActiveGameManager()

    private let storageKey = "gamesapp_active_game_draft"

    @Published var activeSession: ActiveGameSession?

    private init() {
        self.activeSession = loadFromDisk()
    }

    var hasActiveSession: Bool {
        activeSession != nil
    }

    /// Sla een actieve spelsessie op (bij elke scorewijziging of ronde-overgang)
    func saveActiveGame(
        gameName: String,
        playerNames: [String],
        currentRound: Int,
        summary: String,
        state: [String: String] = [:]
    ) {
        let session = ActiveGameSession(
            gameName: gameName,
            dateStarted: activeSession?.gameName == gameName ? (activeSession?.dateStarted ?? Date()) : Date(),
            playerNames: playerNames,
            currentRound: currentRound,
            summary: summary,
            stateData: state
        )

        self.activeSession = session
        persistToDisk(session)
    }

    /// Ruim het opgeslagen lopende spel op (wanneer het spel voltooid of gereset is)
    func clearActiveGame() {
        self.activeSession = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func persistToDisk(_ session: ActiveGameSession) {
        do {
            let data = try JSONEncoder().encode(session)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Fout bij opslaan van actieve spelsessie: \(error)")
        }
    }

    private func loadFromDisk() -> ActiveGameSession? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        do {
            return try JSONDecoder().decode(ActiveGameSession.self, from: data)
        } catch {
            print("Fout bij inladen actieve spelsessie: \(error)")
            return nil
        }
    }
}
