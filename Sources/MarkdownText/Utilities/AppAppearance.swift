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

/// Cross-platform appearance representation used to select
/// the precomputed light/dark citation preview image.
enum AppAppearance {
  case light
  case dark

  @WithLock
  static var current: AppAppearance = .dark

  #if canImport(UIKit)
  var platformType: UIUserInterfaceStyle {
    switch self {
    case .dark: return UIUserInterfaceStyle.dark
    case .light: return UIUserInterfaceStyle.light
    }
  }

  static func update(style: UIUserInterfaceStyle) {
    $current.mutate { value in
      value = switch style {
      case .dark:
          .dark
      default:
          .light
      }
    }
  }

  #elseif canImport(AppKit)
  var platformType: NSAppearance? {
    switch self {
    case .dark: return NSAppearance(named: .darkAqua)
    case .light: return NSAppearance(named: .aqua)
    }
  }

  static func update(appearance: NSAppearance) {
    // bestMatch resolves all dark variants (vibrantDark, accessibilityHighContrastDarkAqua, etc.)
    // to .darkAqua and all light variants to .aqua.
    let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    $current.mutate { $0 = isDark ? .dark : .light }
  }
  #endif
}
