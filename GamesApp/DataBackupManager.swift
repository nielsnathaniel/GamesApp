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

/// Volledig iCloud synchronisatie-formaat (inclusief tombstones van verwijderde potjes)
struct GamesAppSyncPayload: Codable {
    let appVersion: String
    let exportDate: Date
    let playerNames: [String]
    let playedGames: [PlayedGame]
    let scores: [Score]
    let deletedGameIds: [String]?
}

/// Beheerder voor JSON exporteren/importeren en volledige iCloud synchronisatie (spellen, scores, spelers)
final class DataBackupManager: ObservableObject {
    static let shared = DataBackupManager()

    private let scoreManager = ScoreManager.shared

    // iCloud Keys
    private let iCloudFullPayloadKey = "icloud_full_sync_payload_v2"
    private let iCloudPlayerKey = "icloud_saved_player_names"
    private let iCloudBackupMetaKey = "icloud_last_backup_meta"
    private let iCloudLastSyncTimestampKey = "icloud_last_sync_timestamp"
    private let iCloudDeletedIdsKey = "icloud_deleted_game_ids_v1"

    // Lokale opslag voor verwijderde game IDs (tombstones) zodat verwijderde potjes niet terugkeren via sync
    private let localDeletedIdsKey = "local_deleted_game_ids_v1"
    private let lastSyncDateKey = "local_last_icloud_sync_date"
    private let lastSyncSummaryKey = "local_last_icloud_sync_summary"

    @Published var lastExportURL: URL? = nil
    @Published var lastSyncDate: Date? = nil
    @Published var lastSyncSummary: String = ""
    @Published var isSyncing: Bool = false
    @AppStorage("auto_icloud_sync_enabled") var isAutoSyncEnabled: Bool = true

    private var autoSyncWorkItem: DispatchWorkItem? = nil
    private var isPerformingCloudMerge: Bool = false

    private init() {
        if let storedDate = UserDefaults.standard.object(forKey: lastSyncDateKey) as? Date {
            self.lastSyncDate = storedDate
        }
        self.lastSyncSummary = UserDefaults.standard.string(forKey: lastSyncSummaryKey) ?? ""

        listenForiCloudChanges()

        // Automatische initiële sync bij het starten van de app
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self, self.isAutoSyncEnabled else { return }
            self.syncAllDataToiCloud()
        }
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
                syncAllDataToiCloud()
                return .success(summary)
            } else {
                // Volledig overschrijven
                scoreManager.saveAllPlayerNames(backup.playerNames)
                scoreManager.saveAllGames(backup.playedGames)
                scoreManager.saveAllScores(backup.scores)
                scoreManager.refresh()

                let summary = "Hersteld: \(backup.playerNames.count) spelers en \(backup.playedGames.count) spelsessies ingeladen."
                syncAllDataToiCloud()
                return .success(summary)
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Verwijderde IDs (Tombstones)

    func recordDeletedGameIds<S: Sequence>(_ ids: S) where S.Element == UUID {
        var existing = Set(UserDefaults.standard.stringArray(forKey: localDeletedIdsKey) ?? [])
        for id in ids {
            existing.insert(id.uuidString)
        }
        UserDefaults.standard.set(Array(existing), forKey: localDeletedIdsKey)
        scheduleAutoSyncToiCloud()
    }

    private func getLocalDeletedIds() -> Set<String> {
        return Set(UserDefaults.standard.stringArray(forKey: localDeletedIdsKey) ?? [])
    }

    // MARK: - Automatische Debounced Sync

    /// Plant een automatische achtergrond-sync na kleine vertraging (voorkomt spammen bij snel achter elkaar opslaan)
    func scheduleAutoSyncToiCloud() {
        guard isAutoSyncEnabled, !isPerformingCloudMerge else { return }

        autoSyncWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.syncAllDataToiCloud()
        }
        autoSyncWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
    }

    // MARK: - Volledige iCloud Synchronisatie (Spelers, Gespeelde Spellen & Scores)

    /// Voert een volledige tweerichtingensync uit met iCloud Key-Value Store
    func syncAllDataToiCloud(force: Bool = false, completion: ((Result<String, Error>) -> Void)? = nil) {
        guard !isPerformingCloudMerge else { return }
        isPerformingCloudMerge = true

        DispatchQueue.main.async {
            self.isSyncing = true
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let store = NSUbiquitousKeyValueStore.default
            store.synchronize()

            // 1. Lokale gegevens ophalen
            var localPlayers = Set(self.scoreManager.fetchPlayerNames())
            var localGames = self.scoreManager.fetchGames()
            var localScores = self.scoreManager.fetchScores()
            var localDeletedIds = self.getLocalDeletedIds()

            // 2. iCloud data ophalen en decoderen
            var cloudPayload: GamesAppSyncPayload? = nil
            if let cloudData = store.data(forKey: self.iCloudFullPayloadKey) {
                let decompressed = self.decompressIfNeeded(cloudData)
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    cloudPayload = try decoder.decode(GamesAppSyncPayload.self, from: decompressed)
                } catch {
                    print("Waarschuwing: kon cloud payload niet decoderen (\(error)).")
                }
            }

            // Oudere fallback: als er alleen spelers in iCloud stonden
            var legacyPlayers: [String] = []
            if cloudPayload == nil, let arr = store.array(forKey: self.iCloudPlayerKey) as? [String] {
                legacyPlayers = arr
            }

            // 3. Samenvoegen van tombstones (verwijderde spellen)
            if let cloudDeleted = cloudPayload?.deletedGameIds {
                localDeletedIds.formUnion(cloudDeleted)
            }
            UserDefaults.standard.set(Array(localDeletedIds), forKey: self.localDeletedIdsKey)

            // Filter lokale games en scores die verwijderd zijn
            localGames.removeAll { localDeletedIds.contains($0.id.uuidString) }
            localScores.removeAll { localDeletedIds.contains($0.id.uuidString) }

            var hasLocalChanges = false

            // 4. Samenvoegen van Cloud Games met Lokale Games
            var mergedGamesDict: [UUID: PlayedGame] = [:]
            for g in localGames {
                mergedGamesDict[g.id] = g
            }

            if let cloudGames = cloudPayload?.playedGames {
                for cg in cloudGames {
                    guard !localDeletedIds.contains(cg.id.uuidString) else { continue }
                    if mergedGamesDict[cg.id] == nil {
                        mergedGamesDict[cg.id] = cg
                        hasLocalChanges = true
                    }
                }
            }

            let finalGames = Array(mergedGamesDict.values).sorted { $0.date > $1.date }

            // 5. Samenvoegen van Scores
            var mergedScoresDict: [UUID: Score] = [:]
            for s in localScores {
                mergedScoresDict[s.id] = s
            }

            if let cloudScores = cloudPayload?.scores {
                for cs in cloudScores {
                    guard !localDeletedIds.contains(cs.id.uuidString) else { continue }
                    if mergedScoresDict[cs.id] == nil {
                        mergedScoresDict[cs.id] = cs
                        hasLocalChanges = true
                    }
                }
            }
            let finalScores = Array(mergedScoresDict.values).sorted { $0.date > $1.date }

            // 6. Samenvoegen van Spelers
            if let cloudPlayers = cloudPayload?.playerNames {
                for p in cloudPlayers {
                    let trimmed = p.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty && !localPlayers.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                        localPlayers.insert(trimmed)
                        hasLocalChanges = true
                    }
                }
            }
            for lp in legacyPlayers {
                let trimmed = lp.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && !localPlayers.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                    localPlayers.insert(trimmed)
                    hasLocalChanges = true
                }
            }
            let finalPlayers = self.scoreManager.sortPlayersByPopularity(Array(localPlayers))

            // 7. Lokale data updaten indien nieuw van iCloud
            if hasLocalChanges {
                DispatchQueue.main.async {
                    self.scoreManager.saveAllPlayerNames(finalPlayers)
                    self.scoreManager.saveAllGames(finalGames)
                    self.scoreManager.saveAllScores(finalScores)
                    self.scoreManager.refresh()
                }
            }

            // 8. Uploaden van de complete samengevoegde toestand naar iCloud
            let newPayload = GamesAppSyncPayload(
                appVersion: "2.0",
                exportDate: Date(),
                playerNames: finalPlayers,
                playedGames: finalGames,
                scores: finalScores,
                deletedGameIds: Array(localDeletedIds)
            )

            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let rawData = try encoder.encode(newPayload)
                let compressedData = self.compressIfNeeded(rawData)

                store.set(compressedData, forKey: self.iCloudFullPayloadKey)
                store.set(Array(localDeletedIds), forKey: self.iCloudDeletedIdsKey)
                store.set(finalPlayers, forKey: self.iCloudPlayerKey)

                let metaStr = "Gesynchroniseerd: \(finalGames.count) potjes, \(finalPlayers.count) spelers"
                store.set(metaStr, forKey: self.iCloudBackupMetaKey)
                store.set(Date().timeIntervalSince1970, forKey: self.iCloudLastSyncTimestampKey)
                store.synchronize()

                let now = Date()
                DispatchQueue.main.async {
                    self.lastSyncDate = now
                    self.lastSyncSummary = metaStr
                    self.isSyncing = false
                    self.isPerformingCloudMerge = false
                    UserDefaults.standard.set(now, forKey: self.lastSyncDateKey)
                    UserDefaults.standard.set(metaStr, forKey: self.lastSyncSummaryKey)
                    completion?(.success(metaStr))
                }
            } catch {
                print("Fout bij encoderen/uploaden naar iCloud: \(error)")
                DispatchQueue.main.async {
                    self.isSyncing = false
                    self.isPerformingCloudMerge = false
                    completion?(.failure(error))
                }
            }
        }
    }

    /// Alias voor achterwaartse compatibiliteit
    func syncPlayersToiCloud() {
        syncAllDataToiCloud()
    }

    // MARK: - iCloud Wijzigingen van Andere Toestellen Beluisteren

    private func listenForiCloudChanges() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            // Als er externe wijzigingen van een ander toestel binnenkomen, synchroniseer en merge
            print("iCloud externe wijziging ontvangen. Bezig met synchroniseren...")
            self.syncAllDataToiCloud()
        }
    }

    // MARK: - Datacompressie Helpers (zlib)

    /// Comprimeert data met zlib indien groter dan 20KB om ver onder de 1MB iCloud KVS limiet te blijven
    private func compressIfNeeded(_ data: Data) -> Data {
        guard data.count > 20_000 else { return data }
        do {
            let compressed = try (data as NSData).compressed(using: .zlib) as Data
            // Voeg een 4-byte marker 'ZLBF' toe zodat we direct weten dat het gecomprimeerd is
            var tagged = Data([0x5A, 0x4C, 0x42, 0x46])
            tagged.append(compressed)
            return tagged
        } catch {
            return data
        }
    }

    /// Decomprimeert data indien voorzien van de 'ZLBF' marker
    private func decompressIfNeeded(_ data: Data) -> Data {
        if data.count >= 4 && data.prefix(4) == Data([0x5A, 0x4C, 0x42, 0x46]) {
            let payload = data.dropFirst(4)
            if let decompressed = try? (payload as NSData).decompressed(using: .zlib) as Data {
                return decompressed
            }
        }
        return data
    }
}
