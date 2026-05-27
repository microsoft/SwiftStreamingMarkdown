//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import SwiftUI

enum SampleSettings {
  static let preferStreamedMarkdownKey = "preferStreamedMarkdown"
  static let appearanceModeKey = "appearanceMode"
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
