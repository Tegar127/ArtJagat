import SwiftUI

struct StatusBar: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            // Status or progress
            if appState.isProcessing {
                ProgressView()
                    .controlSize(.small)
                Text(appState.statusMessage)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
            } else {
                Text(appState.statusMessage)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            if let doc = documentManager.activeDocument {
                // Document Info
                Text("\(Int(doc.canvasSize.width)) × \(Int(doc.canvasSize.height)) px")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))

                Text("•")
                    .foregroundColor(.white.opacity(0.2))

                Text("\(Int(doc.resolution)) PPI")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))

                Text("•")
                    .foregroundColor(.white.opacity(0.2))

                // Zoom Controls
                HStack(spacing: 4) {
                    Button {
                        doc.zoomOut()
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)

                    Text("\(Int(doc.zoomLevel * 100))%")
                        .font(.system(size: 11, design: .monospaced))
                        .frame(width: 44)

                    Button {
                        doc.zoomIn()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)

                    Button("Fit") {
                        // Will fit to canvas
                        doc.setZoom(1.0)
                    }
                    .font(.system(size: 10))
                    .buttonStyle(.plain)
                    .padding(.horizontal, 4)
                }
                .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 24)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.06)),
            alignment: .top
        )
    }
}
