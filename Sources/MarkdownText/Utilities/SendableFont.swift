//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A `Sendable` wrapper around `MDFont` (`UIFont`/`NSFont`).
///
/// `UIFont`/`NSFont` are effectively immutable and safe to share across
/// concurrency domains, but the SDK does not mark them as `Sendable`. Storing a
/// font in this value type keeps the unchecked assertion in a single, auditable
/// place so font-holding configuration types can be plainly `Sendable` without
/// leaking a retroactive `Sendable` conformance onto the platform font types.
struct SendableFont: Hashable, @unchecked Sendable {
  /// The wrapped platform font.
  let font: MDFont

  init(_ font: MDFont) {
    self.font = font
  }
}
