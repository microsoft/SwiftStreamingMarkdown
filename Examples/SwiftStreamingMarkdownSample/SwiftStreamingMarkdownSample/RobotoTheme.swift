//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftStreamingMarkdown
import SwiftUI
import UIKit

/// A completely custom `MarkdownRenderConfig` that demonstrates plugging in a
/// different type family (Google Roboto) and a vivid teal-on-deep-purple
/// color palette. Compare side-by-side against `MarkdownRenderConfig.default`
/// to see how every text style and color is configurable.
enum RobotoTheme {

  // MARK: - Colors

  private static let pageForeground = UIColor(red: 0.92, green: 0.96, blue: 1.00, alpha: 1.0)
  private static let mutedForeground = UIColor(red: 0.65, green: 0.78, blue: 0.90, alpha: 1.0)
  private static let accent = UIColor(red: 0.20, green: 0.85, blue: 0.78, alpha: 1.0)
  private static let accentSoft = UIColor(red: 0.20, green: 0.85, blue: 0.78, alpha: 0.18)
  private static let boldEmphasis = UIColor(red: 1.00, green: 0.78, blue: 0.36, alpha: 1.0)
  private static let codeForeground = UIColor(red: 0.98, green: 0.94, blue: 0.74, alpha: 1.0)
  private static let codeBackground = UIColor(red: 0.10, green: 0.06, blue: 0.20, alpha: 1.0)
  private static let codeUnderline = UIColor(red: 0.40, green: 0.30, blue: 0.55, alpha: 1.0)
  private static let tableHeaderBackground = UIColor(red: 0.18, green: 0.10, blue: 0.32, alpha: 1.0)
  private static let tableBorder = UIColor(red: 0.45, green: 0.30, blue: 0.65, alpha: 1.0)

  /// Background applied around the rendered content to make the Roboto theme
  /// pop visually. Exposed so `DemonstrationView` can paint the scroll view.
  static let pageBackground = Color(red: 0.07, green: 0.04, blue: 0.16)

  // MARK: - Fonts

  private static func roboto(_ size: CGFloat, weight: String = "Regular") -> UIFont {
    UIFont(name: "Roboto-\(weight)", size: size)
      ?? .systemFont(ofSize: size, weight: weight == "Bold" ? .bold : (weight == "Medium" ? .medium : .regular))
  }

  private static func robotoItalic(_ size: CGFloat, bold: Bool = false) -> UIFont {
    let name = bold ? "Roboto-BoldItalic" : "Roboto-Italic"
    return UIFont(name: name, size: size)
      ?? .italicSystemFont(ofSize: size)
  }

  private static func textFonts(size: CGFloat, lineHeight: CGFloat? = nil, letterSpacing: CGFloat? = nil) -> TextFonts {
    TextFonts(
      normal: roboto(size, weight: "Regular"),
      italic: robotoItalic(size),
      bold: roboto(size, weight: "Bold"),
      boldItalic: robotoItalic(size, bold: true),
      preferredLetterSpacing: letterSpacing,
      preferredLineHeight: lineHeight
    )
  }

  private static func headingFonts(size: CGFloat, letterSpacing: CGFloat) -> TextFonts {
    TextFonts(
      normal: roboto(size, weight: "Medium"),
      italic: robotoItalic(size),
      bold: roboto(size, weight: "Bold"),
      boldItalic: robotoItalic(size, bold: true),
      preferredLetterSpacing: letterSpacing,
      preferredLineHeight: size * 1.2
    )
  }

  // MARK: - Config

  static let renderConfig: MarkdownRenderConfig = MarkdownRenderConfig(
    shouldAnimateText: false,
    blockQuoteStyle: .init(
      textFonts: textFonts(size: 16, lineHeight: 24),
      textColor: mutedForeground
    ),
    headingStyle: .init(
      h1Font: headingFonts(size: 32, letterSpacing: -0.5),
      h2Font: headingFonts(size: 26, letterSpacing: -0.25),
      h3Font: headingFonts(size: 22, letterSpacing: 0),
      h4Font: headingFonts(size: 19, letterSpacing: 0),
      h5Font: headingFonts(size: 17, letterSpacing: 0.5),
      h6Font: headingFonts(size: 15, letterSpacing: 0.75),
      textColor: accent
    ),
    orderedListStyle: .init(
      textFonts: textFonts(size: 16, lineHeight: 24),
      textColor: pageForeground
    ),
    paragraphStyle: .init(
      textFonts: textFonts(size: 16, lineHeight: 24, letterSpacing: 0.15),
      textColor: pageForeground
    ),
    tableStyle: .init(
      textFonts: textFonts(size: 14, lineHeight: 20),
      headerTextColor: accent,
      regularTextColor: pageForeground,
      headerBackgroundColor: tableHeaderBackground,
      borderColor: tableBorder,
      actionButtonColor: accent
    ),
    inlineStyle: .init(
      boldTextColor: boldEmphasis,
      linkTextFont: roboto(16, weight: "Medium"),
      linkTextColor: accent,
      codeTextFont: UIFont.monospacedSystemFont(ofSize: 15, weight: .regular),
      codeTextColor: codeForeground,
      codeBackgroundColor: codeBackground,
      codeUnderlineColor: codeUnderline
    ),
    textContextMenu: nil,
    citationConfig: .init(
      isEnabled: true,
      font: roboto(12, weight: "Medium"),
      textColor: pageForeground,
      backgroundColor: accentSoft
    )
  )
}
