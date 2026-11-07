//
//  GamesAppApp.swift
//  GamesApp
//
//  Created by Niels Pronk on 23/11/2024.
//

import SwiftUI

@main
struct GamesAppApp: App {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.selectedTheme.colorScheme)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        CloudSyncManager.shared.syncNowIfNeeded()
                    }
                }
        }
    }
}
