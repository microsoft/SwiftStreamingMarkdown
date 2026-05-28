//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import UIKit

public struct TextContextMenuItem: Identifiable, Hashable, Sendable {
  public let id: String
  public let title: String
  public let subtitle: String?
  public let image: UIImage?

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

  public static func == (lhs: TextContextMenuItem, rhs: TextContextMenuItem) -> Bool {
    lhs.id == rhs.id &&
      lhs.title == rhs.title &&
      lhs.subtitle == rhs.subtitle
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(title)
    hasher.combine(subtitle)
  }
}
