//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import BeautifulMermaid
import SwiftUI

/// Styling configuration for Mermaid diagrams.
public struct MermaidConfig: Hashable, Sendable {

  /// A named BeautifulMermaid diagram theme.
  public enum Theme: String, CaseIterable, Hashable, Sendable {
    /// Resolves to the light or dark variant of the bundled default theme based
    /// on the active `ColorScheme`.
    case auto
    case zincLight
    case zincDark
    case tokyoNight
    case tokyoNightStorm
    case tokyoNightLight
    case catppuccinMocha
    case catppuccinLatte
    case nord
    case nordLight
    case dracula
    case githubLight
    case githubDark
    case solarizedLight
    case solarizedDark
    case oneDark
    case gruvboxDark
    case gruvboxLight

    /// Resolve the `DiagramTheme` to render with for the given color scheme.
    func diagramTheme(for colorScheme: ColorScheme) -> DiagramTheme {
      switch self {
      case .auto:
        return colorScheme == .dark ? .zincDark : .zincLight
      case .zincLight: return .zincLight
      case .zincDark: return .zincDark
      case .tokyoNight: return .tokyoNight
      case .tokyoNightStorm: return .tokyoNightStorm
      case .tokyoNightLight: return .tokyoNightLight
      case .catppuccinMocha: return .catppuccinMocha
      case .catppuccinLatte: return .catppuccinLatte
      case .nord: return .nord
      case .nordLight: return .nordLight
      case .dracula: return .dracula
      case .githubLight: return .githubLight
      case .githubDark: return .githubDark
      case .solarizedLight: return .solarizedLight
      case .solarizedDark: return .solarizedDark
      case .oneDark: return .oneDark
      case .gruvboxDark: return .gruvboxDark
      case .gruvboxLight: return .gruvboxLight
      }
    }
  }

  /// The theme applied to rendered diagrams. Defaults to `.auto`, which follows
  /// the active `ColorScheme`.
  public let theme: Theme

  /// Whether Mermaid diagram rendering is enabled.
  public let isEnabled: Bool

  /// Create a mermaid configuration.
  /// - Parameters:
  ///   - theme: See `theme`. Defaults to `.auto`.
  ///   - isEnabled: See `isEnabled`. Defaults to `true`.
  public init(theme: Theme = .auto, isEnabled: Bool = true) {
    self.theme = theme
    self.isEnabled = isEnabled
  }

  /// The default mermaid configuration, following the active color scheme.
  public static let `default` = MermaidConfig()

  /// Mermaid diagram rendering disabled.
  public static let disabled = MermaidConfig(isEnabled: false)
}
