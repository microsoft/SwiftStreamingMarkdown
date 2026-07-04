//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(AppKit)
import AppKit
import SnapshotTesting
import SwiftUI
import XCTest

/// Window-size-based variant for macOS snapshot testing.
public struct MacVariant {
  let title: WindowSize
  let size: CGSize
  let snapshot: Snapshotting<NSViewController, NSImage>
  let colorScheme: ColorScheme

  enum WindowSize: String {
    case standard   // ~800pt, typical window
    case wide       // ~1200pt, full-width
  }
}

extension MacVariant {
  var name: String {
    "macOS-\(title.rawValue)-\(colorScheme.macDescription)"
  }
}

private extension ColorScheme {
  var macDescription: String {
    switch self {
    case .light: return "light"
    case .dark: return "dark"
    @unknown default: fatalError()
    }
  }
}

// MARK: - Window-Based Snapshotting

/// Custom snapshotting that places the view in a real NSWindow and captures it
/// using CGWindowListCreateImage — the same composited output the window server
/// produces. This correctly captures all views including MTMathUILabel.
extension Snapshotting where Value == NSView, Format == NSImage {
  static func layerImage(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    size: CGSize? = nil
  ) -> Snapshotting {
    return SimplySnapshotting.image(
      precision: precision, perceptualPrecision: perceptualPrecision
    ).asyncPullback { view in
      let initialSize = view.frame.size
      if let size = size { view.frame.size = size }
      guard view.frame.width > 0, view.frame.height > 0 else {
        fatalError("View not renderable to image at size \(view.frame.size)")
      }

      return Async { callback in
        // Place view in a real on-screen window
        let window = NSWindow(
          contentRect: NSRect(origin: CGPoint(x: 50, y: 50), size: view.frame.size),
          styleMask: [.borderless],
          backing: .buffered,
          defer: false
        )
        window.contentView = view
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .floating
        window.orderFrontRegardless()

        // Run the RunLoop to allow full display pipeline
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))

        // Force layout and display
        view.needsLayout = true
        view.layoutSubtreeIfNeeded()
        view.needsDisplay = true
        view.displayIfNeeded()
        window.displayIfNeeded()

        // Another pass for subviews
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))

        // Capture using CGWindowListCreateImage — gets the exact composited output
        let windowID = CGWindowID(window.windowNumber)
        let bounds = CGRect.null  // capture full window
        guard let cgImage = CGWindowListCreateImage(
          bounds,
          .optionIncludingWindow,
          windowID,
          [.boundsIgnoreFraming, .nominalResolution]
        ) else {
          fatalError("CGWindowListCreateImage failed")
        }

        let image = NSImage(cgImage: cgImage, size: view.bounds.size)

        // Clean up
        window.contentView = nil
        window.orderOut(nil)

        callback(image)
        view.frame.size = initialSize
      }
    }
  }
}

extension Snapshotting where Value == NSViewController, Format == NSImage {
  /// Window-based image snapshotting for view controllers.
  static func layerImage(
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    size: CGSize? = nil
  ) -> Snapshotting {
    return Snapshotting<NSView, NSImage>.layerImage(
      precision: precision, perceptualPrecision: perceptualPrecision, size: size
    ).pullback { $0.view }
  }
}

// MARK: - Factory Methods

extension MacVariant {
  static func standard(
    colorScheme: ColorScheme = .light,
    precision: Float = 1,
    perceptualPrecision: Float = 1
  ) -> MacVariant {
    let size = CGSize(width: 800, height: 800)
    return MacVariant(
      title: .standard,
      size: size,
      snapshot: .layerImage(precision: precision, perceptualPrecision: perceptualPrecision, size: size),
      colorScheme: colorScheme
    )
  }

  static func wide(
    colorScheme: ColorScheme = .light,
    precision: Float = 1,
    perceptualPrecision: Float = 1
  ) -> MacVariant {
    let size = CGSize(width: 1200, height: 800)
    return MacVariant(
      title: .wide,
      size: size,
      snapshot: .layerImage(precision: precision, perceptualPrecision: perceptualPrecision, size: size),
      colorScheme: colorScheme
    )
  }
}

// MARK: - Standard Collections

extension Collection where Element == MacVariant {
  /// Standard macOS variants: standard light/dark
  public static func standard(
    precision: Float = 1,
    perceptualPrecision: Float = 1.0
  ) -> [MacVariant] {
    [
      .standard(colorScheme: .light, precision: precision, perceptualPrecision: perceptualPrecision),
      .standard(colorScheme: .dark, precision: precision, perceptualPrecision: perceptualPrecision)
    ]
  }

  /// Wide variants only (light and dark)
  public static func wideOnly(
    precision: Float = 1,
    perceptualPrecision: Float = 1.0
  ) -> [MacVariant] {
    [
      .wide(colorScheme: .light, precision: precision, perceptualPrecision: perceptualPrecision),
      .wide(colorScheme: .dark, precision: precision, perceptualPrecision: perceptualPrecision)
    ]
  }
}
#endif
