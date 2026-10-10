// ImageExporter.swift
// ArtJagat — Export CGImages to file

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum ExportError: LocalizedError {
    case failedToCreateDestination
    case failedToFinalize
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .failedToCreateDestination: return "Could not create export destination."
        case .failedToFinalize: return "Could not write image data to file."
        case .unsupportedFormat: return "Unsupported export format."
        }
    }
}

struct ImageExporter {

    static func export(cgImage: CGImage, to url: URL, format: ExportFormat, quality: Double = 0.9) throws {
        let uti: CFString
        switch format {
        case .png:  uti = UTType.png.identifier as CFString
        case .jpeg: uti = UTType.jpeg.identifier as CFString
        case .tiff: uti = UTType.tiff.identifier as CFString
        }

        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, uti, 1, nil) else {
            throw ExportError.failedToCreateDestination
        }

        var options: [CFString: Any] = [:]
        if format == .jpeg {
            options[kCGImageDestinationLossyCompressionQuality] = quality
        }

        CGImageDestinationAddImage(dest, cgImage, options as CFDictionary)

        guard CGImageDestinationFinalize(dest) else {
            throw ExportError.failedToFinalize
        }
    }
}
