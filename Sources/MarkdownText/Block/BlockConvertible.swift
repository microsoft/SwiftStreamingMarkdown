//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown
import SwiftUI

/// A markdown block that can be converted into `MarkdownRenderable`

protocol BlockConvertible {

  /// Convert into `MarkdownRenderable`
  /// - Parameter attributeContainer: The inherited attributes
  /// - Parameter config: The mark down rendering config used to override fonts & text color if needed.
  /// - Returns: A `MarkdownRenderable` that is ready to be rendered by Views.
  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> MarkdownRenderable
}

extension Markup {
  var blockConvertibleChildren: [BlockConvertible] {
    return self.children.compactMap { $0 as? BlockConvertible }
  }
}
