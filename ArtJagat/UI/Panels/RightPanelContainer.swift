import SwiftUI

enum PanelTab: String, CaseIterable, Identifiable {
    case layers = "layers"
    case adjustments = "adjustments"
    case color = "color"
    case history = "history"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .layers: return "Layers"
        case .adjustments: return "Adjust"
        case .color: return "Color"
        case .history: return "History"
        }
    }

    var icon: String {
        switch self {
        case .layers: return "square.2.layers.3d"
        case .adjustments: return "slider.horizontal.3"
        case .color: return "paintpalette"
        case .history: return "clock.arrow.circlepath"
        }
    }
}

struct RightPanelContainer: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var appState: AppState

    @State private var selectedTab: PanelTab = .layers

    var body: some View {
        VStack(spacing: 0) {
            // Panel Tab Bar
            HStack(spacing: 2) {
                ForEach(PanelTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 11))
                            Text(tab.title)
                                .font(.system(size: 11, weight: selectedTab == tab ? .medium : .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.45))
                        .background(
                            selectedTab == tab
                                ? Color(red: 0.16, green: 0.16, blue: 0.17)
                                : Color.clear
                        )
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color(red: 0.12, green: 0.12, blue: 0.13))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.white.opacity(0.06)),
                alignment: .bottom
            )

            // Panel Content
            if let doc = documentManager.activeDocument {
                switch selectedTab {
                case .layers:
                    LayersPanelView(document: doc)
                case .adjustments:
                    AdjustmentsPanelView(document: doc)
                case .color:
                    ColorPanelView()
                case .history:
                    HistoryPanelView(document: doc)
                }
            } else {
                VStack {
                    Spacer()
                    Text("No Document")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.13, green: 0.13, blue: 0.14))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.white.opacity(0.06)),
            alignment: .leading
        )
    }
}
