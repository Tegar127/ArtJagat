// HistoryManager.swift
// ArtJagat — Command-based undo/redo history manager

import Foundation
import Combine

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
