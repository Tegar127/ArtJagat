import SwiftUI
import AppKit

struct CanvasWorkspace: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var appState: AppState

    @State private var currentStrokePoints: [CGPoint] = []
    @State private var strokeSnapshot: CGImage?
    @State private var marqueeStart: CGPoint?
    @State private var marqueeCurrent: CGPoint?
    @State private var initialLayerPosition: CGPoint = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Workspace background
                Color(red: 0.12, green: 0.12, blue: 0.13)
                    .ignoresSafeArea()

                if let doc = documentManager.activeDocument {
                    canvasContainer(doc: doc, viewportSize: geo.size)
                } else {
                    Text("No Document")
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
    }

    @ViewBuilder
    private func canvasContainer(doc: ArtDocument, viewportSize: CGSize) -> some View {
        let origin = doc.canvasOriginInViewport(viewSize: viewportSize)
        let scaledW = doc.canvasSize.width * doc.zoomLevel
        let scaledH = doc.canvasSize.height * doc.zoomLevel

        ZStack(alignment: .topLeading) {
            // Interactive canvas surface
            ZStack {
                // Checkerboard pattern for transparency
                CheckerboardBackground()
                    .frame(width: scaledW, height: scaledH)

                // Rendered document composite
                if let composite = doc.compositedImage() {
                    Image(decorative: composite, scale: 1.0)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: scaledW, height: scaledH)
                }

                // Pixel Grid overlay at high zoom
                if appState.showGrid && doc.zoomLevel >= 4.0 {
                    PixelGridView(
                        canvasSize: doc.canvasSize,
                        zoomLevel: doc.zoomLevel
                    )
                    .frame(width: scaledW, height: scaledH)
                }

                // Selection Marquee overlay
                if !doc.selection.isEmpty, let rect = doc.selection.boundingRect {
                    SelectionMarqueeView(
                        rect: CGRect(
                            x: rect.origin.x * doc.zoomLevel,
                            y: rect.origin.y * doc.zoomLevel,
                            width: rect.width * doc.zoomLevel,
                            height: rect.height * doc.zoomLevel
                        )
                    )
                }

                // Live Marquee during drag
                if let start = marqueeStart, let current = marqueeCurrent {
                    let rect = CGRect(
                        x: min(start.x, current.x) * doc.zoomLevel,
                        y: min(start.y, current.y) * doc.zoomLevel,
                        width: abs(current.x - start.x) * doc.zoomLevel,
                        height: abs(current.y - start.y) * doc.zoomLevel
                    )
                    SelectionMarqueeView(rect: rect)
                }
            }
            .frame(width: scaledW, height: scaledH)
            .shadow(color: Color.black.opacity(0.4), radius: 10, y: 4)
            .position(
                x: origin.x + scaledW / 2,
                y: origin.y + scaledH / 2
            )
            .gesture(canvasDragGesture(doc: doc, viewportSize: viewportSize))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private func canvasDragGesture(doc: ArtDocument, viewportSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let docPoint = doc.viewportToDocument(value.location, in: viewportSize)

                switch appState.activeTool {
                case .hand:
                    doc.panOffset.x += value.translation.width * 0.1
                    doc.panOffset.y += value.translation.height * 0.1

                case .brush:
                    guard let active = doc.activeLayer, !active.isLocked else { return }
                    if currentStrokePoints.isEmpty {
                        strokeSnapshot = active.cgImage
                    }
                    currentStrokePoints.append(docPoint)
                    let nsColor = NSColor(appState.foregroundColor)
                    active.paintStroke(
                        points: [docPoint],
                        color: nsColor,
                        size: appState.brushSize,
                        opacity: appState.brushOpacity,
                        hardness: appState.brushHardness
                    )
                    doc.markDirty()

                case .eraser:
                    guard let active = doc.activeLayer, !active.isLocked else { return }
                    if currentStrokePoints.isEmpty {
                        strokeSnapshot = active.cgImage
                    }
                    currentStrokePoints.append(docPoint)
                    active.eraseStroke(
                        points: [docPoint],
                        size: appState.brushSize,
                        opacity: appState.brushOpacity
                    )
                    doc.markDirty()

                case .move:
                    guard let active = doc.activeLayer, !active.isLocked else { return }
                    if currentStrokePoints.isEmpty {
                        initialLayerPosition = active.position
                        currentStrokePoints.append(docPoint)
                    }
                    let dx = value.translation.width / doc.zoomLevel
                    let dy = value.translation.height / doc.zoomLevel
                    active.position = CGPoint(x: initialLayerPosition.x + dx, y: initialLayerPosition.y + dy)
                    doc.markDirty()

                case .rectangularMarquee:
                    if marqueeStart == nil {
                        marqueeStart = docPoint
                    }
                    marqueeCurrent = docPoint

                case .eyedropper:
                    sampleColor(at: docPoint, in: doc)

                default:
                    break
                }
            }
            .onEnded { value in
                switch appState.activeTool {
                case .brush:
                    if let active = doc.activeLayer, !currentStrokePoints.isEmpty {
                        let nsColor = NSColor(appState.foregroundColor)
                        let cmd = PaintStrokeCommand(
                            layer: active,
                            points: currentStrokePoints,
                            color: nsColor,
                            size: appState.brushSize,
                            opacity: appState.brushOpacity,
                            hardness: appState.brushHardness
                        )
                        doc.history.execute(cmd)
                    }
                    currentStrokePoints.removeAll()
                    strokeSnapshot = nil

                case .eraser:
                    if let active = doc.activeLayer, !currentStrokePoints.isEmpty {
                        let cmd = EraseStrokeCommand(
                            layer: active,
                            points: currentStrokePoints,
                            size: appState.brushSize,
                            opacity: appState.brushOpacity
                        )
                        doc.history.execute(cmd)
                    }
                    currentStrokePoints.removeAll()
                    strokeSnapshot = nil

                case .move:
                    currentStrokePoints.removeAll()

                case .rectangularMarquee:
                    if let start = marqueeStart, let current = marqueeCurrent {
                        let r = CGRect(
                            x: min(start.x, current.x),
                            y: min(start.y, current.y),
                            width: abs(current.x - start.x),
                            height: abs(current.y - start.y)
                        )
                        if r.width > 2 && r.height > 2 {
                            doc.selection.shape = .rectangle(r)
                        }
                    }
                    marqueeStart = nil
                    marqueeCurrent = nil

                case .zoom:
                    doc.zoomIn()

                default:
                    break
                }
            }
    }

    private func sampleColor(at point: CGPoint, in doc: ArtDocument) {
        guard let image = doc.compositedImage() else { return }
        let x = Int(point.x)
        let y = Int(point.y)
        guard x >= 0, x < image.width, y >= 0, y < image.height else { return }

        if let pixelData = image.dataProvider?.data,
           let data = CFDataGetBytePtr(pixelData) {
            let bytesPerPixel = 4
            let bytesPerRow = image.bytesPerRow
            let offset = y * bytesPerRow + x * bytesPerPixel
            let r = Double(data[offset]) / 255.0
            let g = Double(data[offset + 1]) / 255.0
            let b = Double(data[offset + 2]) / 255.0
            appState.foregroundColor = Color(red: r, green: g, blue: b)
        }
    }
}

// MARK: - Checkerboard Background

struct CheckerboardBackground: View {
    var body: some View {
        Canvas { context, size in
            let tileSize: CGFloat = 12
            let cols = Int(ceil(size.width / tileSize))
            let rows = Int(ceil(size.height / tileSize))

            for row in 0..<rows {
                for col in 0..<cols {
                    let isEven = (row + col) % 2 == 0
                    let color = isEven ? Color(white: 0.88) : Color(white: 0.78)
                    let rect = CGRect(
                        x: CGFloat(col) * tileSize,
                        y: CGFloat(row) * tileSize,
                        width: tileSize,
                        height: tileSize
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}

// MARK: - Pixel Grid View

struct PixelGridView: View {
    let canvasSize: CGSize
    let zoomLevel: Double

    var body: some View {
        Canvas { context, size in
            let step = zoomLevel
            guard step >= 4.0 else { return }

            var path = Path()
            // Vertical lines
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }

            // Horizontal lines
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }

            context.stroke(path, with: .color(Color.black.opacity(0.12)), lineWidth: 0.5)
        }
    }
}

// MARK: - Selection Marquee View

struct SelectionMarqueeView: View {
    let rect: CGRect

    var body: some View {
        Rectangle()
            .strokeBorder(
                style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
            )
            .foregroundColor(Color.white)
            .background(
                Rectangle()
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 4], dashPhase: 4)
                    )
                    .foregroundColor(Color.black)
            )
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }
}
