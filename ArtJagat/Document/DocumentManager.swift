// DocumentManager.swift
// ArtJagat — Manages the collection of open documents

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import Combine

@MainActor
final class DocumentManager: ObservableObject {

    @Published var documents: [ArtDocument] = []
    @Published var activeDocumentID: UUID?

    var activeDocument: ArtDocument? {
        guard let id = activeDocumentID else { return nil }
        return documents.first { $0.id == id }
    }

    // MARK: - Document Creation

    func newDocument(
        name: String = "Untitled",
        size: CGSize = CGSize(width: 1920, height: 1080),
        resolution: Double = 72,
        background: BackgroundType = .white
    ) -> ArtDocument {
        let doc = ArtDocument(name: name, size: size, resolution: resolution, backgroundType: background)
        documents.append(doc)
        activeDocumentID = doc.id
        return doc
    }

    // MARK: - Open Document

    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [
            .png, .jpeg, .tiff, .heic,
            UTType(filenameExtension: "artjagat") ?? .data
        ]

        guard panel.runModal() == .OK, let url = panel.url else { return }
        openDocument(at: url)
    }

    func openDocument(at url: URL) {
        // Check if already open
        if let existing = documents.first(where: { $0.fileURL == url }) {
            activeDocumentID = existing.id
            return
        }

        // Check if this is a native .artjagat file
        if url.pathExtension.lowercased() == "artjagat" {
            openNativeDocument(at: url)
            return
        }

        // Otherwise treat as image import
        openImageAsDocument(at: url)
    }

    private func openImageAsDocument(at url: URL) {
        guard let nsImage = NSImage(contentsOf: url),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            showError("Could not open image at \(url.lastPathComponent)")
            return
        }

        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let doc = ArtDocument(
            name: url.deletingPathExtension().lastPathComponent,
            size: size,
            resolution: 72,
            backgroundType: .transparent
        )
        doc.fileURL = url

        // Replace the default background layer with the imported image
        if let bgLayer = doc.layers.first {
            bgLayer.setCGImage(cgImage)
            bgLayer.name = url.deletingPathExtension().lastPathComponent
        }

        doc.markClean()
        documents.append(doc)
        activeDocumentID = doc.id
    }

    private func openNativeDocument(at url: URL) {
        // Placeholder: full implementation in Milestone 6
        showError("Native .artjagat format loading will be available in the next milestone.")
    }

    // MARK: - Close Document

    func closeDocument(_ id: UUID) {
        guard let doc = documents.first(where: { $0.id == id }) else { return }

        if doc.isDirty {
            let alert = NSAlert()
            alert.messageText = "Save changes to \"\(doc.displayName)\"?"
            alert.informativeText = "Your changes will be lost if you don't save them."
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn:
                saveDocument(id)
            case .alertSecondButtonReturn:
                break  // Close without saving
            default:
                return  // Cancel
            }
        }

        documents.removeAll { $0.id == id }
        if activeDocumentID == id {
            activeDocumentID = documents.last?.id
        }
    }

    // MARK: - Save

    func saveDocument(_ id: UUID) {
        guard let doc = documents.first(where: { $0.id == id }) else { return }

        if let url = doc.fileURL, url.pathExtension.lowercased() == "artjagat" {
            saveNativeDocument(doc, to: url)
        } else {
            saveDocumentAs(id)
        }
    }

    func saveDocumentAs(_ id: UUID) {
        guard let doc = documents.first(where: { $0.id == id }) else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "artjagat") ?? .data]
        panel.nameFieldStringValue = doc.displayName + ".artjagat"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        doc.fileURL = url
        doc.displayName = url.deletingPathExtension().lastPathComponent
        saveNativeDocument(doc, to: url)
    }

    private func saveNativeDocument(_ doc: ArtDocument, to url: URL) {
        // Placeholder: full serialization in Milestone 6
        doc.markClean()
    }

    // MARK: - Export

    func exportDocument(_ id: UUID, format: ExportFormat = .png, quality: Double = 0.9) {
        guard let doc = documents.first(where: { $0.id == id }) else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = doc.displayName + "." + format.fileExtension

        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard let image = doc.compositedImage() else {
            showError("Failed to render document for export.")
            return
        }

        do {
            try ImageExporter.export(cgImage: image, to: url, format: format, quality: quality)
        } catch {
            showError("Export failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Active Document Helpers

    func setActiveDocument(_ id: UUID) {
        guard documents.contains(where: { $0.id == id }) else { return }
        activeDocumentID = id
    }

    // MARK: - Error

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}
