// AppState.swift
// ArtJagat — Global application state (tool selection, color, preferences)

import SwiftUI
import Combine

/// Central hub for application-level (not document-level) state.
@MainActor
final class AppState: ObservableObject {

    // MARK: - Tool Selection
    @Published var activeTool: ToolType = .move

    // MARK: - Color State
    @Published var foregroundColor: Color = .black
    @Published var backgroundColor: Color = .white

    // MARK: - Brush Settings
    @Published var brushSize: Double = 20.0
    @Published var brushOpacity: Double = 1.0
    @Published var brushHardness: Double = 0.8
    @Published var brushSpacing: Double = 0.1

    // MARK: - View Preferences
    @Published var showGrid: Bool = false
    @Published var showGuides: Bool = true
    @Published var showRulers: Bool = false
    @Published var showPanels: Bool = true

    // MARK: - Panel Visibility
    @Published var showLayersPanel: Bool = true
    @Published var showPropertiesPanel: Bool = true
    @Published var showColorPanel: Bool = true
    @Published var showHistoryPanel: Bool = false
    @Published var showBrushPanel: Bool = false
    @Published var showAdjustmentsPanel: Bool = false

    // MARK: - Status Bar
    @Published var statusMessage: String = "Ready"
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Double = 0.0

    // MARK: - Workspace Preferences
    @Published var defaultExportFormat: ExportFormat = .png
    @Published var defaultJpegQuality: Double = 0.9

    init() {
        loadPreferences()
    }

    func swapColors() {
        let temp = foregroundColor
        foregroundColor = backgroundColor
        backgroundColor = temp
    }

    func resetColors() {
        foregroundColor = .black
        backgroundColor = .white
    }

    func setStatus(_ message: String) {
        statusMessage = message
    }

    func startProcessing(_ message: String) {
        statusMessage = message
        isProcessing = true
        processingProgress = 0.0
    }

    func finishProcessing() {
        isProcessing = false
        processingProgress = 1.0
        statusMessage = "Ready"
    }

    private func loadPreferences() {
        let prefs = WorkspacePreferences.shared
        showGrid = prefs.showGrid
        showGuides = prefs.showGuides
        showRulers = prefs.showRulers
        brushSize = prefs.defaultBrushSize
        brushOpacity = prefs.defaultBrushOpacity
        defaultExportFormat = prefs.defaultExportFormat
        defaultJpegQuality = prefs.defaultJpegQuality
    }

    func savePreferences() {
        let prefs = WorkspacePreferences.shared
        prefs.showGrid = showGrid
        prefs.showGuides = showGuides
        prefs.showRulers = showRulers
        prefs.defaultBrushSize = brushSize
        prefs.defaultBrushOpacity = brushOpacity
        prefs.defaultExportFormat = defaultExportFormat
        prefs.defaultJpegQuality = defaultJpegQuality
        prefs.save()
    }
}
