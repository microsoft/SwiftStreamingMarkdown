//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import CoreGraphics
import iosMath
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
final class LatexAttachment: NSTextAttachment {
  private static let transparentImage = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }

  override func image(for bounds: CGRect,
                      attributes: [NSAttributedString.Key: Any],
                      location: any NSTextLocation,
                      textContainer: NSTextContainer?) -> UIImage? {
    Self.transparentImage
  }
}
#elseif canImport(AppKit)
final class LatexAttachment: NSTextAttachment {
  private static let transparentImage: NSImage = {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    guard let context = CGContext(
      data: nil,
      width: 1,
      height: 1,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    ), let cgImage = context.makeImage() else {
      return NSImage(size: NSSize(width: 1, height: 1))
    }
    return NSImage(cgImage: cgImage, size: NSSize(width: 1, height: 1))
  }()

  override func image(for bounds: NSRect,
                      attributes: [NSAttributedString.Key: Any],
                      location: any NSTextLocation,
                      textContainer: NSTextContainer?) -> NSImage? {
    Self.transparentImage
  }
}
#endif

// MARK: - LatexAttachmentData Color Resolution

extension LatexAttachmentData {
  var resolvedTextColor: MDColor {
    let fallback = MDColor(Color.Theme.Foreground.Primary.Primary750)
    #if canImport(UIKit)
    guard let lightColor = UIColor(hex: lightTextColor),
          let darkColor = UIColor(hex: darkTextColor) else {
      return fallback
    }
    return UIColor { trait in
      trait.userInterfaceStyle == .dark ? darkColor : lightColor
    }
    #elseif canImport(AppKit)
    guard let lightColor = NSColor(hex: lightTextColor),
          let darkColor = NSColor(hex: darkTextColor) else {
      return fallback
    }
    return NSColor(name: nil) { appearance in
      let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
      return isDark ? darkColor : lightColor
    }
    #endif
  }
}

// MARK: - Latex View Provider

final class LatexViewProvider: NSTextAttachmentViewProvider {
  private let latex: String
  private let fontSize: CGFloat
  private let textColor: MDColor
  private static let jsonDecoder = JSONDecoder()

  private struct DecodedAttachment {
    var latex: String = ""
    var fontSize: CGFloat = Typography.base.mdFont.pointSize
    var textColor: MDColor = MDColor(Color.Theme.Foreground.Primary.Primary750)
  }

  #if canImport(UIKit)
  required override init(textAttachment attachment: NSTextAttachment,
                         parentView: UIView?,
                         textLayoutManager: NSTextLayoutManager?,
                         location: any NSTextLocation) {
    let decoded = Self.decode(attachment: attachment)
    (latex, fontSize, textColor) = (decoded.latex, decoded.fontSize, decoded.textColor)
    super.init(textAttachment: attachment, parentView: parentView,
               textLayoutManager: textLayoutManager, location: location)
    tracksTextAttachmentViewBounds = true
  }
  #elseif canImport(AppKit)
  required override init(textAttachment attachment: NSTextAttachment,
                         parentView: NSView?,
                         textLayoutManager: NSTextLayoutManager?,
                         location: any NSTextLocation) {
    let decoded = Self.decode(attachment: attachment)
    (latex, fontSize, textColor) = (decoded.latex, decoded.fontSize, decoded.textColor)
    super.init(textAttachment: attachment, parentView: parentView,
               textLayoutManager: textLayoutManager, location: location)
    tracksTextAttachmentViewBounds = true
  }
  #endif

  private static func decode(attachment: NSTextAttachment) -> DecodedAttachment {
    var result = DecodedAttachment()
    if let data = attachment.contents,
       let attachmentData = try? jsonDecoder.decode(LatexAttachmentData.self, from: data) {
      result.latex = attachmentData.latex
      result.fontSize = attachmentData.fontSize
      result.textColor = attachmentData.resolvedTextColor
    }
    return result
  }

  override func loadView() {
    let label = MTMathUILabel()
    #if canImport(UIKit)
    label.isOpaque = false
    #endif
    label.backgroundColor = .clear
    label.latex = latex
    label.textColor = textColor
    label.displayErrorInline = false
    label.fontSize = fontSize
    label.setContentHuggingPriority(.defaultHigh, for: .vertical)
    self.view = label
  }

  override func attachmentBounds(for attributes: [NSAttributedString.Key: Any],
                                 location: any NSTextLocation,
                                 textContainer: NSTextContainer?,
                                 proposedLineFragment: CGRect,
                                 position: CGPoint) -> CGRect {
    guard let mathLabel = view as? MTMathUILabel else {
      return .zero
    }
    #if canImport(UIKit)
    mathLabel.sizeToFit()
    let size = mathLabel.bounds.size
    #elseif canImport(AppKit)
    let size = mathLabel.intrinsicContentSize
    #endif
    let height = size.height.rounded(.up) + 1.0
    let font = attributes[.font] as? MDFont ?? MDFont.systemFont(ofSize: fontSize)
    let yOffset = (font.xHeight - height) / 2.0
    return CGRect(x: 0, y: yOffset, width: size.width.rounded(.up), height: height)
  }
}
