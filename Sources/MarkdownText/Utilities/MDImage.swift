//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(UIKit)
import UIKit
/// Cross-platform image type. Resolves to `UIImage` on UIKit platforms and `NSImage` on AppKit platforms.
public typealias MDImage = UIImage
#elseif canImport(AppKit)
import AppKit
/// Cross-platform image type. Resolves to `UIImage` on UIKit platforms and `NSImage` on AppKit platforms.
public typealias MDImage = NSImage
#endif

extension MDImage {
  /// Creates a cross-platform image from an SF Symbol name.
  public convenience init?(sfSymbol name: String) {
    #if canImport(UIKit)
    self.init(systemName: name)
    #elseif canImport(AppKit)
    self.init(systemSymbolName: name, accessibilityDescription: nil)
    #endif
  }
}
