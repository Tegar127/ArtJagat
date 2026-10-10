// DocumentTabBar.swift
// ArtJagat — Tab bar for open documents

import SwiftUI

struct DocumentTabBar: View {

    @EnvironmentObject var documentManager: DocumentManager

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 1) {
                    ForEach(documentManager.documents) { doc in
                        DocumentTab(document: doc)
                    }
                }
                .padding(.leading, 8)
            }

            Spacer()

            // New tab button
            Button {
                NotificationCenter.default.post(name: .newDocument, object: nil)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.07)),
            alignment: .bottom
        )
    }
}

struct DocumentTab: View {

    @EnvironmentObject var documentManager: DocumentManager
    @ObservedObject var document: ArtDocument
    @State private var isHovered = false

    var isActive: Bool {
        documentManager.activeDocumentID == document.id
    }

    var body: some View {
        HStack(spacing: 6) {
            // Dirty indicator
            if document.isDirty {
                Circle()
                    .fill(Color(hue: 0.6, saturation: 0.7, brightness: 0.9))
                    .frame(width: 6, height: 6)
            }

            Text(document.displayName)
                .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? .white : .white.opacity(0.55))
                .lineLimit(1)
                .truncationMode(.middle)

            // Close button
            Button {
                documentManager.closeDocument(document.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(isHovered ? 0.8 : 0.3))
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive
                    ? Color(red: 0.18, green: 0.18, blue: 0.2)
                    : (isHovered ? Color.white.opacity(0.05) : Color.clear))
        )
        .overlay(
            isActive ? RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1) : nil
        )
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            documentManager.setActiveDocument(document.id)
        }
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isActive)
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }
}
