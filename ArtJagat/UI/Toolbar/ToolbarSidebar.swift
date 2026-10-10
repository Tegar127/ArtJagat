// ToolbarSidebar.swift
// ArtJagat — Left vertical tool palette

import SwiftUI

struct ToolbarSidebar: View {

    @EnvironmentObject var appState: AppState

    // Tool groups for visual separation
    private let toolGroups: [[ToolType]] = [
        [.hand, .zoom],
        [.rectangularMarquee, .ellipticalMarquee, .lasso],
        [.move, .crop, .brush, .eraser],
        [.text, .rectangle, .ellipse, .line],
        [.eyedropper]
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(Array(toolGroups.enumerated()), id: \.offset) { idx, group in
                        VStack(spacing: 2) {
                            ForEach(group) { tool in
                                ToolButton(tool: tool)
                            }
                        }
                        .padding(.vertical, 4)

                        if idx < toolGroups.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 8)
                        }
                    }

                    // Color Swatches
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.horizontal, 8)

                    ColorSwatchWidget()
                        .padding(.vertical, 8)
                }
                .padding(.top, 8)
            }
        }
        .frame(width: 48)
        .background(Color(red: 0.13, green: 0.13, blue: 0.14))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.white.opacity(0.07)),
            alignment: .trailing
        )
    }
}

// MARK: - Tool Button

struct ToolButton: View {

    @EnvironmentObject var appState: AppState
    let tool: ToolType
    @State private var isHovered = false

    var isActive: Bool { appState.activeTool == tool }

    var body: some View {
        Button {
            appState.activeTool = tool
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tool.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isActive ? .white : .white.opacity(isHovered ? 0.8 : 0.45))
                    .frame(width: 32, height: 32)
            }
            .frame(width: 40, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive
                        ? Color(hue: 0.6, saturation: 0.7, brightness: 0.5).opacity(0.6)
                        : (isHovered ? Color.white.opacity(0.08) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .help(toolHelp(tool))
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.1), value: isActive)
        .animation(.easeOut(duration: 0.1), value: isHovered)
    }

    private func toolHelp(_ tool: ToolType) -> String {
        if let shortcut = tool.shortcut {
            return "\(tool.displayName) (\(shortcut))"
        }
        return tool.displayName
    }
}

// MARK: - Color Swatch Widget

struct ColorSwatchWidget: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background color
            RoundedRectangle(cornerRadius: 4)
                .fill(appState.backgroundColor)
                .frame(width: 22, height: 22)
                .offset(x: 12, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        .offset(x: 12, y: 10)
                )
                .onTapGesture {
                    // TODO: Open color picker for background
                }

            // Foreground color
            ColorPickerSwatch(color: $appState.foregroundColor, label: "Foreground")
                .frame(width: 22, height: 22)
                .offset(x: 4, y: 2)
        }
        .frame(width: 40, height: 36)
        .overlay(
            // Swap arrows
            Button {
                appState.swapColors()
            } label: {
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help("Swap Colors (X)")
            .offset(x: 12, y: -8),
            alignment: .topTrailing
        )
    }
}

struct ColorPickerSwatch: View {
    @Binding var color: Color
    let label: String

    var body: some View {
        ColorPicker(label, selection: $color, supportsOpacity: true)
            .labelsHidden()
    }
}
