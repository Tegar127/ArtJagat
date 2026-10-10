// MainWorkspaceView.swift
// ArtJagat — Root workspace layout

import SwiftUI
import AppKit

struct MainWorkspaceView: View {

    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var appState: AppState

    @State private var rightPanelWidth: CGFloat = 260
    @State private var showNewDocumentSheet = false
    @State private var newDocConfig = NewDocumentConfig()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Color(NSColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1.0))
                    .ignoresSafeArea()

                if documentManager.documents.isEmpty {
                    WelcomeView(showNewDocument: $showNewDocumentSheet)
                } else {
                    mainEditorLayout(geo: geo)
                }
            }
        }
        .sheet(isPresented: $showNewDocumentSheet) {
            NewDocumentSheet(config: $newDocConfig) { config in
                let _ = documentManager.newDocument(
                    name: config.name,
                    size: CGSize(width: config.width, height: config.height),
                    resolution: config.resolution,
                    background: config.background
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newDocument)) { _ in
            showNewDocumentSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDocument)) { _ in
            documentManager.openDocument()
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveDocument)) { _ in
            if let id = documentManager.activeDocumentID {
                documentManager.saveDocument(id)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveDocumentAs)) { _ in
            if let id = documentManager.activeDocumentID {
                documentManager.saveDocumentAs(id)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportDocument)) { _ in
            if let id = documentManager.activeDocumentID {
                documentManager.exportDocument(id, format: appState.defaultExportFormat, quality: appState.defaultJpegQuality)
            }
        }
    }

    @ViewBuilder
    private func mainEditorLayout(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Document Tab Bar
            DocumentTabBar()
                .frame(height: 36)

            HSplitView {
                // Left Toolbar
                ToolbarSidebar()
                    .frame(width: 48)
                    .frame(maxHeight: .infinity)

                // Central Canvas Area
                CanvasWorkspace()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Right Panels
                if appState.showPanels {
                    RightPanelContainer()
                        .frame(width: rightPanelWidth)
                        .frame(maxHeight: .infinity)
                }
            }

            // Status Bar
            StatusBar()
                .frame(height: 24)
        }
    }
}
