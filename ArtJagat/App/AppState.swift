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

// MARK: - Tool Types
enum ToolType: String, CaseIterable, Identifiable {
    // Navigation
    case hand = "hand"
    case zoom = "zoom"
    // Selection
    case rectangularMarquee = "rectangular_marquee"
    case ellipticalMarquee = "elliptical_marquee"
    case lasso = "lasso"
    // Editing
    case move = "move"
    case crop = "crop"
    case brush = "brush"
    case eraser = "eraser"
    // Creation
    case text = "text"
    case rectangle = "rectangle"
    case ellipse = "ellipse"
    case line = "line"
    // Color
    case eyedropper = "eyedropper"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hand: return "Hand"
        case .zoom: return "Zoom"
        case .rectangularMarquee: return "Rectangular Marquee"
        case .ellipticalMarquee: return "Elliptical Marquee"
        case .lasso: return "Lasso"
        case .move: return "Move"
        case .crop: return "Crop"
        case .brush: return "Brush"
        case .eraser: return "Eraser"
        case .text: return "Text"
        case .rectangle: return "Rectangle"
        case .ellipse: return "Ellipse"
        case .line: return "Line"
        case .eyedropper: return "Eyedropper"
        }
    }

    var iconName: String {
        switch self {
        case .hand: return "hand.raised.fill"
        case .zoom: return "magnifyingglass"
        case .rectangularMarquee: return "rectangle.dashed"
        case .ellipticalMarquee: return "oval.fill"
        case .lasso: return "lasso"
        case .move: return "arrow.up.and.down.and.arrow.left.and.right"
        case .crop: return "crop"
        case .brush: return "paintbrush.pointed.fill"
        case .eraser: return "eraser.fill"
        case .text: return "t.square.fill"
        case .rectangle: return "rectangle.fill"
        case .ellipse: return "circle.fill"
        case .line: return "line.diagonal"
        case .eyedropper: return "eyedropper.halffull"
        }
    }

    var shortcut: String? {
        switch self {
        case .hand: return "H"
        case .zoom: return "Z"
        case .rectangularMarquee: return "M"
        case .ellipticalMarquee: return nil
        case .lasso: return "L"
        case .move: return "V"
        case .crop: return "C"
        case .brush: return "B"
        case .eraser: return "E"
        case .text: return "T"
        case .rectangle: return "U"
        case .ellipse: return nil
        case .line: return nil
        case .eyedropper: return "I"
        }
    }
}

// MARK: - Export Format
enum ExportFormat: String, CaseIterable, Identifiable {
    case png = "PNG"
    case jpeg = "JPEG"
    case tiff = "TIFF"

    var id: String { rawValue }
    var fileExtension: String { rawValue.lowercased() }
}
