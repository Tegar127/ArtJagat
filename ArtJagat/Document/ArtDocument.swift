// ArtDocument.swift
// ArtJagat — Core document model

import Foundation
import AppKit
import CoreImage
import Combine

/// A single open document in ArtJagat.
/// Owns the layer stack, history, and document metadata.
@MainActor
final class ArtDocument: ObservableObject, Identifiable {

    // MARK: - Identity
    let id: UUID
    @Published var displayName: String
    @Published var fileURL: URL?
    @Published var isDirty: Bool = false

    // MARK: - Canvas Geometry
    @Published var canvasSize: CGSize
    @Published var resolution: Double  // pixels per inch

    // MARK: - Color
    @Published var colorProfileName: String = "sRGB IEC61966-2.1"
    @Published var backgroundType: BackgroundType = .white

    // MARK: - Layers
    @Published var layers: [ArtLayer] = []
    @Published var activeLayerID: UUID?

    // MARK: - Selection
    @Published var selection: SelectionState = SelectionState()

    // MARK: - Viewport state (per-document)
    static let minZoomLevel: Double = 0.02
    static let maxZoomLevel: Double = 32.0

    @Published var zoomLevel: Double = 1.0
    @Published var panOffset: CGPoint = .zero
    var lastViewportSize: CGSize = CGSize(width: 1200, height: 800)

    // MARK: - Metadata
    let createdAt: Date
    @Published var modifiedAt: Date

    // MARK: - History
    let history: HistoryManager

    // MARK: - Version
    static let formatVersion: Int = 1

    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String = "Untitled",
        size: CGSize = CGSize(width: 1920, height: 1080),
        resolution: Double = 72,
        backgroundType: BackgroundType = .white
    ) {
        self.id = id
        self.displayName = name
        self.canvasSize = size
        self.resolution = resolution
        self.backgroundType = backgroundType
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.history = HistoryManager()

        // Create initial background layer
        let bgLayer = ArtLayer(
            name: "Background",
            type: .raster,
            size: size,
            backgroundColor: backgroundType.nsColor
        )
        self.layers = [bgLayer]
        self.activeLayerID = bgLayer.id
    }

    // MARK: - Layer Access

    var activeLayer: ArtLayer? {
        guard let id = activeLayerID else { return nil }
        return layers.first { $0.id == id }
    }

    var visibleLayers: [ArtLayer] {
        layers.filter { $0.isVisible }
    }

    // MARK: - Layer Operations

    func addLayer(name: String = "Layer", type: LayerType = .raster, above referenceID: UUID? = nil) -> ArtLayer {
        let layer = ArtLayer(name: name, type: type, size: canvasSize)
        let cmd = AddLayerCommand(document: self, layer: layer, aboveLayerID: referenceID ?? activeLayerID)
        history.execute(cmd)
        markDirty()
        return layer
    }

    func deleteLayer(id: UUID) {
        guard layers.count > 1 else { return }  // Protect against deleting the last layer
        guard let idx = layers.firstIndex(where: { $0.id == id }) else { return }
        let cmd = DeleteLayerCommand(document: self, layerID: id, originalIndex: idx)
        history.execute(cmd)
        markDirty()
    }

    func moveLayer(id: UUID, toIndex newIndex: Int) {
        guard let currentIndex = layers.firstIndex(where: { $0.id == id }) else { return }
        let cmd = MoveLayerCommand(document: self, layerID: id, fromIndex: currentIndex, toIndex: newIndex)
        history.execute(cmd)
        markDirty()
    }

    func duplicateLayer(id: UUID) {
        guard let original = layers.first(where: { $0.id == id }),
              let idx = layers.firstIndex(where: { $0.id == id }) else { return }
        let copy = original.duplicate()
        let cmd = AddLayerCommand(document: self, layer: copy, aboveLayerID: layers[idx].id)
        history.execute(cmd)
        markDirty()
    }

    func setActiveLayer(_ id: UUID) {
        activeLayerID = id
    }

    // MARK: - Dirty State

    func markDirty() {
        isDirty = true
        modifiedAt = Date()
    }

    func markClean() {
        isDirty = false
    }

    // MARK: - Viewport
    
    /// Zoom relative to a focal point in the viewport, keeping that document point stable under the cursor.
    func zoom(by factor: Double, around viewportPoint: CGPoint, in viewSize: CGSize) {
        guard viewSize.width > 0, viewSize.height > 0 else { return }
        let oldZoom = zoomLevel
        let newZoom = max(Self.minZoomLevel, min(Self.maxZoomLevel, oldZoom * factor))
        guard newZoom != oldZoom else { return }

        lastViewportSize = viewSize

        // Find the document point currently under viewportPoint
        let docPoint = viewportToDocument(viewportPoint, in: viewSize)

        // Calculate the new origin so that docPoint remains at viewportPoint
        let newOriginX = viewportPoint.x - docPoint.x * newZoom
        let newOriginY = viewportPoint.y - docPoint.y * newZoom

        // Derive new panOffset from newOrigin
        let newPanX = newOriginX - (viewSize.width - canvasSize.width * newZoom) / 2
        let newPanY = newOriginY - (viewSize.height - canvasSize.height * newZoom) / 2

        zoomLevel = newZoom
        panOffset = CGPoint(x: newPanX, y: newPanY)
    }

    func zoomIn(around point: CGPoint? = nil) {
        let viewSize = lastViewportSize.width > 0 ? lastViewportSize : CGSize(width: 1200, height: 800)
        let focal = point ?? CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        zoom(by: 1.25, around: focal, in: viewSize)
    }

    func zoomOut(around point: CGPoint? = nil) {
        let viewSize = lastViewportSize.width > 0 ? lastViewportSize : CGSize(width: 1200, height: 800)
        let focal = point ?? CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        zoom(by: 1.0 / 1.25, around: focal, in: viewSize)
    }

    func zoomToFit(viewSize: CGSize? = nil) {
        let size = (viewSize != nil && viewSize!.width > 0) ? viewSize! : (lastViewportSize.width > 0 ? lastViewportSize : CGSize(width: 1200, height: 800))
        lastViewportSize = size
        let scaleX = size.width / canvasSize.width
        let scaleY = size.height / canvasSize.height
        let targetZoom = min(scaleX, scaleY) * 0.92
        zoomLevel = max(Self.minZoomLevel, min(Self.maxZoomLevel, targetZoom))
        panOffset = .zero
    }

    func zoomToActualPixels() {
        zoomLevel = 1.0
        panOffset = .zero
    }

    func setZoom(_ zoom: Double) {
        zoomLevel = max(Self.minZoomLevel, min(Self.maxZoomLevel, zoom))
    }

    // MARK: - Coordinate Conversion

    /// Convert a point in viewport (SwiftUI) coordinates to document pixel coordinates.
    func viewportToDocument(_ point: CGPoint, in viewSize: CGSize) -> CGPoint {
        let origin = canvasOriginInViewport(viewSize: viewSize)
        return CGPoint(
            x: (point.x - origin.x) / zoomLevel,
            y: (point.y - origin.y) / zoomLevel
        )
    }

    /// Convert a point in document coordinates to viewport coordinates.
    func documentToViewport(_ point: CGPoint, in viewSize: CGSize) -> CGPoint {
        let origin = canvasOriginInViewport(viewSize: viewSize)
        return CGPoint(
            x: point.x * zoomLevel + origin.x,
            y: point.y * zoomLevel + origin.y
        )
    }

    /// The top-left corner of the canvas in viewport coordinates.
    func canvasOriginInViewport(viewSize: CGSize) -> CGPoint {
        let scaledW = canvasSize.width * zoomLevel
        let scaledH = canvasSize.height * zoomLevel
        return CGPoint(
            x: (viewSize.width - scaledW) / 2 + panOffset.x,
            y: (viewSize.height - scaledH) / 2 + panOffset.y
        )
    }

    // MARK: - Rendering

    /// Composite all visible layers into a single CGImage for display or export.
    func compositedImage(scale: CGFloat = 1.0) -> CGImage? {
        let width = Int(canvasSize.width * scale)
        let height = Int(canvasSize.height * scale)
        guard width > 0, height > 0 else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }

        // Fill transparent background
        ctx.clear(CGRect(x: 0, y: 0, width: width, height: height))

        // Draw layers bottom to top
        for layer in layers.reversed() {
            guard layer.isVisible else { continue }
            layer.draw(into: ctx, canvasSize: canvasSize, scale: scale)
        }

        return ctx.makeImage()
    }
}

// MARK: - Background Type

enum BackgroundType: String, CaseIterable, Codable {
    case white = "white"
    case black = "black"
    case transparent = "transparent"
    case custom = "custom"

    var nsColor: NSColor {
        switch self {
        case .white: return .white
        case .black: return .black
        case .transparent: return .clear
        case .custom: return .white
        }
    }

    var displayName: String {
        switch self {
        case .white: return "White"
        case .black: return "Black"
        case .transparent: return "Transparent"
        case .custom: return "Custom"
        }
    }
}
