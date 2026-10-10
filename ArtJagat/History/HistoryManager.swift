// HistoryManager.swift
// ArtJagat — Command-based undo/redo history

import Foundation
import Combine

// MARK: - Command Protocol

protocol HistoryCommand {
    var name: String { get }
    func execute()
    func undo()
}

// MARK: - History Entry

struct HistoryEntry: Identifiable {
    let id: UUID
    let name: String
    let command: any HistoryCommand
    let timestamp: Date

    init(command: any HistoryCommand) {
        self.id = UUID()
        self.name = command.name
        self.command = command
        self.timestamp = Date()
    }
}

// MARK: - History Manager

@MainActor
final class HistoryManager: ObservableObject {

    private let maxEntries: Int = 50

    @Published private(set) var entries: [HistoryEntry] = []
    @Published private(set) var currentIndex: Int = -1

    var canUndo: Bool { currentIndex >= 0 }
    var canRedo: Bool { currentIndex < entries.count - 1 }

    var undoName: String? {
        guard canUndo else { return nil }
        return entries[currentIndex].name
    }

    var redoName: String? {
        guard canRedo else { return nil }
        return entries[currentIndex + 1].name
    }

    // MARK: - Execute

    func execute(_ command: any HistoryCommand) {
        // Remove all entries after current position (invalidate redo history)
        if currentIndex < entries.count - 1 {
            entries = Array(entries.prefix(currentIndex + 1))
        }

        command.execute()

        let entry = HistoryEntry(command: command)
        entries.append(entry)
        currentIndex = entries.count - 1

        // Enforce limit
        if entries.count > maxEntries {
            entries.removeFirst()
            currentIndex -= 1
        }
    }

    // MARK: - Undo

    func undo() {
        guard canUndo else { return }
        entries[currentIndex].command.undo()
        currentIndex -= 1
    }

    // MARK: - Redo

    func redo() {
        guard canRedo else { return }
        currentIndex += 1
        entries[currentIndex].command.execute()
    }

    // MARK: - Clear

    func clear() {
        entries = []
        currentIndex = -1
    }
}

// MARK: - Layer Commands

@MainActor
final class AddLayerCommand: HistoryCommand {
    let name: String = "Add Layer"
    weak var document: ArtDocument?
    let layer: ArtLayer
    let aboveLayerID: UUID?

    init(document: ArtDocument, layer: ArtLayer, aboveLayerID: UUID?) {
        self.document = document
        self.layer = layer
        self.aboveLayerID = aboveLayerID
    }

    func execute() {
        guard let doc = document else { return }
        if let refID = aboveLayerID,
           let idx = doc.layers.firstIndex(where: { $0.id == refID }) {
            doc.layers.insert(layer, at: idx)
        } else {
            doc.layers.insert(layer, at: 0)
        }
        doc.activeLayerID = layer.id
    }

    func undo() {
        guard let doc = document else { return }
        doc.layers.removeAll { $0.id == layer.id }
        if doc.activeLayerID == layer.id {
            doc.activeLayerID = doc.layers.first?.id
        }
    }
}

@MainActor
final class DeleteLayerCommand: HistoryCommand {
    let name: String = "Delete Layer"
    weak var document: ArtDocument?
    let layerID: UUID
    let originalIndex: Int
    var savedLayer: ArtLayer?

    init(document: ArtDocument, layerID: UUID, originalIndex: Int) {
        self.document = document
        self.layerID = layerID
        self.originalIndex = originalIndex
        self.savedLayer = document.layers.first { $0.id == layerID }
    }

    func execute() {
        guard let doc = document else { return }
        doc.layers.removeAll { $0.id == layerID }
        if doc.activeLayerID == layerID {
            doc.activeLayerID = doc.layers.first?.id
        }
    }

    func undo() {
        guard let doc = document, let layer = savedLayer else { return }
        let clampedIndex = min(originalIndex, doc.layers.count)
        doc.layers.insert(layer, at: clampedIndex)
        doc.activeLayerID = layer.id
    }
}

@MainActor
final class MoveLayerCommand: HistoryCommand {
    let name: String = "Move Layer"
    weak var document: ArtDocument?
    let layerID: UUID
    let fromIndex: Int
    let toIndex: Int

    init(document: ArtDocument, layerID: UUID, fromIndex: Int, toIndex: Int) {
        self.document = document
        self.layerID = layerID
        self.fromIndex = fromIndex
        self.toIndex = toIndex
    }

    func execute() {
        document?.layers.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
    }

    func undo() {
        document?.layers.move(fromOffsets: IndexSet(integer: toIndex > fromIndex ? toIndex : toIndex), toOffset: fromIndex > toIndex ? fromIndex + 1 : fromIndex)
    }
}

@MainActor
final class RenameLayerCommand: HistoryCommand {
    let name: String = "Rename Layer"
    weak var layer: ArtLayer?
    let oldName: String
    let newName: String

    init(layer: ArtLayer, oldName: String, newName: String) {
        self.layer = layer
        self.oldName = oldName
        self.newName = newName
    }

    func execute() { layer?.name = newName }
    func undo() { layer?.name = oldName }
}

@MainActor
final class ChangeOpacityCommand: HistoryCommand {
    let name: String = "Change Opacity"
    weak var layer: ArtLayer?
    let oldOpacity: Double
    let newOpacity: Double

    init(layer: ArtLayer, oldOpacity: Double, newOpacity: Double) {
        self.layer = layer
        self.oldOpacity = oldOpacity
        self.newOpacity = newOpacity
    }

    func execute() { layer?.opacity = newOpacity }
    func undo() { layer?.opacity = oldOpacity }
}

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

import SwiftUI

// MARK: - Array move helper

extension Array {
    mutating func move(fromOffsets: IndexSet, toOffset: Int) {
        var s = self
        var destination = toOffset
        var sourceOff = fromOffsets.sorted(by: >)
        for i in sourceOff {
            let item = s.remove(at: i)
            if i < destination { destination -= 1 }
            s.insert(item, at: destination)
        }
        self = s
    }
}
