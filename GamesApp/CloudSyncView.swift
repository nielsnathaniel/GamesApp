import SwiftUI

struct CloudSyncView: View {
    @ObservedObject private var syncManager = CloudSyncManager.shared

    @State private var inputCode: String = ""
    @State private var customDatabaseUrl: String = ""
    @State private var showDisconnectAlert: Bool = false
    @State private var showHelpSheet: Bool = false
    @State private var testStatusMessage: String? = nil
    @State private var isTestingConnection: Bool = false
    @State private var copiedToClipboard: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Form {
            // MARK: - 1. Hero Header
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 64, height: 64)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 4)

                    Text("Online Synchronisatie")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Houd al je spellen, scores, statistieken en tafelschikking automatisch 100% up-to-date tussen iOS en Android met één unieke koppelcode.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            // MARK: - 2. Koppelcode & Verbindingsstatus
            if syncManager.isConnected {
                connectedSection
            } else {
                notConnectedSection
            }

            // MARK: - 3. Server & Geavanceerde Instellingen
            Section(
                header: Text("Server & Database"),
                footer: Text("Standaard gebruikt GamesApp een gedeelde Firebase Realtime Database. Je kunt hier ook je eigen gratis Firebase URL invullen.")
            ) {
                DisclosureGroup("Geavanceerde Database Instellingen") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Firebase Database URL:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("https://jouw-project-default-rtdb...", text: $customDatabaseUrl)
                            .font(.caption)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .padding(8)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(8)

                        HStack(spacing: 10) {
                            Button("Opslaan") {
                                HapticManager.shared.light()
                                syncManager.updateDatabaseUrl(customDatabaseUrl)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)

                            Button("Herstel Standaard") {
                                HapticManager.shared.light()
                                syncManager.resetDatabaseUrlToDefault()
                                customDatabaseUrl = syncManager.databaseUrl
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Spacer()

                            Button(action: runConnectionTest) {
                                if isTestingConnection {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Test Verbinding")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(isTestingConnection)
                        }

                        if let testMsg = testStatusMessage {
                            Text(testMsg)
                                .font(.caption2)
                                .foregroundColor(testMsg.contains("geslaagd") ? .green : .red)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Button(action: { showHelpSheet = true }) {
                    Label("Hoe stel ik mijn eigen Firebase in? (Uitleg)", systemImage: "questionmark.circle")
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("Cloud Synchronisatie")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            customDatabaseUrl = syncManager.databaseUrl
        }
        .alert("Toestel Ontkoppelen?", isPresented: $showDisconnectAlert) {
            Button("Ontkoppel", role: .destructive) {
                HapticManager.shared.medium()
                syncManager.disconnect()
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            Text("Je apparaat wordt losgekoppeld van deze cloud-kluis. Al je huidige spelers en scores blijven veilig lokaal op je toestel bewaard.")
        }
        .sheet(isPresented: $showHelpSheet) {
            firebaseHelpSheet
        }
    }

    // MARK: - A. Reeds Verbonden Weergave

    private var connectedSection: some View {
        Group {
            Section(header: Text("Actieve Koppeling")) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("JOUW KOPPELCODE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)

                            Text(syncManager.cleanSyncCode)
                                .font(.system(size: 28, weight: .heavy, design: .monospaced))
                                .foregroundColor(.blue)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Button(action: {
                                UIPasteboard.general.string = syncManager.cleanSyncCode
                                HapticManager.shared.light()
                                copiedToClipboard = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedToClipboard = false
                                }
                            }) {
                                Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                    .font(.headline)
                                    .foregroundColor(copiedToClipboard ? .green : .blue)
                                    .frame(width: 40, height: 40)
                                    .background(Color.blue.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)

                            ShareLink(
                                item: "Mijn GamesApp koppelcode is: \(syncManager.cleanSyncCode)\nVoer deze code in op iOS of Android bij Instellingen > Cloud Synchronisatie om samen live scores en statistieken te delen!",
                                subject: Text("GamesApp Koppelcode: \(syncManager.cleanSyncCode)")
                            ) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(width: 40, height: 40)
                                    .background(Color.blue.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Divider()

                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)

                        Text("Verbonden met Cloud Vault")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        if let date = syncManager.lastSyncDate {
                            Text("Laatste sync: \(date.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 6)

                // Handmatig synchroniseren knop
                Button(action: {
                    HapticManager.shared.medium()
                    syncManager.syncNow()
                }) {
                    HStack {
                        if syncManager.isSyncing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(syncManager.isSyncing ? "Bezig met synchroniseren..." : "Nu Synchroniseren")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            if !syncManager.lastSyncSummary.isEmpty {
                                Text(syncManager.lastSyncSummary)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(syncManager.isSyncing)

                // Automatische sync toggle
                Toggle(isOn: Binding(
                    get: { syncManager.isAutoSyncEnabled },
                    set: { syncManager.setAutoSyncEnabled($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Automatisch Synchroniseren")
                            .font(.body)
                        Text("Werkt live bij na elk potje en bij het openen van de app")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Ontkoppelen
                Button(role: .destructive, action: {
                    showDisconnectAlert = true
                }) {
                    HStack {
                        Image(systemName: "link.badge.plus")
                        Text("Toestel Ontkoppelen")
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - B. Niet Verbonden Weergave

    private var notConnectedSection: some View {
        Group {
            Section(header: Text("Optie 1: Nieuwe Koppelcode Aanmaken")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Wil je vanaf dit toestel starten? Maak een unieke code aan en deel die daarna met je andere apparaten.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: {
                        HapticManager.shared.medium()
                        syncManager.generateNewCode { result in
                            switch result {
                            case .success(let code):
                                print("Koppelcode aangemaakt: \(code)")
                            case .failure(let error):
                                testStatusMessage = "Fout: \(error.localizedDescription)"
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Genereer Nieuwe Koppelcode")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                .padding(.vertical, 6)
            }

            Section(header: Text("Optie 2: Koppelen met Bestaande Code")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Heb je al een code op je andere telefoon of tablet? Vul hem hieronder in om alle data samen te voegen.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        TextField("Bijv. SPEL-8429", text: $inputCode)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.characters)
                            .disableAutocorrection(true)
                            .padding(10)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(8)

                        Button("Koppelen") {
                            HapticManager.shared.medium()
                            syncManager.connectWithCode(inputCode) { _ in }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(inputCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || syncManager.isSyncing)
                    }

                    if syncManager.isSyncing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Data ophalen en samenvoegen...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func runConnectionTest() {
        HapticManager.shared.light()
        isTestingConnection = true
        testStatusMessage = nil

        syncManager.updateDatabaseUrl(customDatabaseUrl)
        syncManager.testConnection { success, message in
            isTestingConnection = false
            testStatusMessage = message
        }
    }

    // MARK: - Help Sheet
    private var firebaseHelpSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("In 2 minuten je eigen gratis Firebase instellen")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Wil je je eigen privé-database gebruiken in plaats van de standaard? Volg deze eenvoudige stappen:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 14) {
                        helpStep(
                            number: "1",
                            title: "Maak een gratis Firebase project",
                            desc: "Ga naar console.firebase.google.com, log in met een Google-account en klik op 'Project toevoegen' (naam bijv. 'MijnGamesApp')."
                        )

                        helpStep(
                            number: "2",
                            title: "Activeer Realtime Database",
                            desc: "Ga in het linkermenu naar 'Build' ➔ 'Realtime Database' en klik op 'Database maken'. Kies locatie 'België (europe-west1)'."
                        )

                        helpStep(
                            number: "3",
                            title: "Stel de Regels in",
                            desc: "Ga naar het tabblad 'Rules' (Regels) en zet .read en .write op true:\n{\n  \"rules\": {\n    \"vaults\": {\n      \"$vault\": {\n        \".read\": true,\n        \".write\": true\n      }\n    }\n  }\n}"
                        )

                        helpStep(
                            number: "4",
                            title: "Kopieer de URL",
                            desc: "Kopieer de getoonde URL (eindigt op .firebasedatabase.app) en plak hem hier in het veld 'Firebase Database URL'. Klaar!"
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Firebase Hulp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sluiten") {
                        showHelpSheet = false
                    }
                }
            }
        }
    }

    private func helpStep(number: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 26, height: 26)
                Text(number)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)

                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}
