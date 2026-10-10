import SwiftUI
import CoreImage

struct AdjustmentsPanelView: View {
    @ObservedObject var document: ArtDocument
    @EnvironmentObject var appState: AppState

    @State private var brightness: Double = 0.0
    @State private var contrast: Double = 1.0
    @State private var saturation: Double = 1.0
    @State private var exposure: Double = 0.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Color Controls
                VStack(alignment: .leading, spacing: 10) {
                    Text("COLOR ADJUSTMENTS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .kerning(1)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Brightness")
                                .font(.system(size: 11))
                            Spacer()
                            Text(String(format: "%.2f", brightness))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Slider(value: $brightness, in: -0.5...0.5, step: 0.02)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Contrast")
                                .font(.system(size: 11))
                            Spacer()
                            Text(String(format: "%.2f", contrast))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Slider(value: $contrast, in: 0.2...2.0, step: 0.05)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Saturation")
                                .font(.system(size: 11))
                            Spacer()
                            Text(String(format: "%.2f", saturation))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Slider(value: $saturation, in: 0.0...2.0, step: 0.05)
                    }

                    Button("Apply Color Adjustments") {
                        applyColorControls()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(document.activeLayer == nil)
                }
                .padding(12)
                .background(Color(red: 0.14, green: 0.14, blue: 0.15))
                .cornerRadius(6)

                // Quick Filters
                VStack(alignment: .leading, spacing: 10) {
                    Text("QUICK FILTERS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .kerning(1)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        filterButton("Grayscale", filterName: "CIPhotoEffectNoir")
                        filterButton("Sepia Tone", filterName: "CISepiaTone", parameters: ["inputIntensity": 0.8])
                        filterButton("Invert", filterName: "CIColorInvert")
                        filterButton("Vignette", filterName: "CIVignette", parameters: ["inputIntensity": 1.5, "inputRadius": 2.0])
                    }
                }
                .padding(12)
                .background(Color(red: 0.14, green: 0.14, blue: 0.15))
                .cornerRadius(6)
            }
            .padding(12)
        }
    }

    private func filterButton(_ title: String, filterName: String, parameters: [String: Any] = [:]) -> some View {
        Button(title) {
            guard let layer = document.activeLayer else { return }
            appState.startProcessing("Applying \(title)...")
            layer.applyFilter(name: filterName, parameters: parameters)
            document.markDirty()
            appState.finishProcessing()
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(document.activeLayer == nil)
    }

    private func applyColorControls() {
        guard let layer = document.activeLayer else { return }
        appState.startProcessing("Applying adjustments...")
        layer.applyFilter(name: "CIColorControls", parameters: [
            kCIInputBrightnessKey: brightness,
            kCIInputContrastKey: contrast,
            kCIInputSaturationKey: saturation
        ])
        document.markDirty()
        // Reset controls to baseline
        brightness = 0.0
        contrast = 1.0
        saturation = 1.0
        appState.finishProcessing()
    }
}
