import SwiftUI

struct WelcomeView: View {
    @Binding var showNewDocument: Bool
    @EnvironmentObject var documentManager: DocumentManager

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            // Product Identity
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.16, green: 0.16, blue: 0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .frame(width: 80, height: 80)

                    Text("AJ")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.85, green: 0.87, blue: 0.90))
                }

                VStack(spacing: 4) {
                    Text("ArtJagat")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Professional Image Editing Studio")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Primary Actions
            HStack(spacing: 14) {
                WelcomeActionButton(
                    icon: "plus.rectangle.on.rectangle",
                    title: "New Document",
                    subtitle: "Create empty canvas"
                ) {
                    showNewDocument = true
                }

                WelcomeActionButton(
                    icon: "photo.badge.plus",
                    title: "Open Image",
                    subtitle: "Load PNG, JPEG, TIFF"
                ) {
                    documentManager.openDocument()
                }
            }

            // Recents placeholder
            VStack(alignment: .leading, spacing: 8) {
                Text("RECENT")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
                    .kerning(1.2)

                Text("No recent documents")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.35))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
            .frame(width: 380)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WelcomeActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isHovered ? .white : Color(red: 0.22, green: 0.47, blue: 0.85))

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            .frame(width: 170, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(isHovered ? 0.08 : 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.white.opacity(isHovered ? 0.16 : 0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
