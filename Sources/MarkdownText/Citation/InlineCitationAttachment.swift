//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import UniformTypeIdentifiers

final class InlineCitationAttachment: NSTextAttachment {
  /// The decoded citation data - available immediately without JSON parsing
  private(set) var citationData: InlineAttachmentData?

  /// Styling resolved from the active `CitationConfig`. Exposed so the live
  /// label provider can mirror the same look as the precomputed preview image.
  let font: MDFont
  let textColor: MDColor
  let backgroundColor: MDColor

  // MARK: - Precomputed preview images

  private var lightPreviewImage: MDImage?
  private var darkPreviewImage: MDImage?
  private var assignedImage: MDImage?

  // MARK: - Shared Layout

  static let textInsets = MDEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
  static let cornerRadius: CGFloat = 6

  // MARK: - Secure Coding

  override class var supportsSecureCoding: Bool { true }

  private static let payloadCoderKey = "payload"
  private static let fontCoderKey = "font"
  private static let textColorCoderKey = "textColor"
  private static let backgroundColorCoderKey = "backgroundColor"

  #if canImport(UIKit)
  override var image: UIImage? {
    get {
      if let assignedImage { return assignedImage }
      let app = AppAppearance.$current.read({ $0 })
      switch app {
      case .dark: return darkPreviewImage
      case .light: return lightPreviewImage
      }
    }
    set { assignedImage = newValue }
  }
  #elseif canImport(AppKit)
  override var image: NSImage? {
    get {
      if let assignedImage { return assignedImage }
      let app = AppAppearance.$current.read({ $0 })
      switch app {
      case .dark: return darkPreviewImage
      case .light: return lightPreviewImage
      }
    }
    set { assignedImage = newValue }
  }
  #endif

  /// Called during markdown parsing (background queue). Rasterizes both
  /// light/dark previews here so the getter never does work on the main thread.
  init(payload: Data, citationConfig: MarkdownRenderConfig.CitationConfig) {
    let decoded = try? JSONDecoder().decode(InlineAttachmentData.self, from: payload)
    let citationData = (decoded?.type == .citation) ? decoded : nil
    self.citationData = citationData

    self.font = citationConfig.font
    self.textColor = MDColor(citationConfig.textColor)
    self.backgroundColor = MDColor(citationConfig.backgroundColor)
    (self.lightPreviewImage, self.darkPreviewImage) = Self.previewImages(
      title: citationData?.title, font: self.font, textColor: self.textColor, backgroundColor: self.backgroundColor
    )

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

  /// Reconstructs the attachment from an archive. Since `NSCoder` has no access to a
  /// live `MarkdownRenderConfig.CitationConfig`, the font/colors used to render the
  /// preview images are persisted directly alongside the citation payload.
  required init?(coder: NSCoder) {
    guard let payload = coder.decodeObject(of: NSData.self, forKey: Self.payloadCoderKey) as Data?,
          let font = coder.decodeObject(of: MDFont.self, forKey: Self.fontCoderKey),
          let textColor = coder.decodeObject(of: MDColor.self, forKey: Self.textColorCoderKey),
          let backgroundColor = coder.decodeObject(of: MDColor.self, forKey: Self.backgroundColorCoderKey) else {
      return nil
    }

    let decoded = try? JSONDecoder().decode(InlineAttachmentData.self, from: payload)
    let citationData = (decoded?.type == .citation) ? decoded : nil
    self.citationData = citationData

    self.font = font
    self.textColor = textColor
    self.backgroundColor = backgroundColor
    (self.lightPreviewImage, self.darkPreviewImage) = Self.previewImages(
      title: citationData?.title, font: font, textColor: textColor, backgroundColor: backgroundColor
    )

    super.init(data: payload, ofType: UTType.url.identifier)
  }

  override func encode(with coder: NSCoder) {
    super.encode(with: coder)
    if let payload = self.contents {
      coder.encode(payload as NSData, forKey: Self.payloadCoderKey)
    }
    coder.encode(font, forKey: Self.fontCoderKey)
    coder.encode(textColor, forKey: Self.textColorCoderKey)
    coder.encode(backgroundColor, forKey: Self.backgroundColorCoderKey)
  }

  // MARK: - Preview Image Rendering

  private static func previewImages(
    title: String?, font: MDFont, textColor: MDColor, backgroundColor: MDColor
  ) -> (light: MDImage?, dark: MDImage?) {
    guard let title else { return (nil, nil) }
    return (
      renderCitationImage(title: title, font: font, textColor: textColor, backgroundColor: backgroundColor, appearance: .light),
      renderCitationImage(title: title, font: font, textColor: textColor, backgroundColor: backgroundColor, appearance: .dark)
    )
  }

  private static func renderCitationImage(
    title: String, font: MDFont,
    textColor: MDColor, backgroundColor: MDColor,
    appearance: AppAppearance
  ) -> MDImage {
    // Resolve colors for the target appearance
    #if canImport(UIKit)
    let traitCollection = UITraitCollection(userInterfaceStyle: appearance.platformType)
    let resolvedTextColor = textColor.resolvedColor(with: traitCollection)
    let resolvedBackgroundColor = backgroundColor.resolvedColor(with: traitCollection)
    #elseif canImport(AppKit)
    var resolvedTextColor = textColor
    var resolvedBackgroundColor = backgroundColor
    appearance.platformType?.performAsCurrentDrawingAppearance {
      resolvedTextColor = textColor.usingColorSpace(.sRGB) ?? textColor
      resolvedBackgroundColor = backgroundColor.usingColorSpace(.sRGB) ?? backgroundColor
    }
    #endif

    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: resolvedTextColor]
    let textSize = (title as NSString).size(withAttributes: attributes)
    let totalSize = CGSize(
      width: ceil(textSize.width) + textInsets.left + textInsets.right,
      height: ceil(textSize.height) + textInsets.top + textInsets.bottom
    )

    // Render the citation pill image
    #if canImport(UIKit)
    let renderer = UIGraphicsImageRenderer(size: totalSize)
    return renderer.image { _ in
      let rect = CGRect(origin: .zero, size: totalSize)
      let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
      resolvedBackgroundColor.setFill()
      path.fill()

      let textRect = CGRect(x: textInsets.left, y: textInsets.top,
                            width: ceil(textSize.width), height: ceil(textSize.height))
      (title as NSString).draw(in: textRect, withAttributes: attributes)
    }
    #elseif canImport(AppKit)
    return NSImage(size: totalSize, flipped: false) { rect in
      let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
      resolvedBackgroundColor.setFill()
      path.fill()

      let textRect = CGRect(x: Self.textInsets.left, y: Self.textInsets.bottom,
                            width: ceil(textSize.width), height: ceil(textSize.height))
      (title as NSString).draw(in: textRect, withAttributes: attributes)
      return true
    }
    #endif
  }
}
