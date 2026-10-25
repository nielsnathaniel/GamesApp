import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Volledig backup-bestand formaat van de GamesApp
struct GamesAppBackupPayload: Codable {
    let appVersion: String
    let exportDate: Date
    let playerNames: [String]
    let playedGames: [PlayedGame]
    let scores: [Score]
}

/// Beheerder voor JSON exporteren, importeren en iCloud Key-Value synchronisatie
final class DataBackupManager: ObservableObject {
    static let shared = DataBackupManager()

    private let scoreManager = ScoreManager.shared
    private let iCloudPlayerKey = "icloud_saved_player_names"
    private let iCloudBackupMetaKey = "icloud_last_backup_meta"

    @Published var lastExportURL: URL? = nil
    @Published var lastSyncDate: Date? = nil

    private init() {
        listenForiCloudChanges()
    }

    // MARK: - JSON Export

    /// Genereert een JSON backup-bestand en geeft de bestands-URL terug
    func generateBackupFile() -> URL? {
        let backup = GamesAppBackupPayload(
            appVersion: "1.0",
            exportDate: Date(),
            playerNames: scoreManager.fetchPlayerNames(),
            playedGames: scoreManager.playedGames,
            scores: scoreManager.scores
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(backup)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
            let dateStr = dateFormatter.string(from: Date())
            let fileName = "GamesApp_Backup_\(dateStr).json"

            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)

            try data.write(to: fileURL, options: .atomic)
            self.lastExportURL = fileURL
            return fileURL
        } catch {
            print("Fout bij aanmaken backup: \(error)")
            return nil
        }
    }

    // MARK: - JSON Import

    /// Importeert data uit een geselecteerd JSON-bestand (met optie voor samenvoegen of overschrijven)
    func importBackup(from fileURL: URL, merge: Bool) -> Result<String, Error> {
        let shouldStopAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(GamesAppBackupPayload.self, from: data)

            if merge {
                // Samenvoegen met bestaande data
                var currentPlayers = Set(scoreManager.fetchPlayerNames())
                for name in backup.playerNames {
                    currentPlayers.insert(name)
                }

                var currentGames = scoreManager.playedGames
                let existingGameIds = Set(currentGames.map { $0.id })
                let newGames = backup.playedGames.filter { !existingGameIds.contains($0.id) }
                currentGames.append(contentsOf: newGames)

                var currentScores = scoreManager.scores
                let existingScoreIds = Set(currentScores.map { $0.id })
                let newScores = backup.scores.filter { !existingScoreIds.contains($0.id) }
                currentScores.append(contentsOf: newScores)

                // Opslaan
                scoreManager.saveAllPlayerNames(Array(currentPlayers).sorted())
                scoreManager.saveAllGames(currentGames)
                scoreManager.saveAllScores(currentScores)
                scoreManager.refresh()

                let summary = "Samengevoegd: \(backup.playerNames.count) spelers en \(newGames.count) nieuwe spelsessies toegevoegd."
                syncPlayersToiCloud()
                return .success(summary)
            } else {
                // Volledig overschrijven
                scoreManager.saveAllPlayerNames(backup.playerNames)
                scoreManager.saveAllGames(backup.playedGames)
                scoreManager.saveAllScores(backup.scores)
                scoreManager.refresh()

                let summary = "Hersteld: \(backup.playerNames.count) spelers en \(backup.playedGames.count) spelsessies ingeladen."
                syncPlayersToiCloud()
                return .success(summary)
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - iCloud Synchronisatie (NSUbiquitousKeyValueStore)

    /// Synchroniseert opgeslagen spelersnamen naar iCloud
    func syncPlayersToiCloud() {
        let store = NSUbiquitousKeyValueStore.default
        let currentPlayers = scoreManager.fetchPlayerNames()
        store.set(currentPlayers, forKey: iCloudPlayerKey)

        let meta = "Laatste sync: \(Date().formatted(date: .numeric, time: .shortened)) (\(scoreManager.playedGames.count) potjes)"
        store.set(meta, forKey: iCloudBackupMetaKey)
        store.synchronize()

        DispatchQueue.main.async {
            self.lastSyncDate = Date()
        }
    }

    /// Laadt spelersnamen in vanuit iCloud indien aanwezig
    func fetchPlayersFromiCloud() -> [String]? {
        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()
        return store.array(forKey: iCloudPlayerKey) as? [String]
    }

    private func listenForiCloudChanges() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if let cloudPlayers = self.fetchPlayersFromiCloud(), !cloudPlayers.isEmpty {
                var localPlayers = Set(self.scoreManager.fetchPlayerNames())
                localPlayers.formUnion(cloudPlayers)
                self.scoreManager.saveAllPlayerNames(Array(localPlayers).sorted())
                self.scoreManager.refresh()
                self.lastSyncDate = Date()
            }
        }
    }
}
