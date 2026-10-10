import SwiftUI

struct ColorPanelView: View {
    @EnvironmentObject var appState: AppState

    private let defaultSwatches: [Color] = [
        .black, .white, .gray,
        .red, .orange, .yellow,
        .green, .mint, .teal,
        .cyan, .blue, .indigo,
        .purple, .pink, .brown
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Active Swatches (Foreground / Background)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Foreground")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                        ColorPicker("", selection: $appState.foregroundColor)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Background")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                        ColorPicker("", selection: $appState.backgroundColor)
                            .labelsHidden()
                    }

                    Spacer()

                    Button {
                        appState.swapColors()
                    } label: {
                        Image(systemName: "arrow.2.squarepath")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .help("Swap Colors (X)")

                    Button {
                        appState.resetColors()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .help("Reset to Default (D)")
                }
                .padding(12)
                .background(Color(red: 0.14, green: 0.14, blue: 0.15))
                .cornerRadius(6)

                // Swatches Grid
                VStack(alignment: .leading, spacing: 8) {
                    Text("PALETTE SWATCHES")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .kerning(1)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                        ForEach(Array(defaultSwatches.enumerated()), id: \.offset) { _, color in
                            Button {
                                appState.foregroundColor = color
                            } label: {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(color)
                                    .frame(height: 28)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(12)
                .background(Color(red: 0.14, green: 0.14, blue: 0.15))
                .cornerRadius(6)
            }
            .padding(12)
        }
    }
}
