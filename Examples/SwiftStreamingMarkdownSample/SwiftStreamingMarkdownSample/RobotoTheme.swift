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

  /// Loads a named color from the `RobotoTheme` namespace in the main bundle's
  /// asset catalog. Each color provides both a light and dark appearance, so
  /// using the asset-backed `UIColor` lets the rendered markdown automatically
  /// adapt when the user toggles dark mode.
  private static func color(_ name: String) -> UIColor {
    UIColor(named: "RobotoTheme/\(name)") ?? .systemPink
  }

  private static var pageForeground: UIColor { color("PageForeground") }
  private static var mutedForeground: UIColor { color("MutedForeground") }
  private static var accent: UIColor { color("Accent") }
  private static var accentSoft: UIColor { color("AccentSoft") }
  private static var boldEmphasis: UIColor { color("BoldEmphasis") }
  private static var codeForeground: UIColor { color("CodeForeground") }
  private static var codeBackground: UIColor { color("CodeBackground") }
  private static var codeUnderline: UIColor { color("CodeUnderline") }
  private static var tableHeaderBackground: UIColor { color("TableHeaderBackground") }
  private static var tableBorder: UIColor { color("TableBorder") }

  /// Background applied around the rendered content to make the Roboto theme
  /// pop visually. Exposed so `DemonstrationView` can paint the scroll view.
  /// Backed by the same dark-mode-aware asset as everything else.
  static var pageBackground: Color { Color("RobotoTheme/PageBackground") }

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
