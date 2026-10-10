import SwiftUI

struct DocumentPreset: Identifiable {
    let id = UUID()
    let name: String
    let width: Double
    let height: Double
    let resolution: Double
}

struct NewDocumentConfig {
    var name: String = "Untitled"
    var width: Double = 1920
    var height: Double = 1080
    var resolution: Double = 72
    var background: BackgroundType = .white

    static let presets: [DocumentPreset] = [
        DocumentPreset(name: "Full HD (1080p)", width: 1920, height: 1080, resolution: 72),
        DocumentPreset(name: "4K UHD", width: 3840, height: 2160, resolution: 72),
        DocumentPreset(name: "Square (1080×1080)", width: 1080, height: 1080, resolution: 72),
        DocumentPreset(name: "Portrait Story (1080×1920)", width: 1080, height: 1920, resolution: 72),
        DocumentPreset(name: "A4 Print (300 DPI)", width: 2480, height: 3508, resolution: 300),
        DocumentPreset(name: "Icon (1024×1024)", width: 1024, height: 1024, resolution: 72)
    ]
}

struct NewDocumentSheet: View {
    @Binding var config: NewDocumentConfig
    let onCreate: (NewDocumentConfig) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPresetIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Document")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            HStack(alignment: .top, spacing: 24) {
                // Presets list
                VStack(alignment: .leading, spacing: 8) {
                    Text("PRESETS")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .kerning(1)

                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(Array(NewDocumentConfig.presets.enumerated()), id: \.element.id) { index, preset in
                                Button {
                                    selectedPresetIndex = index
                                    config.width = preset.width
                                    config.height = preset.height
                                    config.resolution = preset.resolution
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(preset.name)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(selectedPresetIndex == index ? .white : .white.opacity(0.8))
                                            Text("\(Int(preset.width)) × \(Int(preset.height)) px")
                                                .font(.system(size: 10))
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(selectedPresetIndex == index ? Color(red: 0.22, green: 0.47, blue: 0.85) : Color.white.opacity(0.04))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(width: 200, height: 230)
                }

                Divider()
                    .background(Color.white.opacity(0.08))

                // Custom dimensions form
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        TextField("Name", text: $config.name)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Width (px)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                            TextField("Width", value: $config.width, format: .number)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Height (px)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                            TextField("Height", value: $config.height, format: .number)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Resolution (PPI)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                            TextField("Resolution", value: $config.resolution, format: .number)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Background")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                            Picker("", selection: $config.background) {
                                ForEach(BackgroundType.allCases, id: \.self) { bg in
                                    Text(bg.displayName).tag(bg)
                                }
                            }
                            .labelsHidden()
                        }
                    }
                }
                .frame(width: 240)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    onCreate(config)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 530, height: 350)
        .background(Color(red: 0.14, green: 0.14, blue: 0.15))
    }
}
