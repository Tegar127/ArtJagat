// HistoryCommand.swift
// ArtJagat — Command protocol and entry abstraction for undo/redo history

import Foundation

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
