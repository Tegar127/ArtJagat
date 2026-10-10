// RenderEngine.swift
// ArtJagat — Shared rendering resources and Core Image pipeline

import CoreImage
import CoreGraphics

/// Shared graphics and image rendering pipeline
enum RenderEngine {
    /// Shared GPU-accelerated CIContext for filter operations and adjustments
    static let sharedCIContext: CIContext = CIContext(options: [
        .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
        .useSoftwareRenderer: false
    ])
}
