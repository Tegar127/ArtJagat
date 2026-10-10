import SwiftUI

struct HistoryPanelView: View {
    @ObservedObject var document: ArtDocument

    var body: some View {
        VStack(spacing: 0) {
            if document.history.entries.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.2))
                    Text("No actions yet")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(document.history.entries.enumerated()), id: \.element.id) { index, entry in
                            let isCurrent = index == document.history.currentIndex
                            let isPast = index <= document.history.currentIndex

                            HStack(spacing: 8) {
                                Image(systemName: isCurrent ? "arrowtriangle.right.fill" : (isPast ? "checkmark.circle" : "circle"))
                                    .font(.system(size: 9))
                                    .foregroundColor(isCurrent ? Color(red: 0.22, green: 0.47, blue: 0.85) : (isPast ? .white.opacity(0.6) : .white.opacity(0.2)))

                                Text(entry.name)
                                    .font(.system(size: 11, weight: isCurrent ? .semibold : .regular))
                                    .foregroundColor(isPast ? .white.opacity(0.85) : .white.opacity(0.3))

                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isCurrent ? Color(red: 0.22, green: 0.47, blue: 0.85).opacity(0.25) : Color.clear)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                jumpTo(index: index)
                            }
                        }
                    }
                    .padding(6)
                }
            }

            Divider()
                .background(Color.white.opacity(0.06))

            // Undo / Redo buttons at bottom
            HStack(spacing: 12) {
                Button {
                    document.history.undo()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(!document.history.canUndo)

                Spacer()

                Button {
                    document.history.redo()
                } label: {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(!document.history.canRedo)
            }
            .foregroundColor(.white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.13, green: 0.13, blue: 0.14))
        }
    }

    private func jumpTo(index: Int) {
        while document.history.currentIndex > index && document.history.canUndo {
            document.history.undo()
        }
        while document.history.currentIndex < index && document.history.canRedo {
            document.history.redo()
        }
    }
}
