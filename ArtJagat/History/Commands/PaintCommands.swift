// PaintCommands.swift
// ArtJagat — Raster paint and erase stroke commands for undo/redo history

import AppKit
import CoreGraphics

// MARK: - Paint Stroke Command

@MainActor
final class PaintStrokeCommand: HistoryCommand {
    let name: String = "Paint Stroke"
    weak var layer: ArtLayer?
    let points: [CGPoint]
    let color: NSColor
    let size: Double
    let opacity: Double
    let hardness: Double
    let snapshotBefore: CGImage?

    init(layer: ArtLayer, points: [CGPoint], color: NSColor, size: Double, opacity: Double, hardness: Double) {
        self.layer = layer
        self.points = points
        self.color = color
        self.size = size
        self.opacity = opacity
        self.hardness = hardness
        self.snapshotBefore = layer.cgImage
    }

    func execute() {
        layer?.paintStroke(points: points, color: color, size: size, opacity: opacity, hardness: hardness)
    }

    func undo() {
        if let snap = snapshotBefore {
            layer?.setCGImage(snap)
        }
    }
}

// MARK: - Erase Stroke Command

@MainActor
final class EraseStrokeCommand: HistoryCommand {
    let name: String = "Erase"
    weak var layer: ArtLayer?
    let points: [CGPoint]
    let size: Double
    let opacity: Double
    let snapshotBefore: CGImage?

    init(layer: ArtLayer, points: [CGPoint], size: Double, opacity: Double) {
        self.layer = layer
        self.points = points
        self.size = size
        self.opacity = opacity
        self.snapshotBefore = layer.cgImage
    }

    func execute() {
        layer?.eraseStroke(points: points, size: size, opacity: opacity)
    }

    func undo() {
        if let snap = snapshotBefore {
            layer?.setCGImage(snap)
        }
    }
}
