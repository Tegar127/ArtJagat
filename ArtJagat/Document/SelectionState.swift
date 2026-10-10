// SelectionState.swift
// ArtJagat — Represents the active selection in a document

import Foundation
import CoreGraphics

/// Represents the active pixel selection within a document.
struct SelectionState {

    enum SelectionShape {
        case none
        case rectangle(CGRect)
        case ellipse(CGRect)
        case polygon([CGPoint])
    }

    var shape: SelectionShape = .none

    var isEmpty: Bool {
        switch shape {
        case .none: return true
        case .rectangle(let r): return r.isEmpty
        case .ellipse(let r): return r.isEmpty
        case .polygon(let pts): return pts.count < 3
        }
    }

    var boundingRect: CGRect? {
        switch shape {
        case .none: return nil
        case .rectangle(let r), .ellipse(let r): return r
        case .polygon(let pts):
            guard !pts.isEmpty else { return nil }
            let xs = pts.map { $0.x }
            let ys = pts.map { $0.y }
            return CGRect(
                x: xs.min()!, y: ys.min()!,
                width: xs.max()! - xs.min()!,
                height: ys.max()! - ys.min()!
            )
        }
    }

    /// Check whether a document-space point is inside the selection
    func contains(_ point: CGPoint) -> Bool {
        switch shape {
        case .none: return true  // No selection = all selected
        case .rectangle(let r): return r.contains(point)
        case .ellipse(let r):
            let cx = r.midX, cy = r.midY
            let rx = r.width / 2, ry = r.height / 2
            guard rx > 0, ry > 0 else { return false }
            let dx = (point.x - cx) / rx
            let dy = (point.y - cy) / ry
            return (dx * dx + dy * dy) <= 1.0
        case .polygon(let pts):
            return polygonContains(point, polygon: pts)
        }
    }

    mutating func selectAll(in size: CGSize) {
        shape = .rectangle(CGRect(origin: .zero, size: size))
    }

    mutating func deselect() {
        shape = .none
    }

    mutating func invert(documentSize: CGSize) {
        // Simplified: toggle between full selection and none
        if isEmpty {
            selectAll(in: documentSize)
        } else {
            deselect()
        }
    }

    // MARK: - Polygon hit test (winding number)
    private func polygonContains(_ point: CGPoint, polygon: [CGPoint]) -> Bool {
        var winding = 0
        let n = polygon.count
        for i in 0..<n {
            let a = polygon[i]
            let b = polygon[(i + 1) % n]
            if a.y <= point.y {
                if b.y > point.y {
                    if isLeft(a, b, point) > 0 { winding += 1 }
                }
            } else {
                if b.y <= point.y {
                    if isLeft(a, b, point) < 0 { winding -= 1 }
                }
            }
        }
        return winding != 0
    }

    private func isLeft(_ a: CGPoint, _ b: CGPoint, _ p: CGPoint) -> CGFloat {
        return (b.x - a.x) * (p.y - a.y) - (p.x - a.x) * (b.y - a.y)
    }
}
