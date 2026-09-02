//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(UIKit)
import UIKit
/// Cross-platform font type. Resolves to `UIFont` on UIKit platforms and `NSFont` on AppKit platforms.
public typealias MDFont = UIFont
#elseif canImport(AppKit)
import AppKit
/// Cross-platform font type. Resolves to `UIFont` on UIKit platforms and `NSFont` on AppKit platforms.
public typealias MDFont = NSFont
#endif

extension MDFont {
  /// Returns a copy of this font with the given point size.
  func resized(to size: CGFloat) -> MDFont {
    #if canImport(UIKit)
    return withSize(size)
    #elseif canImport(AppKit)
    return NSFont(descriptor: fontDescriptor, size: size) ?? self
    #endif
  }
}
