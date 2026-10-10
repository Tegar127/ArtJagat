import SwiftUI
import AppKit

struct LayersPanelView: View {
    @ObservedObject var document: ArtDocument
    @State private var editingLayerID: UUID?
    @State private var editingName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header: Opacity & Blend Mode
            if let active = document.activeLayer {
                VStack(spacing: 8) {
                    HStack {
                        Text("Blend")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))

                        Spacer()

                        Picker("", selection: Binding(
                            get: { active.blendMode },
                            set: { active.blendMode = $0; document.markDirty() }
                        )) {
                            ForEach(LayerBlendMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 110)
                    }

                    HStack {
                        Text("Opacity")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))

                        Slider(value: Binding(
                            get: { active.opacity },
                            set: { active.opacity = $0; document.markDirty() }
                        ), in: 0...1)

                        Text("\(Int(active.opacity * 100))%")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 36, alignment: .trailing)
                    }
                }
                .padding(10)
                .background(Color(red: 0.14, green: 0.14, blue: 0.15))

                Divider()
                    .background(Color.white.opacity(0.06))
            }

            // Layer list
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(document.layers) { layer in
                        LayerRow(
                            layer: layer,
                            isActive: document.activeLayerID == layer.id,
                            onSelect: {
                                document.setActiveLayer(layer.id)
                            },
                            onToggleVisibility: {
                                layer.isVisible.toggle()
                                document.markDirty()
                            },
                            onToggleLock: {
                                layer.isLocked.toggle()
                                document.markDirty()
                            }
                        )
                    }
                }
                .padding(.vertical, 4)
            }

            Divider()
                .background(Color.white.opacity(0.06))

            // Footer controls: Add, Duplicate, Delete, Move
            HStack(spacing: 8) {
                Button {
                    _ = document.addLayer()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("New Layer")

                Button {
                    if let id = document.activeLayerID {
                        document.duplicateLayer(id: id)
                    }
                } label: {
                    Image(systemName: "plus.square.on.square")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Duplicate Layer")

                Spacer()

                Button {
                    if let id = document.activeLayerID {
                        document.deleteLayer(id: id)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .disabled(document.layers.count <= 1)
                .help("Delete Layer")
            }
            .foregroundColor(.white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.13, green: 0.13, blue: 0.14))
        }
    }
}

struct LayerRow: View {
    @ObservedObject var layer: ArtLayer
    let isActive: Bool
    let onSelect: () -> Void
    let onToggleVisibility: () -> Void
    let onToggleLock: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            // Visibility eye
            Button(action: onToggleVisibility) {
                Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash")
                    .font(.system(size: 11))
                    .foregroundColor(layer.isVisible ? .white.opacity(0.7) : .white.opacity(0.2))
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)

            // Lock icon
            Button(action: onToggleLock) {
                Image(systemName: layer.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 10))
                    .foregroundColor(layer.isLocked ? Color.orange.opacity(0.8) : .white.opacity(0.15))
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)

            // Thumbnail / Icon
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 24, height: 24)

                if let thumb = layer.thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                } else {
                    Image(systemName: layer.type.iconName)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Layer Name
            Text(layer.name)
                .font(.system(size: 12, weight: isActive ? .medium : .regular))
                .foregroundColor(isActive ? .white : .white.opacity(0.75))
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 8)
        .frame(height: 32)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isActive
                    ? Color(red: 0.22, green: 0.47, blue: 0.85).opacity(0.35)
                    : (isHovered ? Color.white.opacity(0.04) : Color.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
    }
}
