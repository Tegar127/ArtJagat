// LayerCommands.swift
// ArtJagat — Layer manipulation commands for undo/redo history

import Foundation

// MARK: - Add Layer Command

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

// MARK: - Delete Layer Command

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

// MARK: - Move Layer Command

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

// MARK: - Rename Layer Command

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

// MARK: - Change Opacity Command

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
