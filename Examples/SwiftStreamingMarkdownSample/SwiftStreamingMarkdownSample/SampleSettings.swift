//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI

enum SampleSettings {
  static let preferStreamedMarkdownKey = "preferStreamedMarkdown"
  static let appearanceModeKey = "appearanceMode"
  static let markdownThemeKey = "markdownTheme"
}

enum AppearanceMode: String, CaseIterable, Identifiable {
  case device
  case light
  case dark

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .device: return "Device"
    case .light: return "Light"
    case .dark: return "Dark"
    }
  }

  var colorScheme: ColorScheme? {
    switch self {
    case .device: return nil
    case .light: return .light
    case .dark: return .dark
    }
  }
}
