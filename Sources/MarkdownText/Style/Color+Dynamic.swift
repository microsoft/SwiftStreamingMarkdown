//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
  /// Creates a dynamic color that resolves to different values in light and dark mode.
  public static func dynamic(light: Color, dark: Color) -> Color {
    #if canImport(UIKit)
    Color(UIColor { traitCollection in
      traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
    })
    #elseif canImport(AppKit)
    Color(nsColor: NSColor(name: nil) { appearance in
      appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        ? NSColor(dark) : NSColor(light)
    })
    #endif
  }

  /// The system background color, resolving to the appropriate platform value.
  public static var systemBackground: Color {
    #if canImport(UIKit)
    Color(.systemBackground)
    #elseif canImport(AppKit)
    Color(nsColor: .windowBackgroundColor)
    #endif
  }
}
