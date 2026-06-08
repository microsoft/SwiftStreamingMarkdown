//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import UIKit

/// A single tappable item shown inside a `TextContextMenuGroup`.
public struct TextContextMenuItem: Identifiable, Hashable, Sendable {
  /// Stable identifier forwarded to `MarkdownListener.onContextMenuTap` when
  /// the item is selected.
  public let id: String
  /// User-visible title.
  public let title: String
  /// Optional secondary label rendered beneath `title`.
  public let subtitle: String?
  /// Optional leading icon.
  public let image: UIImage?

  /// Create a menu item with the supplied id, title, and optional metadata.
  public init(
    id: String,
    title: String,
    subtitle: String? = nil,
    image: UIImage? = nil
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.image = image
  }

  /// Equality compares `id`, `title`, and `subtitle` (image is ignored).
  public static func == (lhs: TextContextMenuItem, rhs: TextContextMenuItem) -> Bool {
    lhs.id == rhs.id &&
      lhs.title == rhs.title &&
      lhs.subtitle == rhs.subtitle
  }

  /// Hash mirrors `==`: combines `id`, `title`, and `subtitle`.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(title)
    hasher.combine(subtitle)
  }
}
