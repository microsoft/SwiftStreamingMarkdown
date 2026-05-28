//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import UIKit

public struct TextContextMenuGroup: Hashable, Sendable {
  public let title: String?
  public let image: UIImage?
  public let displayInline: Bool
  public let items: [TextContextMenuItem]

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

  public static func == (lhs: TextContextMenuGroup, rhs: TextContextMenuGroup) -> Bool {
    lhs.title == rhs.title && lhs.displayInline == rhs.displayInline && lhs.items == rhs.items
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(title)
    hasher.combine(displayInline)
    hasher.combine(items)
  }
}
