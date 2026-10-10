// ArtJagatApp.swift
// ArtJagat — Professional macOS Image Editor
// Copyright © 2026 M Tegar Fitriano Jagat. All rights reserved.

import SwiftUI
import AppKit

@main
struct ArtJagatApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var documentManager = DocumentManager()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainWorkspaceView()
                .environmentObject(documentManager)
                .environmentObject(appState)
                .frame(minWidth: 1100, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            ArtJagatCommands(documentManager: documentManager, appState: appState)
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
