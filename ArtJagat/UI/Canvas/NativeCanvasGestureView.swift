// NativeCanvasGestureView.swift
// ArtJagat — Native macOS trackpad gestures and canvas navigation

import SwiftUI
import AppKit

/// SwiftUI wrapper for native AppKit trackpad gesture recognizers and canvas navigation.
struct NativeCanvasGestureRepresentable: NSViewRepresentable {
    @ObservedObject var document: ArtDocument
    @ObservedObject var appState: AppState
    let viewportSize: CGSize

    func makeNSView(context: Context) -> NativeCanvasGestureNSView {
        let view = NativeCanvasGestureNSView()
        view.document = document
        view.appState = appState
        view.viewportSize = viewportSize
        return view
    }

    func updateNSView(_ nsView: NativeCanvasGestureNSView, context: Context) {
        nsView.document = document
        nsView.appState = appState
        nsView.viewportSize = viewportSize
    }
}

/// AppKit NSView handling native macOS trackpad gestures:
/// - Pinch-to-zoom with focal point preservation (NSMagnificationGestureRecognizer)
/// - Two-finger trackpad scrolling and panning (scrollWheel)
/// - Command + scroll wheel zooming
/// - Smart magnification (two-finger double tap)
/// - Spacebar + drag canvas panning without tool disruption
/// - Hand tool smooth canvas panning
final class NativeCanvasGestureNSView: NSView, NSGestureRecognizerDelegate {

    weak var document: ArtDocument?
    weak var appState: AppState?
    var viewportSize: CGSize = .zero

    private var pinchRecognizer: NSMagnificationGestureRecognizer!
    private var isSpaceDown: Bool = false
    private var isDragging: Bool = false
    private var lastDragLocation: NSPoint?
    private var localKeyMonitor: Any?
    private var trackingArea: NSTrackingArea?

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    // MARK: - Init & Lifecycle

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupGestures()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestures()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil && localKeyMonitor == nil {
            setupKeyMonitor()
        }
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        if newWindow == nil, let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
    }

    // MARK: - Setup Gestures

    private func setupGestures() {
        // Native macOS pinch magnification gesture recognizer
        pinchRecognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        pinchRecognizer.delegate = self
        pinchRecognizer.delaysMagnificationEvents = false
        addGestureRecognizer(pinchRecognizer)
    }

    private func setupKeyMonitor() {
        // Listen for Spacebar press/release for temporary canvas navigation
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            guard let self = self else { return event }

            // Do not intercept Space if user is editing a text field or text view
            if let responder = self.window?.firstResponder, responder is NSText {
                return event
            }

            if event.keyCode == 49 { // Spacebar on macOS
                if event.type == .keyDown && !event.isARepeat {
                    self.isSpaceDown = true
                    if !self.isDragging {
                        NSCursor.openHand.set()
                    }
                    return nil // Intercept Space key so it does not trigger sound or other actions
                } else if event.type == .keyUp {
                    self.isSpaceDown = false
                    if !self.isDragging {
                        self.restoreToolCursor()
                    }
                    return nil
                }
            }
            return event
        }
    }

    // MARK: - Pinch-to-Zoom (NSMagnificationGestureRecognizer)

    @objc private func handlePinchGesture(_ recognizer: NSMagnificationGestureRecognizer) {
        guard let doc = document, viewportSize.width > 0, viewportSize.height > 0 else { return }

        let focalPoint = recognizer.location(in: self)
        let delta = Double(recognizer.magnification)
        guard delta != 0 else { return }

        // Multiplier: 1.0 + delta (positive = pinch out / zoom in, negative = pinch in / zoom out)
        let factor = 1.0 + delta

        // Reset magnification delta so next action invocation is incremental
        recognizer.magnification = 0.0

        // Perform smooth zoom centered at the gesture's focal point
        doc.zoom(by: factor, around: focalPoint, in: viewportSize)
    }

    // Ensure we do NOT handle magnify(with:) if NSMagnificationGestureRecognizer is handling it,
    // to strictly avoid double-zooming per requirement 3.
    override func magnify(with event: NSEvent) {
        // Handled solely by pinchRecognizer; do not double-process
        super.magnify(with: event)
    }

    // MARK: - Trackpad Scrolling & Panning

    override func scrollWheel(with event: NSEvent) {
        guard let doc = document, viewportSize.width > 0, viewportSize.height > 0 else {
            super.scrollWheel(with: event)
            return
        }

        // Support Command + scroll wheel zooming centered at cursor position
        if event.modifierFlags.contains(.command) {
            let focalPoint = convert(event.locationInWindow, from: nil)
            let factor: Double
            if event.hasPreciseScrollingDeltas {
                factor = 1.0 + Double(event.scrollingDeltaY) * 0.015
            } else {
                factor = event.scrollingDeltaY > 0 ? 1.1 : 0.9
            }
            doc.zoom(by: factor, around: focalPoint, in: viewportSize)
            return
        }

        // Two-finger trackpad panning and standard scroll wheel
        // scrollingDeltaX / scrollingDeltaY natively respect user's macOS Natural Scrolling settings
        let dx = event.scrollingDeltaX
        let dy = event.scrollingDeltaY

        doc.panOffset.x += dx
        doc.panOffset.y += dy
    }

    // MARK: - Smart Magnification (Double Tap with Two Fingers)

    override func smartMagnify(with event: NSEvent) {
        guard let doc = document, viewportSize.width > 0, viewportSize.height > 0 else { return }
        let focalPoint = convert(event.locationInWindow, from: nil)

        // Toggle between Fit to Screen and 100% (Actual Pixels)
        if abs(doc.zoomLevel - 1.0) < 0.08 {
            doc.zoomToFit(viewSize: viewportSize)
        } else {
            doc.zoom(by: 1.0 / doc.zoomLevel, around: focalPoint, in: viewportSize)
        }
    }

    // MARK: - Spacebar & Hand Tool Drag Navigation

    override func mouseDown(with event: NSEvent) {
        if isSpaceDown || appState?.activeTool == .hand {
            isDragging = true
            lastDragLocation = convert(event.locationInWindow, from: nil)
            NSCursor.closedHand.set()
            return
        }
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        if (isSpaceDown || appState?.activeTool == .hand), isDragging {
            let current = convert(event.locationInWindow, from: nil)
            if let last = lastDragLocation, let doc = document {
                let dx = current.x - last.x
                let dy = current.y - last.y
                doc.panOffset.x += dx
                doc.panOffset.y += dy
            }
            lastDragLocation = current
            NSCursor.closedHand.set()
            return
        }
        super.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        if isDragging {
            isDragging = false
            lastDragLocation = nil
            if isSpaceDown || appState?.activeTool == .hand {
                NSCursor.openHand.set()
            } else {
                restoreToolCursor()
            }
            return
        }
        super.mouseUp(with: event)
    }

    // MARK: - Hit Testing

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard bounds.contains(point) else { return nil }

        // If Space is pressed or Hand tool is active, intercept clicks for drag-to-pan
        if isSpaceDown || appState?.activeTool == .hand {
            return self
        }

        // If the current event is a trackpad gesture or scroll event, intercept it
        if let type = NSApp.currentEvent?.type {
            if type == .magnify || type == .scrollWheel || type == .smartMagnify || type == .gesture {
                return self
            }
        }

        // For drawing tools (Brush, Eraser, Selection, Crop, Move, etc.), return nil
        // so the event passes through to the underlying SwiftUI canvas
        return nil
    }

    // MARK: - Cursor Management

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .cursorUpdate, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func cursorUpdate(with event: NSEvent) {
        if isSpaceDown || appState?.activeTool == .hand {
            if isDragging {
                NSCursor.closedHand.set()
            } else {
                NSCursor.openHand.set()
            }
        } else {
            restoreToolCursor()
        }
    }

    private func restoreToolCursor() {
        guard let tool = appState?.activeTool else {
            NSCursor.arrow.set()
            return
        }

        switch tool {
        case .hand:
            NSCursor.openHand.set()
        case .brush, .eraser:
            NSCursor.crosshair.set()
        case .move:
            NSCursor.arrow.set()
        case .zoom:
            NSCursor.crosshair.set()
        default:
            NSCursor.arrow.set()
        }
    }
}
