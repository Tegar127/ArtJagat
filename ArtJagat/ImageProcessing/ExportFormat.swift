// ExportFormat.swift
// ArtJagat — Image export formats supported by ImageExporter

import Foundation

/// Supported image export formats
enum ExportFormat: String, CaseIterable, Identifiable {
    case png = "PNG"
    case jpeg = "JPEG"
    case tiff = "TIFF"

    var id: String { rawValue }
    var fileExtension: String { rawValue.lowercased() }
}
