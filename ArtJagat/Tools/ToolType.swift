// ToolType.swift
// ArtJagat — Tool definitions, display attributes, and keyboard shortcuts

import SwiftUI

/// Available workspace tools in ArtJagat
enum ToolType: String, CaseIterable, Identifiable {
    // Navigation
    case hand = "hand"
    case zoom = "zoom"

    // Selection
    case rectangularMarquee = "rectangular_marquee"
    case ellipticalMarquee = "elliptical_marquee"
    case lasso = "lasso"

    // Editing
    case move = "move"
    case crop = "crop"
    case brush = "brush"
    case eraser = "eraser"

    // Creation
    case text = "text"
    case rectangle = "rectangle"
    case ellipse = "ellipse"
    case line = "line"

    // Color
    case eyedropper = "eyedropper"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hand: return "Hand"
        case .zoom: return "Zoom"
        case .rectangularMarquee: return "Rectangular Marquee"
        case .ellipticalMarquee: return "Elliptical Marquee"
        case .lasso: return "Lasso"
        case .move: return "Move"
        case .crop: return "Crop"
        case .brush: return "Brush"
        case .eraser: return "Eraser"
        case .text: return "Text"
        case .rectangle: return "Rectangle"
        case .ellipse: return "Ellipse"
        case .line: return "Line"
        case .eyedropper: return "Eyedropper"
        }
    }

    var iconName: String {
        switch self {
        case .hand: return "hand.raised.fill"
        case .zoom: return "magnifyingglass"
        case .rectangularMarquee: return "rectangle.dashed"
        case .ellipticalMarquee: return "oval.fill"
        case .lasso: return "lasso"
        case .move: return "arrow.up.and.down.and.arrow.left.and.right"
        case .crop: return "crop"
        case .brush: return "paintbrush.pointed.fill"
        case .eraser: return "eraser.fill"
        case .text: return "t.square.fill"
        case .rectangle: return "rectangle.fill"
        case .ellipse: return "circle.fill"
        case .line: return "line.diagonal"
        case .eyedropper: return "eyedropper.halffull"
        }
    }

    var shortcut: String? {
        switch self {
        case .hand: return "H"
        case .zoom: return "Z"
        case .rectangularMarquee: return "M"
        case .ellipticalMarquee: return nil
        case .lasso: return "L"
        case .move: return "V"
        case .crop: return "C"
        case .brush: return "B"
        case .eraser: return "E"
        case .text: return "T"
        case .rectangle: return "U"
        case .ellipse: return nil
        case .line: return nil
        case .eyedropper: return "I"
        }
    }
}
