//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

/// Custom `NSTextAttachment` for citations with pre-decoded data.
///
/// Light/dark preview images are rendered once at init on the markdown parse
/// queue, so the `image` getter (called by TextKit on the main thread) never
/// rasterizes. Fixes the watchdog hang tracked by Sentry issue 6963759451.
final class InlineCitationAttachment: NSTextAttachment {
  /// The decoded citation data - available immediately without JSON parsing
  private(set) var citationData: InlineAttachmentData?

  /// Styling resolved from the active `CitationConfig`. Exposed so the live
  /// label provider can mirror the same look as the precomputed preview image.
  let font: UIFont
  let textColor: UIColor
  let backgroundColor: UIColor

  // MARK: - Interface style tracking

  /// Latest interface style, used by `image` to pick between the precomputed
  /// light/dark images. Updated from the main thread when a `ParagraphUIView`
  /// applies new content. Defaults to `.dark` to match the pre-existing
  /// behavior from #12415 before `updateInterfaceStyle` has been called.
  private static var currentInterfaceStyle: UIUserInterfaceStyle = .dark
  private static let styleLock = NSLock()

  static func updateInterfaceStyle(_ style: UIUserInterfaceStyle) {
    styleLock.lock()
    defer { styleLock.unlock() }
    currentInterfaceStyle = style
  }

  private static var latestStyle: UIUserInterfaceStyle {
    styleLock.lock()
    defer { styleLock.unlock() }
    return currentInterfaceStyle
  }

  // MARK: - Precomputed preview images

  /// Nil when `citationData` is missing. Rendered once at init and never
  /// mutated afterwards. `var` (vs `let`) is only so `init(coder:)` can
  /// populate these after `super.init` reconstructs `contents`.
  private var lightPreviewImage: UIImage?
  private var darkPreviewImage: UIImage?

  /// Backing store for `image` setter. Kept separate from the precomputed
  /// pair so a `set` call does not clobber `contents`/`fileType`.
  private var assignedImage: UIImage?

  // MARK: - Shared Layout

  /// Layout constants shared between the live `AttachmentCitationLabel` (in
  /// `InlineCitationViewProvider`) and the static image rasterized by
  /// `renderCitationImage`, so the two renderings stay visually identical.
  static let textInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
  static let cornerRadius: CGFloat = 6

  override var image: UIImage? {
    get {
      if let assignedImage { return assignedImage }
      return Self.latestStyle == .dark ? darkPreviewImage : lightPreviewImage
    }
    set {
      assignedImage = newValue
    }
  }

  /// Called during markdown parsing (background queue). Rasterizes both
  /// light/dark previews here so the getter never does work on the main thread.
  init(payload: Data, citationConfig: MarkdownRenderConfig.CitationConfig) {
    let decoded = try? JSONDecoder().decode(InlineAttachmentData.self, from: payload)
    let citationData = (decoded?.type == .citation) ? decoded : nil
    self.citationData = citationData

    self.font = citationConfig.font
    self.textColor = citationConfig.textColor
    self.backgroundColor = citationConfig.backgroundColor

    if let title = citationData?.title {
      self.lightPreviewImage = Self.renderCitationImage(
        title: title,
        font: self.font,
        textColor: self.textColor,
        backgroundColor: self.backgroundColor,
        traitCollection: UITraitCollection(userInterfaceStyle: .light)
      )
      self.darkPreviewImage = Self.renderCitationImage(
        title: title,
        font: self.font,
        textColor: self.textColor,
        backgroundColor: self.backgroundColor,
        traitCollection: UITraitCollection(userInterfaceStyle: .dark)
      )
    } else {
      self.lightPreviewImage = nil
      self.darkPreviewImage = nil
    }

    super.init(data: payload, ofType: UTType.url.identifier)
  }

  /// Create citation attachment directly from data struct
  convenience init?(citationData: InlineAttachmentData, citationConfig: MarkdownRenderConfig.CitationConfig) {
    guard citationData.type == .citation,
          let payload = try? JSONEncoder().encode(citationData) else {
      return nil
    }
    self.init(payload: payload, citationConfig: citationConfig)
  }

  required init?(coder: NSCoder) {
    return nil
  }

  // MARK: - Preview Image Rendering

  /// Thread-safe citation-label rendering using Core Graphics. Shares styling
  /// constants with `AttachmentCitationLabel` for visual consistency.
  private static func renderCitationImage(
    title: String,
    font: UIFont,
    textColor: UIColor,
    backgroundColor: UIColor,
    traitCollection: UITraitCollection
  ) -> UIImage {
    let textInsets = Self.textInsets
    let cornerRadius = Self.cornerRadius
    // Resolve dynamic colors for the current appearance (light/dark mode).
    let resolvedTextColor = textColor.resolvedColor(with: traitCollection)
    let resolvedBackgroundColor = backgroundColor.resolvedColor(with: traitCollection)

    // Measure text size using NSAttributedString (thread-safe)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: resolvedTextColor
    ]
    let textSize = (title as NSString).size(withAttributes: attributes)
    let totalSize = CGSize(
      width: ceil(textSize.width) + textInsets.left + textInsets.right,
      height: ceil(textSize.height) + textInsets.top + textInsets.bottom
    )

    let renderer = UIGraphicsImageRenderer(size: totalSize)
    return renderer.image { _ in
      let rect = CGRect(origin: .zero, size: totalSize)
      let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
      resolvedBackgroundColor.setFill()
      path.fill()

      let textRect = CGRect(
        x: textInsets.left,
        y: textInsets.top,
        width: ceil(textSize.width),
        height: ceil(textSize.height)
      )
      (title as NSString).draw(in: textRect, withAttributes: attributes)
    }
  }
}
