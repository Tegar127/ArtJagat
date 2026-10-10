// WorkspacePreferences.swift
// ArtJagat — Persistent workspace preferences using UserDefaults

import Foundation

final class WorkspacePreferences {

    static let shared = WorkspacePreferences()
    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private enum Key {
        static let showGrid = "showGrid"
        static let showGuides = "showGuides"
        static let showRulers = "showRulers"
        static let defaultBrushSize = "defaultBrushSize"
        static let defaultBrushOpacity = "defaultBrushOpacity"
        static let defaultExportFormat = "defaultExportFormat"
        static let defaultJpegQuality = "defaultJpegQuality"
        static let leftPanelWidth = "leftPanelWidth"
        static let rightPanelWidth = "rightPanelWidth"
    }

    // MARK: - Properties
    var showGrid: Bool {
        get { defaults.bool(forKey: Key.showGrid) }
        set { defaults.set(newValue, forKey: Key.showGrid) }
    }

    var showGuides: Bool {
        get { defaults.object(forKey: Key.showGuides) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showGuides) }
    }

    var showRulers: Bool {
        get { defaults.bool(forKey: Key.showRulers) }
        set { defaults.set(newValue, forKey: Key.showRulers) }
    }

    var defaultBrushSize: Double {
        get { defaults.object(forKey: Key.defaultBrushSize) as? Double ?? 20.0 }
        set { defaults.set(newValue, forKey: Key.defaultBrushSize) }
    }

    var defaultBrushOpacity: Double {
        get { defaults.object(forKey: Key.defaultBrushOpacity) as? Double ?? 1.0 }
        set { defaults.set(newValue, forKey: Key.defaultBrushOpacity) }
    }

    var defaultExportFormat: ExportFormat {
        get {
            let raw = defaults.string(forKey: Key.defaultExportFormat) ?? "PNG"
            return ExportFormat(rawValue: raw) ?? .png
        }
        set { defaults.set(newValue.rawValue, forKey: Key.defaultExportFormat) }
    }

    var defaultJpegQuality: Double {
        get { defaults.object(forKey: Key.defaultJpegQuality) as? Double ?? 0.9 }
        set { defaults.set(newValue, forKey: Key.defaultJpegQuality) }
    }

    var rightPanelWidth: CGFloat {
        get { defaults.object(forKey: Key.rightPanelWidth) as? CGFloat ?? 260 }
        set { defaults.set(newValue, forKey: Key.rightPanelWidth) }
    }

    func save() {
        defaults.synchronize()
    }

    private init() {}
}
