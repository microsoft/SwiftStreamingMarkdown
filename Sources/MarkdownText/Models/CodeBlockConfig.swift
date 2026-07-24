//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import HighlightSwift
import SwiftUI

/// Styling configuration for fenced code blocks, primarily the syntax-
/// highlighting color theme.
public struct CodeBlockConfig: Hashable, Sendable {

  /// Syntax-highlighting color theme applied to code blocks.
  ///
  /// Built-in cases map to the matching highlight.js theme and automatically
  /// resolve to their light or dark variant based on the active `ColorScheme`.
  /// Use `.custom(lightCSS:darkCSS:)` to supply your own highlight.js CSS for
  /// each appearance.
  public enum Theme: Hashable, Sendable {
    case a11y
    case atomOne
    case classic
    case edge
    case github
    case google
    case gradient
    case grayscale
    case harmonic16
    case heetch
    case horizon
    case humanoid
    case ia
    case isblEditor
    case kimbie
    case nnfx
    case pandaSyntax
    case papercolor
    case paraiso
    case qtcreator
    case silk
    case solarFlare
    case solarized
    case stackoverflow
    case standard
    case summerfruit
    case synthMidnightTerminal
    case tokyoNight
    case unikitty
    case xcode

    /// Custom highlight.js CSS supplied per appearance.
    /// - Parameters:
    ///   - lightCSS: CSS applied when the active color scheme is light.
    ///   - darkCSS: CSS applied when the active color scheme is dark.
    case custom(lightCSS: String, darkCSS: String)

    /// The default theme, preserving the bundled dark code-block styling in
    /// both light and dark appearances.
    public static let `default` = Theme.custom(
      lightCSS: CodeBlockConfig.defaultCSS,
      darkCSS: CodeBlockConfig.defaultCSS
    )
  }

  /// The syntax-highlighting theme applied to code blocks.
  public let theme: Theme

  /// Background color applied behind the code block chrome. `nil` leaves the
  /// background unset so the surrounding content shows through; this is the
  /// default for any non-default theme.
  public let backgroundColor: Color?

  /// Foreground color applied to the code block chrome (language label and
  /// copy control). `nil` falls back to the bundled `Stone350`.
  public let foregroundColor: Color?

  /// Create a code-block configuration.
  /// - Parameters:
  ///   - theme: See `theme`. Defaults to `Theme.default`.
  ///   - backgroundColor: See `backgroundColor`. Defaults to `nil` (unset).
  ///   - foregroundColor: See `foregroundColor`. Defaults to `nil` (`Stone350`).
  public init(
    theme: Theme = .default,
    backgroundColor: Color? = nil,
    foregroundColor: Color? = nil
  ) {
    self.theme = theme
    self.backgroundColor = backgroundColor
    self.foregroundColor = foregroundColor
  }

  /// The default code-block configuration, which keeps the bundled dark
  /// code-block background.
  public static let `default` = CodeBlockConfig(
    theme: .default,
    backgroundColor: Color.Theme.Component.CodeBlock.Background.Background750
  )
}

extension CodeBlockConfig.Theme {
  /// Resolve the highlight.js colors to use for the given color scheme.
  ///
  /// Only `colors.css` affects the rendered `AttributedString`; the code-block
  /// chrome background is owned by `CodeBlockView`, so the theme background hex
  /// is intentionally ignored here.
  func highlightColors(for colorScheme: ColorScheme) -> HighlightColors {
    switch self {
    case .custom(let lightCSS, let darkCSS):
      return .custom(css: colorScheme == .dark ? darkCSS : lightCSS)
    default:
      let theme = builtInHighlightTheme
      return colorScheme == .dark ? .dark(theme) : .light(theme)
    }
  }

  /// The `HighlightTheme` matching a built-in case.
  ///
  /// `.custom` is handled before this is read; it falls back to `.xcode`.
  private var builtInHighlightTheme: HighlightTheme {
    switch self {
    case .a11y: return .a11y
    case .atomOne: return .atomOne
    case .classic: return .classic
    case .edge: return .edge
    case .github: return .github
    case .google: return .google
    case .gradient: return .gradient
    case .grayscale: return .grayscale
    case .harmonic16: return .harmonic16
    case .heetch: return .heetch
    case .horizon: return .horizon
    case .humanoid: return .humanoid
    case .ia: return .ia
    case .isblEditor: return .isblEditor
    case .kimbie: return .kimbie
    case .nnfx: return .nnfx
    case .pandaSyntax: return .pandaSyntax
    case .papercolor: return .papercolor
    case .paraiso: return .paraiso
    case .qtcreator: return .qtcreator
    case .silk: return .silk
    case .solarFlare: return .solarFlare
    case .solarized: return .solarized
    case .stackoverflow: return .stackoverflow
    case .standard: return .standard
    case .summerfruit: return .summerfruit
    case .synthMidnightTerminal: return .synthMidnightTerminal
    case .tokyoNight: return .tokyoNight
    case .unikitty: return .unikitty
    case .xcode: return .xcode
    case .custom: return .xcode
    }
  }
}

extension CodeBlockConfig {
  /// The bundled default highlight.js CSS, tuned for a dark code-block chrome.
  static let defaultCSS = """
  code {
  color: #FCFAF7
  }

  .hljs-comment,
  .hljs-meta {
  color: #AA9C87
  }

  .hljs-built_in,
  .hljs-class .hljs-title {
  color: #FFC42F
  }

  .hljs-doctag,
  .hljs-formula,
  .hljs-keyword,
  .hljs-literal {
  color: #67ABF1
  }
  .hljs-addition,
  .hljs-attribute,
  .hljs-meta-string,
  .hljs-regexp,
  .hljs-string {
  color: #00B360
  }
  .hljs-attr,
  .hljs-number,
  .hljs-selector-attr,
  .hljs-selector-class,
  .hljs-selector-pseudo,
  .hljs-template-variable,
  .hljs-type,
  .hljs-variable {
  color: #F96C00
  }

  .hljs-bullet,
  .hljs-link,
  .hljs-selector-id,
  .hljs-symbol,
  .hljs-title {
  color: #E3B5FA
  }
  """
}
