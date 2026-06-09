//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftStreamingMarkdown
import SwiftUI
import UIKit

enum SampleMarkdownTheme: String, CaseIterable, Identifiable {
  case automatic
  case system
  case roboto
  case presentation
  case midnight
  case sepia

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .automatic: "Automatic"
    case .system: "System"
    case .roboto: "Roboto"
    case .presentation: "Presentation"
    case .midnight: "Midnight"
    case .sepia: "Sepia"
    }
  }

  func backgroundColor(for demonstration: Demonstration) -> Color {
    switch resolvedTheme(for: demonstration) {
    case .automatic:
      demonstration.automaticBackgroundColor
    case .system:
      Color(.systemBackground)
    case .roboto:
      RobotoTheme.pageBackground
    case .presentation:
      Color(uiColor: Palette.presentation.background)
    case .midnight:
      Color(uiColor: Palette.midnight.background)
    case .sepia:
      Color(uiColor: Palette.sepia.background)
    }
  }

  func renderConfig(for demonstration: Demonstration, isStreaming: Bool) -> MarkdownRenderConfig {
    resolvedConfig(for: demonstration)
      .withTextContextMenu(value: demonstration.customContextMenu)
      .withShouldAnimateText(value: isStreaming)
  }

  private func resolvedTheme(for demonstration: Demonstration) -> SampleMarkdownTheme {
    switch self {
    case .automatic:
      switch demonstration {
      case .robotoTheme: .roboto
      default: .system
      }
    default:
      self
    }
  }

  private func resolvedConfig(for demonstration: Demonstration) -> MarkdownRenderConfig {
    switch resolvedTheme(for: demonstration) {
    case .automatic, .system:
      .default
    case .roboto:
      RobotoTheme.renderConfig
    case .presentation:
      Self.paletteConfig(.presentation)
    case .midnight:
      Self.paletteConfig(.midnight)
    case .sepia:
      Self.paletteConfig(.sepia)
    }
  }

  private static func paletteConfig(_ palette: Palette) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: false,
      blockQuoteStyle: .init(
        textFonts: MarkdownRenderConfig.defaultBlockQuoteStyle.textFonts,
        textColor: palette.secondaryForeground
      ),
      headingStyle: .init(
        h1Font: MarkdownRenderConfig.defaultHeadingStyle.h1Font,
        h2Font: MarkdownRenderConfig.defaultHeadingStyle.h2Font,
        h3Font: MarkdownRenderConfig.defaultHeadingStyle.h3Font,
        h4Font: MarkdownRenderConfig.defaultHeadingStyle.h4Font,
        h5Font: MarkdownRenderConfig.defaultHeadingStyle.h5Font,
        h6Font: MarkdownRenderConfig.defaultHeadingStyle.h6Font,
        textColor: palette.heading
      ),
      orderedListStyle: .init(
        textFonts: MarkdownRenderConfig.defaultOrderedListStyle.textFonts,
        textColor: palette.secondaryForeground
      ),
      paragraphStyle: .init(
        textFonts: MarkdownRenderConfig.defaultParagraphStyle.textFonts,
        textColor: palette.foreground
      ),
      tableStyle: .init(
        textFonts: MarkdownRenderConfig.defaultTableStyle.textFonts,
        headerTextColor: palette.heading,
        regularTextColor: palette.foreground,
        headerBackgroundColor: palette.tableHeaderBackground,
        borderColor: palette.border,
        actionButtonColor: palette.accent
      ),
      inlineStyle: .init(
        boldTextColor: palette.heading,
        linkTextFont: MarkdownRenderConfig.defaultInlineStyle.linkTextFont,
        linkTextColor: palette.accent,
        codeTextFont: MarkdownRenderConfig.defaultInlineStyle.codeTextFont,
        codeTextColor: palette.codeForeground,
        codeBackgroundColor: palette.codeBackground,
        codeUnderlineColor: palette.accent
      ),
      textContextMenu: nil,
      citationConfig: .init(
        isEnabled: true,
        font: MarkdownRenderConfig.default.citationConfig.font,
        textColor: palette.foreground,
        backgroundColor: palette.softAccent
      )
    )
  }
}

private struct Palette {
  let background: UIColor
  let foreground: UIColor
  let secondaryForeground: UIColor
  let heading: UIColor
  let accent: UIColor
  let softAccent: UIColor
  let codeForeground: UIColor
  let codeBackground: UIColor
  let tableHeaderBackground: UIColor
  let border: UIColor

  static let presentation = Palette(
    background: .dynamic(light: .sampleRGB(0.95, 0.98, 1.00), dark: .sampleRGB(0.03, 0.07, 0.13)),
    foreground: .dynamic(light: .sampleRGB(0.05, 0.13, 0.25), dark: .sampleRGB(0.88, 0.94, 1.00)),
    secondaryForeground: .dynamic(light: .sampleRGB(0.24, 0.34, 0.48), dark: .sampleRGB(0.62, 0.74, 0.88)),
    heading: .dynamic(light: .sampleRGB(0.02, 0.24, 0.56), dark: .sampleRGB(0.53, 0.78, 1.00)),
    accent: .dynamic(light: .sampleRGB(0.00, 0.39, 0.82), dark: .sampleRGB(0.38, 0.76, 1.00)),
    softAccent: .dynamic(light: .sampleRGB(0.83, 0.91, 1.00), dark: .sampleRGB(0.08, 0.20, 0.34)),
    codeForeground: .dynamic(light: .sampleRGB(0.02, 0.24, 0.44), dark: .sampleRGB(0.78, 0.90, 1.00)),
    codeBackground: .dynamic(light: .sampleRGB(0.88, 0.94, 1.00), dark: .sampleRGB(0.08, 0.12, 0.20)),
    tableHeaderBackground: .dynamic(light: .sampleRGB(0.82, 0.91, 1.00), dark: .sampleRGB(0.10, 0.17, 0.28)),
    border: .dynamic(light: .sampleRGB(0.58, 0.72, 0.91), dark: .sampleRGB(0.22, 0.34, 0.50))
  )

  static let midnight = Palette(
    background: .dynamic(light: .sampleRGB(0.92, 0.95, 1.00), dark: .sampleRGB(0.04, 0.05, 0.09)),
    foreground: .dynamic(light: .sampleRGB(0.10, 0.16, 0.28), dark: .sampleRGB(0.89, 0.93, 0.98)),
    secondaryForeground: .dynamic(light: .sampleRGB(0.31, 0.39, 0.54), dark: .sampleRGB(0.62, 0.69, 0.80)),
    heading: .dynamic(light: .sampleRGB(0.10, 0.32, 0.70), dark: .sampleRGB(0.56, 0.80, 1.00)),
    accent: .dynamic(light: .sampleRGB(0.05, 0.46, 0.72), dark: .sampleRGB(0.40, 0.86, 0.98)),
    softAccent: .dynamic(light: .sampleRGB(0.78, 0.89, 1.00), dark: .sampleRGB(0.10, 0.22, 0.33)),
    codeForeground: .dynamic(light: .sampleRGB(0.07, 0.24, 0.43), dark: .sampleRGB(0.82, 0.93, 1.00)),
    codeBackground: .dynamic(light: .sampleRGB(0.84, 0.90, 0.99), dark: .sampleRGB(0.10, 0.12, 0.19)),
    tableHeaderBackground: .dynamic(light: .sampleRGB(0.78, 0.86, 0.98), dark: .sampleRGB(0.12, 0.16, 0.25)),
    border: .dynamic(light: .sampleRGB(0.55, 0.66, 0.84), dark: .sampleRGB(0.22, 0.29, 0.42))
  )

  static let sepia = Palette(
    background: .dynamic(light: .sampleRGB(0.98, 0.93, 0.84), dark: .sampleRGB(0.13, 0.09, 0.05)),
    foreground: .dynamic(light: .sampleRGB(0.26, 0.17, 0.08), dark: .sampleRGB(0.94, 0.84, 0.66)),
    secondaryForeground: .dynamic(light: .sampleRGB(0.47, 0.34, 0.18), dark: .sampleRGB(0.74, 0.60, 0.39)),
    heading: .dynamic(light: .sampleRGB(0.55, 0.24, 0.08), dark: .sampleRGB(0.96, 0.55, 0.25)),
    accent: .dynamic(light: .sampleRGB(0.68, 0.32, 0.10), dark: .sampleRGB(0.96, 0.62, 0.31)),
    softAccent: .dynamic(light: .sampleRGB(0.91, 0.78, 0.56), dark: .sampleRGB(0.33, 0.20, 0.10)),
    codeForeground: .dynamic(light: .sampleRGB(0.43, 0.18, 0.07), dark: .sampleRGB(0.98, 0.73, 0.45)),
    codeBackground: .dynamic(light: .sampleRGB(0.93, 0.84, 0.66), dark: .sampleRGB(0.20, 0.13, 0.07)),
    tableHeaderBackground: .dynamic(light: .sampleRGB(0.90, 0.78, 0.58), dark: .sampleRGB(0.24, 0.16, 0.08)),
    border: .dynamic(light: .sampleRGB(0.72, 0.57, 0.36), dark: .sampleRGB(0.48, 0.33, 0.17))
  )
}

private extension UIColor {
  static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
    UIColor { traitCollection in
      traitCollection.userInterfaceStyle == .dark ? dark : light
    }
  }

  static func sampleRGB(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
    UIColor(red: red, green: green, blue: blue, alpha: 1)
  }
}
