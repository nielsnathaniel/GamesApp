import Foundation
import SwiftUI
import Combine

/// Payload structuur voor online synchronisatie tussen iOS en Android via Firebase Realtime Database REST API
struct GamesAppCloudPayload: Codable {
    var appVersion: String
    var exportDate: String
    var lastUpdated: Int64
    var lastUpdatedDevice: String?
    var playerNames: [String]
    var playedGames: [PlayedGame]
    var scores: [Score]
    var tafelschikking: [String]?
    var deletedGameIds: [String]?
}

/// Beheerder voor platformonafhankelijke cloud-synchronisatie (iOS <-> Android) met behulp van een koppelcode.
/// Werkt via de directe, lichte REST API van Firebase Realtime Database (geen zware SDK nodig).
final class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    // MARK: - Standaard Configuratie (Privé & Veilig)
    // Onze standaard database-URL wordt NOOIT getoond in de UI en blijft privé in de code.
    private static let internalDefaultDatabaseUrl = "https://gamesapp-858bc-default-rtdb.europe-west1.firebasedatabase.app"

    // UserDefaults Keys
    private let syncCodeKey = "cloud_sync_vault_code_v1"
    private let customDatabaseUrlKey = "cloud_sync_custom_database_url_v1"
    private let autoSyncKey = "cloud_sync_auto_enabled_v1"
    private let lastSyncTimestampKey = "cloud_sync_last_timestamp_v1"
    private let lastSyncSummaryKey = "cloud_sync_last_summary_v1"
    private let localDeletedIdsKey = "local_deleted_game_ids_v1"
    private let excludedPlayersKey = "cloud_sync_excluded_players_v1"

    // MARK: - Gepubliceerde Status
    @Published var syncCode: String = ""
    @Published var customDatabaseUrl: String = "" // Bevat UITSLUITEND een eigen ingevulde URL van de gebruiker (nooit onze default!)
    @Published var isAutoSyncEnabled: Bool = true
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date? = nil
    @Published var lastSyncSummary: String = ""
    @Published var lastErrorMessage: String? = nil
    @Published var excludedPlayerNames: Set<String> = [] // Spelers die de gebruiker NIET wil synchroniseren

    private let scoreManager = ScoreManager.shared
    private var autoSyncWorkItem: DispatchWorkItem? = nil
    private var isPerformingMerge: Bool = false

    private init() {
        self.syncCode = UserDefaults.standard.string(forKey: syncCodeKey) ?? ""

        // Alleen een EIGEN ingevulde URL inladen; onze interne standaard URL blijft verborgen
        let storedCustom = UserDefaults.standard.string(forKey: customDatabaseUrlKey) ?? ""
        if !storedCustom.isEmpty && !storedCustom.contains("gamesapp-858bc") && !storedCustom.contains("gamesapp-sync-default-rtdb") {
            self.customDatabaseUrl = storedCustom
        } else {
            self.customDatabaseUrl = ""
            UserDefaults.standard.removeObject(forKey: customDatabaseUrlKey)
        }

        if UserDefaults.standard.object(forKey: autoSyncKey) != nil {
            self.isAutoSyncEnabled = UserDefaults.standard.bool(forKey: autoSyncKey)
        }
        if let ts = UserDefaults.standard.object(forKey: lastSyncTimestampKey) as? Double {
            self.lastSyncDate = Date(timeIntervalSince1970: ts)
        }
        self.lastSyncSummary = UserDefaults.standard.string(forKey: lastSyncSummaryKey) ?? ""

        let storedExcluded = UserDefaults.standard.stringArray(forKey: excludedPlayersKey) ?? []
        self.excludedPlayerNames = Set(storedExcluded.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })

        // Initiële automatische synchronisatie bij opstarten
        if isConnected && isAutoSyncEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.syncNow()
            }
        }
    }

    // MARK: - Berekende Eigenschappen

    var isConnected: Bool {
        return !syncCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var cleanSyncCode: String {
        return syncCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    /// Geeft aan of de gebruiker een eigen database gebruikt in plaats van onze standaard
    var isUsingCustomDatabaseUrl: Bool {
        return !customDatabaseUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// De effectieve database URL die onder de motorkap wordt aangeroepen
    private var cleanDatabaseUrl: String {
        let raw = isUsingCustomDatabaseUrl ? customDatabaseUrl : CloudSyncManager.internalDefaultDatabaseUrl
        var url = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while url.hasSuffix("/") {
            url.removeLast()
        }
        if !url.lowercased().hasPrefix("http://") && !url.lowercased().hasPrefix("https://") {
            url = "https://" + url
        }
        return url
    }

    // MARK: - Configuratie & Eigen Database URL Opslaan

    func updateCustomDatabaseUrl(_ newUrl: String) {
        let trimmed = newUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        // Voorkom dat de gebruiker per ongeluk onze verborgen URL invoert
        if trimmed.contains("gamesapp-858bc") {
            self.customDatabaseUrl = ""
            UserDefaults.standard.removeObject(forKey: customDatabaseUrlKey)
        } else {
            self.customDatabaseUrl = trimmed
            UserDefaults.standard.set(trimmed, forKey: customDatabaseUrlKey)
        }
    }

    func resetDatabaseUrlToDefault() {
        self.customDatabaseUrl = ""
        UserDefaults.standard.removeObject(forKey: customDatabaseUrlKey)
    }

    func setAutoSyncEnabled(_ enabled: Bool) {
        self.isAutoSyncEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: autoSyncKey)
    }

    // MARK: - Speler-selectie voor Synchronisatie

    func isPlayerSyncEnabled(name: String) -> Bool {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return !excludedPlayerNames.contains(key)
    }

    func togglePlayerSync(name: String) {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return }
        if excludedPlayerNames.contains(key) {
            excludedPlayerNames.remove(key)
        } else {
            excludedPlayerNames.insert(key)
        }
        UserDefaults.standard.set(Array(excludedPlayerNames), forKey: excludedPlayersKey)
        scheduleAutoSync()
    }

    func setPlayerSyncEnabled(name: String, enabled: Bool) {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return }
        if enabled {
            excludedPlayerNames.remove(key)
        } else {
            excludedPlayerNames.insert(key)
        }
        UserDefaults.standard.set(Array(excludedPlayerNames), forKey: excludedPlayersKey)
        scheduleAutoSync()
    }

    func selectAllPlayers() {
        excludedPlayerNames.removeAll()
        UserDefaults.standard.set([], forKey: excludedPlayersKey)
        scheduleAutoSync()
    }

    func deselectAllPlayers(allPlayers: [String]) {
        excludedPlayerNames = Set(allPlayers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        UserDefaults.standard.set(Array(excludedPlayerNames), forKey: excludedPlayersKey)
        scheduleAutoSync()
    }

    // MARK: - Koppelcode Beheer

    /// Genereert een nieuwe, leesbare koppelcode (bijv. "SPEL-8429"), uploadt huidige data en activeert de koppeling
    func generateNewCode(completion: @escaping (Result<String, Error>) -> Void) {
        let alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Geen verwarrende 0/O of 1/I
        let randomChars = (0..<4).map { _ in alphabet.randomElement()! }
        let newCode = "SPEL-\(String(randomChars))"

        self.syncCode = newCode
        UserDefaults.standard.set(newCode, forKey: syncCodeKey)

        // Upload huidige lokale data naar deze nieuwe kluis
        uploadLocalDataOnly(code: newCode) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(.success(newCode))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /// Koppelt met een bestaande code, downloadt de online data en voegt deze samen met de lokale data
    func connectWithCode(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        let clean = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !clean.isEmpty else {
            completion(.failure(NSError(domain: "CloudSync", code: 400, userInfo: [NSLocalizedDescriptionKey: "Voer een geldige koppelcode in."])))
            return
        }

        self.syncCode = clean
        UserDefaults.standard.set(clean, forKey: syncCodeKey)

        // Direct synchroniseren en samenvoegen
        syncNow { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let summary):
                    completion(.success(summary))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /// Verbreekt de koppeling met de cloud (lokale data blijft onaangeroerd bewaard)
    func disconnect() {
        self.syncCode = ""
        UserDefaults.standard.removeObject(forKey: syncCodeKey)
        self.lastSyncSummary = "Niet gekoppeld"
        UserDefaults.standard.set(self.lastSyncSummary, forKey: lastSyncSummaryKey)
    }

    // MARK: - Synchronisatie Uitvoeren

    /// Plant een automatische sync in op de achtergrond (debounced op 1.5s om snelle opeenvolgende acties te bundelen)
    func scheduleAutoSync() {
        guard isConnected, isAutoSyncEnabled, !isPerformingMerge else { return }

        autoSyncWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.syncNow()
        }
        autoSyncWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    /// Controleert en synchroniseert indien verbonden
    func syncNowIfNeeded() {
        guard isConnected, isAutoSyncEnabled else { return }
        syncNow()
    }

    /// Voert een volledige tweewegs-synchronisatie uit: downloaden -> mergen -> uploaden van het samengevoegde resultaat
    func syncNow(completion: ((Result<String, Error>) -> Void)? = nil) {
        guard isConnected else {
            completion?(.failure(NSError(domain: "CloudSync", code: 404, userInfo: [NSLocalizedDescriptionKey: "Geen koppelcode ingesteld."])))
            return
        }
        guard !isPerformingMerge else {
            completion?(.success("Synchronisatie al bezig..."))
            return
        }

        let code = cleanSyncCode
        guard let url = URL(string: "\(cleanDatabaseUrl)/vaults/\(code).json") else {
            completion?(.failure(NSError(domain: "CloudSync", code: 400, userInfo: [NSLocalizedDescriptionKey: "Ongeldige database-URL."])))
            return
        }

        DispatchQueue.main.async {
            self.isSyncing = true
            self.lastErrorMessage = nil
        }
        self.isPerformingMerge = true

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15.0

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                self.finishSync(error: error, completion: completion)
                return
            }

            // Controleer HTTP status
            if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                let err = NSError(domain: "CloudSync", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server gaf HTTP \(http.statusCode) terug. Controleer de Firebase-regels of database-URL."])
                self.finishSync(error: err, completion: completion)
                return
            }

            guard let data = data, !data.isEmpty else {
                // Leeg antwoord, upload lokale data
                self.uploadMergedData(code: code, completion: completion)
                return
            }

            let rawString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if rawString == "null" || rawString.isEmpty {
                // Kluis bestaat online nog niet -> initialiseer met lokale data
                self.uploadMergedData(code: code, completion: completion)
                return
            }

            // Decodeer online payload
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let cloudPayload = try decoder.decode(GamesAppCloudPayload.self, from: data)

                // Voer samenvoeging uit op achtergrondthread
                self.mergeCloudDataIntoLocal(cloudPayload)

                // Upload het samengevoegde resultaat terug zodat de cloud ook up-to-date is
                self.uploadMergedData(code: code, completion: completion)
            } catch {
                print("Fout bij decoderen van cloud payload: \(error)")
                self.uploadMergedData(code: code, completion: completion)
            }
        }.resume()
    }

    // MARK: - Samenvoegen van Cloud & Lokale Data

    private func mergeCloudDataIntoLocal(_ cloud: GamesAppCloudPayload) {
        // 1. Tombstones (verwijderde games) samenvoegen
        var localDeletedIds = Set(UserDefaults.standard.stringArray(forKey: localDeletedIdsKey) ?? [])
        if let cloudDeleted = cloud.deletedGameIds {
            localDeletedIds.formUnion(cloudDeleted)
        }
        UserDefaults.standard.set(Array(localDeletedIds), forKey: localDeletedIdsKey)

        // 2. Spelersnamen samenvoegen
        var currentPlayers = Set(scoreManager.fetchPlayerNames())
        for p in cloud.playerNames {
            let trimmed = p.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                currentPlayers.insert(trimmed)
            }
        }

        // 3. Spellen samenvoegen (deduplicatie op UUID, tombstones uitsluiten)
        var localGames = scoreManager.fetchGames()
        localGames.removeAll { localDeletedIds.contains($0.id.uuidString) }

        var gamesMap: [UUID: PlayedGame] = [:]
        for g in localGames {
            gamesMap[g.id] = g
        }

        for cg in cloud.playedGames {
            guard !localDeletedIds.contains(cg.id.uuidString) else { continue }
            if gamesMap[cg.id] == nil {
                gamesMap[cg.id] = cg
            }
        }

        let mergedGames = Array(gamesMap.values).sorted(by: { $0.date > $1.date })

        // 4. Scores samenvoegen
        var localScores = scoreManager.fetchScores()
        localScores.removeAll { localDeletedIds.contains($0.id.uuidString) }

        var scoresMap: [UUID: Score] = [:]
        for s in localScores {
            scoresMap[s.id] = s
        }

        for cs in cloud.scores {
            guard !localDeletedIds.contains(cs.id.uuidString) else { continue }
            if scoresMap[cs.id] == nil {
                scoresMap[cs.id] = cs
            }
        }

        let mergedScores = Array(scoresMap.values).sorted(by: { $0.date > $1.date })

        // 5. Tafelschikking bijwerken
        if let cloudTafel = cloud.tafelschikking, !cloudTafel.isEmpty {
            if scoreManager.savedTafelschikking.isEmpty {
                scoreManager.savedTafelschikking = cloudTafel
                scoreManager.saveTafelschikking(cloudTafel)
            }
        }

        // 6. Opslaan in ScoreManager op hoofddraad
        DispatchQueue.main.sync {
            self.scoreManager.saveAllPlayerNames(Array(currentPlayers).sorted())
            self.scoreManager.saveAllGames(mergedGames)
            self.scoreManager.saveAllScores(mergedScores)
            self.scoreManager.refresh()
        }
    }

    // MARK: - Uploaden naar Firebase REST (Met Spelersfilter)

    private func uploadMergedData(code: String, completion: ((Result<String, Error>) -> Void)?) {
        guard let url = URL(string: "\(cleanDatabaseUrl)/vaults/\(code).json") else {
            finishSync(error: NSError(domain: "CloudSync", code: 400, userInfo: [NSLocalizedDescriptionKey: "Ongeldige database-URL."]), completion: completion)
            return
        }

        let localDeletedIds = Array(Set(UserDefaults.standard.stringArray(forKey: localDeletedIdsKey) ?? []))

        // Alleen spelers die actief zijn goedgekeurd voor synchronisatie
        let allPlayers = scoreManager.fetchPlayerNames()
        let playersToSync = allPlayers.filter { isPlayerSyncEnabled(name: $0) }
        let syncedPlayerSet = Set(playersToSync.map { $0.lowercased() })

        // Alleen potjes synchroniseren waarvan alle deelnemers geselecteerd zijn
        let gamesToSync = scoreManager.playedGames.filter { game in
            let participants = game.playerNamesList.map { $0.lowercased() }
            return !participants.isEmpty && participants.allSatisfy { syncedPlayerSet.contains($0) }
        }

        // Alleen scores van gesynchroniseerde spelers
        let scoresToSync = scoreManager.scores.filter { sc in
            syncedPlayerSet.contains(sc.playerName.lowercased())
        }

        let tafel = scoreManager.savedTafelschikking.filter { isPlayerSyncEnabled(name: $0) }

        let now = Date()
        let isoFormatter = ISO8601DateFormatter()
        let payload = GamesAppCloudPayload(
            appVersion: "1.0",
            exportDate: isoFormatter.string(from: now),
            lastUpdated: Int64(now.timeIntervalSince1970 * 1000),
            lastUpdatedDevice: "iOS",
            playerNames: playersToSync,
            playedGames: gamesToSync,
            scores: scoresToSync,
            tafelschikking: tafel,
            deletedGameIds: localDeletedIds
        )

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.sortedKeys]
            let jsonData = try encoder.encode(payload)

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            request.timeoutInterval = 15.0

            URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
                guard let self = self else { return }

                if let error = error {
                    self.finishSync(error: error, completion: completion)
                    return
                }

                if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                    let err = NSError(domain: "CloudSync", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Upload mislukt met HTTP code \(http.statusCode). Controleer de database-rechten."])
                    self.finishSync(error: err, completion: completion)
                    return
                }

                let summary = "Gesynchroniseerd: \(gamesToSync.count) potjes en \(playersToSync.count) spelers up-to-date."
                self.finishSync(successSummary: summary, completion: completion)
            }.resume()
        } catch {
            finishSync(error: error, completion: completion)
        }
    }

    private func uploadLocalDataOnly(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        uploadMergedData(code: code, completion: completion)
    }

    private func finishSync(successSummary: String? = nil, error: Error? = nil, completion: ((Result<String, Error>) -> Void)?) {
        DispatchQueue.main.async {
            self.isSyncing = false
            self.isPerformingMerge = false

            if let error = error {
                self.lastErrorMessage = error.localizedDescription
                completion?(.failure(error))
            } else if let summary = successSummary {
                self.lastSyncDate = Date()
                self.lastSyncSummary = summary
                UserDefaults.standard.set(self.lastSyncDate?.timeIntervalSince1970, forKey: self.lastSyncTimestampKey)
                UserDefaults.standard.set(summary, forKey: self.lastSyncSummaryKey)
                completion?(.success(summary))
            }
        }
    }

    // MARK: - Testen van Database Verbinding (Veilig via /vaults/_ping.json)

    func testConnection(completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "\(cleanDatabaseUrl)/vaults/_ping.json") else {
            completion(false, "Ongeldige URL indeling.")
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 8.0

        URLSession.shared.dataTask(with: req) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Verbindingsfout: \(error.localizedDescription)")
                    return
                }
                if let http = response as? HTTPURLResponse {
                    if http.statusCode == 200 {
                        completion(true, "Verbinding met Firebase Realtime Database is geslaagd! (HTTP 200)")
                    } else if http.statusCode == 401 || http.statusCode == 403 {
                        completion(false, "Toegang geweigerd (HTTP \(http.statusCode)). Controleer de Firebase Security Rules.")
                    } else {
                        completion(false, "Server gaf HTTP statuscode \(http.statusCode) terug.")
                    }
                } else {
                    completion(false, "Geen antwoord van server ontvangen.")
                }
            }
        }.resume()
    }
}
