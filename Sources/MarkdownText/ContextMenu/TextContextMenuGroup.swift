//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import UIKit

/// A grouping of related `TextContextMenuItem`s rendered as either a submenu
/// or an inline section within `TextContextMenu`.
public struct TextContextMenuGroup: Hashable, Sendable {
  /// Submenu title, or `nil` for an inline/untitled group.
  public let title: String?
  /// Optional icon shown next to the title.
  public let image: UIImage?
  /// When `true`, the group renders inline rather than as a submenu.
  public let displayInline: Bool
  /// Ordered items that belong to this group.
  public let items: [TextContextMenuItem]

  /// Create a group from the supplied title, icon, layout flag, and items.
  public init(
    title: String?,
    image: UIImage?,
    displayInline: Bool,
    items: [TextContextMenuItem]
  ) {
    self.title = title
    self.image = image
    self.displayInline = displayInline
    self.items = items
  }

  /// Equality compares `title`, `displayInline`, and `items` (image is ignored
  /// because `UIImage` is not value-equatable in a useful way).
  public static func == (lhs: TextContextMenuGroup, rhs: TextContextMenuGroup) -> Bool {
    lhs.title == rhs.title && lhs.displayInline == rhs.displayInline && lhs.items == rhs.items
  }

  /// Hash mirrors `==`: combines `title`, `displayInline`, and `items`.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(title)
    hasher.combine(displayInline)
    hasher.combine(items)
  }
}
