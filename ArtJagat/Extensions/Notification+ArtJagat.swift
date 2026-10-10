// Notification+ArtJagat.swift
// ArtJagat — App-wide notification identifiers for menu actions & shortcuts

import Foundation

extension Notification.Name {
    static let newDocument = Notification.Name("ArtJagat.newDocument")
    static let openDocument = Notification.Name("ArtJagat.openDocument")
    static let saveDocument = Notification.Name("ArtJagat.saveDocument")
    static let saveDocumentAs = Notification.Name("ArtJagat.saveDocumentAs")
    static let exportDocument = Notification.Name("ArtJagat.exportDocument")
    static let undo = Notification.Name("ArtJagat.undo")
    static let redo = Notification.Name("ArtJagat.redo")
    static let newLayer = Notification.Name("ArtJagat.newLayer")
    static let deleteLayer = Notification.Name("ArtJagat.deleteLayer")
}
