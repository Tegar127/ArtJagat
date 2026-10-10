// ArtLayer.swift
// ArtJagat — Layer model with rendering

import Foundation
import AppKit
import CoreImage
import CoreGraphics
import Combine

// MARK: - Layer Type

enum LayerType: String, Codable, CaseIterable {
    case raster = "raster"
    case text = "text"
    case shape = "shape"
    case background = "background"

    var displayName: String {
        switch self {
        case .raster: return "Raster"
        case .text: return "Text"
        case .shape: return "Shape"
        case .background: return "Background"
        }
    }

    var iconName: String {
        switch self {
        case .raster: return "photo"
        case .text: return "textformat"
        case .shape: return "square.on.circle"
        case .background: return "rectangle.fill"
        }
    }
}

// MARK: - Blend Mode

enum LayerBlendMode: String, CaseIterable, Codable, Identifiable {
    case normal = "normal"
    case multiply = "multiply"
    case screen = "screen"
    case overlay = "overlay"
    case darken = "darken"
    case lighten = "lighten"
    case hardLight = "hardLight"
    case softLight = "softLight"
    case difference = "difference"
    case exclusion = "exclusion"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .multiply: return "Multiply"
        case .screen: return "Screen"
        case .overlay: return "Overlay"
        case .darken: return "Darken"
        case .lighten: return "Lighten"
        case .hardLight: return "Hard Light"
        case .softLight: return "Soft Light"
        case .difference: return "Difference"
        case .exclusion: return "Exclusion"
        }
    }
}

// MARK: - ArtLayer

@MainActor
final class ArtLayer: ObservableObject, Identifiable {

    // MARK: - Identity
    let id: UUID
    @Published var name: String
    let type: LayerType

    // MARK: - Visibility & Compositing
    @Published var isVisible: Bool = true
    @Published var opacity: Double = 1.0         // 0.0 – 1.0
    @Published var blendMode: LayerBlendMode = .normal
    @Published var isLocked: Bool = false

    // MARK: - Geometry
    @Published var position: CGPoint = .zero       // Layer's top-left in document coords
    @Published var layerSize: CGSize               // Dimensions of this layer's pixel buffer

    // MARK: - Pixel Content (raster layers)
    private var _cgImage: CGImage?
    private var _bitmapContext: CGContext?

    // MARK: - Text Content
    @Published var textContent: String = ""
    @Published var textFont: NSFont = .systemFont(ofSize: 24, weight: .regular)
    @Published var textColor: NSColor = .black
    @Published var textAlignment: NSTextAlignment = .left

    // MARK: - Shape Content
    @Published var shapeType: ShapeLayerType = .rectangle
    @Published var fillColor: NSColor = .blue
    @Published var strokeColor: NSColor = .clear
    @Published var strokeWidth: Double = 0
    @Published var shapeRect: CGRect = .zero

    // MARK: - Thumbnail
    @Published var thumbnail: NSImage?

    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String,
        type: LayerType,
        size: CGSize,
        backgroundColor: NSColor = .clear
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.layerSize = size

        // Initialize raster context
        if type == .raster || type == .background {
            self._bitmapContext = Self.makeContext(size: size)
            if backgroundColor != .clear {
                fill(color: backgroundColor)
            }
        }

        updateThumbnail()
    }

    // MARK: - Bitmap Context

    private static func makeContext(size: CGSize) -> CGContext? {
        let w = Int(size.width)
        let h = Int(size.height)
        guard w > 0, h > 0 else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        return CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
    }

    // MARK: - Image Access

    var cgImage: CGImage? {
        _cgImage ?? _bitmapContext?.makeImage()
    }

    func setCGImage(_ image: CGImage) {
        let w = Int(layerSize.width)
        let h = Int(layerSize.height)
        _bitmapContext = Self.makeContext(size: layerSize)
        _bitmapContext?.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        _cgImage = nil
        updateThumbnail()
    }

    // MARK: - Fill

    func fill(color: NSColor) {
        guard let ctx = _bitmapContext else { return }
        ctx.setFillColor(color.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: layerSize.width, height: layerSize.height))
    }

    // MARK: - Painting

    func paintStroke(points: [CGPoint], color: NSColor, size: Double, opacity: Double, hardness: Double) {
        guard let ctx = _bitmapContext, !points.isEmpty else { return }
        let diameter = size
        let radius = diameter / 2

        ctx.saveGState()
        ctx.setAlpha(opacity)
        ctx.setBlendMode(.normal)
        ctx.setFillColor(color.cgColor)

        for i in 0..<points.count {
            let pt = points[i]
            let rect = CGRect(x: pt.x - radius, y: pt.y - radius, width: diameter, height: diameter)
            if hardness >= 0.99 {
                ctx.fillEllipse(in: rect)
            } else {
                // Soft brush: use gradient
                let innerRadius = radius * hardness
                let locations: [CGFloat] = [0, 1]
                let components: [CGFloat] = [
                    color.redComponent, color.greenComponent, color.blueComponent, CGFloat(opacity),
                    color.redComponent, color.greenComponent, color.blueComponent, 0
                ]
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                if let gradient = CGGradient(colorSpace: colorSpace, colorComponents: components, locations: locations, count: 2) {
                    ctx.drawRadialGradient(
                        gradient,
                        startCenter: pt,
                        startRadius: innerRadius,
                        endCenter: pt,
                        endRadius: radius,
                        options: []
                    )
                }
            }
        }
        ctx.restoreGState()

        updateThumbnail()
    }

    func eraseStroke(points: [CGPoint], size: Double, opacity: Double) {
        guard let ctx = _bitmapContext, !points.isEmpty else { return }
        let radius = size / 2

        ctx.saveGState()
        ctx.setBlendMode(.clear)
        ctx.setAlpha(opacity)

        for pt in points {
            let rect = CGRect(x: pt.x - radius, y: pt.y - radius, width: size, height: size)
            ctx.fillEllipse(in: rect)
        }
        ctx.restoreGState()

        updateThumbnail()
    }

    // MARK: - Drawing into composite context

    func draw(into ctx: CGContext, canvasSize: CGSize, scale: CGFloat) {
        ctx.saveGState()

        let layerX = position.x * scale
        let layerY = (canvasSize.height - position.y - layerSize.height) * scale
        let layerW = layerSize.width * scale
        let layerH = layerSize.height * scale
        let rect = CGRect(x: layerX, y: layerY, width: layerW, height: layerH)

        ctx.setAlpha(CGFloat(opacity))
        ctx.setBlendMode(blendMode.cgBlendMode)

        switch type {
        case .raster, .background:
            if let img = cgImage {
                ctx.draw(img, in: rect)
            }

        case .text:
            drawText(into: ctx, rect: rect)

        case .shape:
            drawShape(into: ctx, rect: rect)
        }

        ctx.restoreGState()
    }

    private func drawText(into ctx: CGContext, rect: CGRect) {
        let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.current = nsCtx

        let attrs: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: textColor
        ]
        let str = NSAttributedString(string: textContent, attributes: attrs)
        str.draw(in: rect)
    }

    private func drawShape(into ctx: CGContext, rect: CGRect) {
        ctx.setFillColor(fillColor.cgColor)
        ctx.setStrokeColor(strokeColor.cgColor)
        ctx.setLineWidth(strokeWidth)

        switch shapeType {
        case .rectangle:
            ctx.fill(rect)
            if strokeWidth > 0 { ctx.stroke(rect) }
        case .ellipse:
            ctx.fillEllipse(in: rect)
            if strokeWidth > 0 { ctx.strokeEllipse(in: rect) }
        case .line:
            ctx.move(to: CGPoint(x: rect.minX, y: rect.midY))
            ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            ctx.strokePath()
        }
    }

    // MARK: - Thumbnail

    func updateThumbnail() {
        guard let img = cgImage else {
            if type == .text {
                thumbnail = NSImage(systemSymbolName: "textformat", accessibilityDescription: nil)
            } else if type == .shape {
                thumbnail = NSImage(systemSymbolName: "square.on.circle", accessibilityDescription: nil)
            }
            return
        }

        let thumbSize = CGSize(width: 48, height: 48)
        let nsImage = NSImage(cgImage: img, size: thumbSize)
        thumbnail = nsImage
    }

    // MARK: - Duplicate

    func duplicate() -> ArtLayer {
        let copy = ArtLayer(
            name: name + " copy",
            type: type,
            size: layerSize,
            backgroundColor: .clear
        )
        copy.isVisible = isVisible
        copy.opacity = opacity
        copy.blendMode = blendMode
        copy.position = position

        if let img = cgImage {
            copy.setCGImage(img)
        }
        copy.textContent = textContent
        copy.textFont = textFont
        copy.textColor = textColor
        copy.fillColor = fillColor
        copy.strokeColor = strokeColor
        copy.strokeWidth = strokeWidth
        copy.shapeRect = shapeRect
        copy.shapeType = shapeType

        return copy
    }

    // MARK: - Filter Processing

    func applyFilter(name: String, parameters: [String: Any] = [:]) {
        guard let inputCGImage = cgImage else { return }
        let ciImage = CIImage(cgImage: inputCGImage)
        guard let filter = CIFilter(name: name) else { return }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        for (k, v) in parameters {
            filter.setValue(v, forKey: k)
        }
        let context = CIContext(options: nil)
        guard let outputCI = filter.outputImage,
              let outputCG = context.createCGImage(outputCI, from: outputCI.extent) else { return }
        setCGImage(outputCG)
    }
}

// MARK: - Shape Layer Type

enum ShapeLayerType: String, Codable, CaseIterable {
    case rectangle = "rectangle"
    case ellipse = "ellipse"
    case line = "line"
}

// MARK: - Blend Mode Extension

extension LayerBlendMode {
    var cgBlendMode: CGBlendMode {
        switch self {
        case .normal: return .normal
        case .multiply: return .multiply
        case .screen: return .screen
        case .overlay: return .overlay
        case .darken: return .darken
        case .lighten: return .lighten
        case .hardLight: return .hardLight
        case .softLight: return .softLight
        case .difference: return .difference
        case .exclusion: return .exclusion
        }
    }
}
