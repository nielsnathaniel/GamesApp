import SwiftUI

struct GegevensbeheerView: View {
    @ObservedObject private var scoreManager = ScoreManager.shared
    @ObservedObject private var backupManager = DataBackupManager.shared

    @State private var showClearHistoryAlert: Bool = false
    @State private var showClearPlayersAlert: Bool = false

    // Backup & Sync
    @State private var showExportSheet: Bool = false
    @State private var exportFileURL: URL? = nil
    @State private var showFileImporter: Bool = false
    @State private var pendingImportURL: URL? = nil
    @State private var showImportMergeDialog: Bool = false
    @State private var importStatusMessage: String = ""
    @State private var showStatusAlert: Bool = false
    @State private var isSyncingCloud: Bool = false

    var body: some View {
        List {
            // Samenvatting Header Card
            Section {
                HStack(spacing: 16) {
                    // Spelers indicator
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("Spelers")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("\(scoreManager.fetchPlayerNames().count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(10)

                    // Spelsessies indicator
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Sessies")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("\(scoreManager.playedGames.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }

            // Beheer navigatie knoppen
            Section(header: Text("Beheer")) {
                // Knop naar Opgeslagen Spelers
                NavigationLink(destination: OpgeslagenSpelersView()) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .semibold))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Opgeslagen Spelers")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Spelers bekijken, toevoegen en verwijderen")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("\(scoreManager.fetchPlayerNames().count)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                }

                // Knop naar Opgeslagen Spelsessies
                NavigationLink(destination: SpelsessiesBeheerView()) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.orange)
                                .font(.system(size: 16, weight: .semibold))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Opgeslagen Spelsessies")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Geschiedenis per dag, spel of sessie wissen")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("\(scoreManager.playedGames.count)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                }
            }

            // Backup & Synchronisatie (JSON & iCloud)
            Section(
                header: Label("Backup & Synchronisatie", systemImage: "arrow.triangle.2.circlepath.icloud.fill"),
                footer: Text("Exporteer al je data als JSON-bestand om op te slaan in Bestanden, te delen via AirDrop/WhatsApp, of over te zetten naar een ander toestel.")
            ) {
                // Exporteer knop
                Button(action: {
                    HapticManager.shared.light()
                    if let url = backupManager.generateBackupFile() {
                        exportFileURL = url
                        showExportSheet = true
                    }
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "square.and.arrow.up.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 16, weight: .semibold))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Exporteer Backup (JSON)")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Alle spelers, potjes en scores opslaan")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Importeer knop
                Button(action: {
                    HapticManager.shared.light()
                    showFileImporter = true
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "square.and.arrow.down.fill")
                                .foregroundColor(.purple)
                                .font(.system(size: 16, weight: .semibold))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Importeer Backup")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Herstel data vanuit een eerder JSON-bestand")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // iCloud synchronisatie knop
                Button(action: {
                    HapticManager.shared.medium()
                    isSyncingCloud = true
                    backupManager.syncPlayersToiCloud()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        isSyncingCloud = false
                        importStatusMessage = "Spelersnamen succesvol gesynchroniseerd met iCloud!"
                        showStatusAlert = true
                    }
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: isSyncingCloud ? "arrow.triangle.2.circlepath" : "icloud.and.arrow.up.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .semibold))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("iCloud Synchronisatie")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            if let syncDate = backupManager.lastSyncDate {
                                Text("Laatst bijgewerkt: \(syncDate.formatted(date: .numeric, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Tik om spelers te synchroniseren")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Gevaarlijke Acties / Volledige Reset
            Section(header: Text("Volledige Reset"), footer: Text("Let op: Deze acties kunnen niet ongedaan worden gemaakt. Gebruik 'Opgeslagen Spelsessies' om gericht per dag of potje te verwijderen.")) {
                Button(role: .destructive, action: {
                    showClearHistoryAlert = true
                }) {
                    Label("Alle spelgeschiedenis & scores wissen", systemImage: "arrow.counterclockwise")
                        .foregroundColor(.red)
                }

                Button(role: .destructive, action: {
                    showClearPlayersAlert = true
                }) {
                    Label("Alle opgeslagen spelers wissen", systemImage: "person.crop.circle.badge.minus")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Gegevensbeheer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            scoreManager.refresh()
        }
        .confirmationDialog(
            "Weet je zeker dat je alle spelgeschiedenis wilt wissen?",
            isPresented: $showClearHistoryAlert,
            titleVisibility: .visible
        ) {
            Button("Alle geschiedenis wissen", role: .destructive) {
                withAnimation {
                    scoreManager.clearHistory()
                }
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            Text("Alle opgeslagen potjes, statistieken en scores worden permanent verwijderd.")
        }
        .confirmationDialog(
            "Weet je zeker dat je alle opgeslagen spelers wilt wissen?",
            isPresented: $showClearPlayersAlert,
            titleVisibility: .visible
        ) {
            Button("Alle spelers wissen", role: .destructive) {
                withAnimation {
                    scoreManager.clearAllPlayers()
                }
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            Text("Alle opgeslagen spelersnamen worden gewist. Je kunt ze later weer handmatig of bij een nieuw spel toevoegen.")
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    pendingImportURL = url
                    showImportMergeDialog = true
                }
            case .failure(let error):
                importStatusMessage = "Fout bij selecteren bestand: \(error.localizedDescription)"
                showStatusAlert = true
            }
        }
        .confirmationDialog(
            "Hoe wil je de backup importeren?",
            isPresented: $showImportMergeDialog,
            titleVisibility: .visible
        ) {
            Button("Samenvoegen met huidige data") {
                if let url = pendingImportURL {
                    executeImport(url: url, merge: true)
                }
            }
            Button("Alles overschrijven (Vervangen)", role: .destructive) {
                if let url = pendingImportURL {
                    executeImport(url: url, merge: false)
                }
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            Text("Kies 'Samenvoegen' om nieuwe potjes en spelers toe te voegen zonder je huidige data kwijt te raken.")
        }
        .alert("Backup Status", isPresented: $showStatusAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importStatusMessage)
        }
    }

    private func executeImport(url: URL, merge: Bool) {
        let result = backupManager.importBackup(from: url, merge: merge)
        switch result {
        case .success(let message):
            HapticManager.shared.success()
            importStatusMessage = message
            showStatusAlert = true
        case .failure(let error):
            HapticManager.shared.error()
            importStatusMessage = "Importeren mislukt: \(error.localizedDescription)"
            showStatusAlert = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        GegevensbeheerView()
    }
}
