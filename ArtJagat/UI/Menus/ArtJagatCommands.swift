import SwiftUI
import AppKit

struct ArtJagatCommands: Commands {

    @ObservedObject var documentManager: DocumentManager
    @ObservedObject var appState: AppState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Document…") {
                NotificationCenter.default.post(name: .newDocument, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Open…") {
                documentManager.openDocument()
            }
            .keyboardShortcut("o", modifiers: .command)

            Divider()

            Button("Close Document") {
                if let id = documentManager.activeDocumentID {
                    documentManager.closeDocument(id)
                }
            }
            .keyboardShortcut("w", modifiers: .command)
            .disabled(documentManager.activeDocument == nil)

            Button("Save") {
                if let id = documentManager.activeDocumentID {
                    documentManager.saveDocument(id)
                }
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(documentManager.activeDocument == nil)

            Button("Save As…") {
                if let id = documentManager.activeDocumentID {
                    documentManager.saveDocumentAs(id)
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(documentManager.activeDocument == nil)

            Divider()

            Button("Export…") {
                if let id = documentManager.activeDocumentID {
                    documentManager.exportDocument(
                        id,
                        format: appState.defaultExportFormat,
                        quality: appState.defaultJpegQuality
                    )
                }
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .disabled(documentManager.activeDocument == nil)
        }

        CommandGroup(replacing: .undoRedo) {
            Button(undoTitle) {
                documentManager.activeDocument?.history.undo()
            }
            .keyboardShortcut("z", modifiers: .command)
            .disabled(!(documentManager.activeDocument?.history.canUndo ?? false))

            Button(redoTitle) {
                documentManager.activeDocument?.history.redo()
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .disabled(!(documentManager.activeDocument?.history.canRedo ?? false))
        }

        CommandMenu("Layer") {
            Button("New Layer") {
                _ = documentManager.activeDocument?.addLayer()
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .disabled(documentManager.activeDocument == nil)

            Button("Duplicate Layer") {
                if let doc = documentManager.activeDocument, let activeID = doc.activeLayerID {
                    doc.duplicateLayer(id: activeID)
                }
            }
            .keyboardShortcut("j", modifiers: .command)
            .disabled(documentManager.activeDocument == nil)

            Button("Delete Layer") {
                if let doc = documentManager.activeDocument, let activeID = doc.activeLayerID {
                    doc.deleteLayer(id: activeID)
                }
            }
            .disabled((documentManager.activeDocument?.layers.count ?? 0) <= 1)
        }

        CommandMenu("View") {
            Button("Zoom In") {
                documentManager.activeDocument?.zoomIn()
            }
            .keyboardShortcut("+", modifiers: .command)
            .disabled(documentManager.activeDocument == nil)

            Button("Zoom Out") {
                documentManager.activeDocument?.zoomOut()
            }
            .keyboardShortcut("-", modifiers: .command)
            .disabled(documentManager.activeDocument == nil)

            Button("Fit to Screen") {
                documentManager.activeDocument?.zoomToFit()
            }
            .keyboardShortcut("0", modifiers: .command)
            .disabled(documentManager.activeDocument == nil)

            Button("Actual Pixels (100%)") {
                documentManager.activeDocument?.zoomToActualPixels()
            }
            .keyboardShortcut("1", modifiers: .command)
            .disabled(documentManager.activeDocument == nil)

            Divider()

            Toggle("Show Grid", isOn: $appState.showGrid)
                .keyboardShortcut("'", modifiers: .command)

            Toggle("Show Panels", isOn: $appState.showPanels)
                .keyboardShortcut(.tab, modifiers: [])
        }
    }

    private var undoTitle: String {
        if let name = documentManager.activeDocument?.history.undoName {
            return "Undo \(name)"
        }
        return "Undo"
    }

    private var redoTitle: String {
        if let name = documentManager.activeDocument?.history.redoName {
            return "Redo \(name)"
        }
        return "Redo"
    }
}
