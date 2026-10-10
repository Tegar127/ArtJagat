import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            toolsTab
                .tabItem {
                    Label("Tools", systemImage: "paintbrush")
                }

            exportTab
                .tabItem {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
        }
        .frame(width: 460, height: 280)
        .padding()
    }

    private var generalTab: some View {
        Form {
            Toggle("Show pixel grid at high zoom", isOn: $appState.showGrid)
            Toggle("Show document guides", isOn: $appState.showGuides)
            Toggle("Show canvas rulers", isOn: $appState.showRulers)
        }
        .padding()
    }

    private var toolsTab: some View {
        Form {
            Slider(value: $appState.brushSize, in: 1...500, step: 1) {
                Text("Default Brush Size: \(Int(appState.brushSize)) px")
            }
            Slider(value: $appState.brushOpacity, in: 0.05...1.0, step: 0.05) {
                Text("Default Opacity: \(Int(appState.brushOpacity * 100))%")
            }
            Slider(value: $appState.brushHardness, in: 0.0...1.0, step: 0.05) {
                Text("Brush Hardness: \(Int(appState.brushHardness * 100))%")
            }
        }
        .padding()
    }

    private var exportTab: some View {
        Form {
            Picker("Default Format", selection: $appState.defaultExportFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }

            if appState.defaultExportFormat == .jpeg {
                Slider(value: $appState.defaultJpegQuality, in: 0.1...1.0, step: 0.05) {
                    Text("JPEG Quality: \(Int(appState.defaultJpegQuality * 100))%")
                }
            }
        }
        .padding()
    }
}
