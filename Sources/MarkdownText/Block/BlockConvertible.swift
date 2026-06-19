//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
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

  func blockRenderables(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> [MarkdownRenderable] {
    if let paragraph = self as? Paragraph {
      return paragraph.convertRenderables(attributeContainer: attributeContainer, config: config)
    }

    if let blockDirective = self as? BlockDirective {
      return blockDirective.convertRenderables(attributeContainer: attributeContainer, config: config)
    }

    guard let convertible = self as? BlockConvertible else {
      return []
    }

    return [convertible.convert(attributeContainer: attributeContainer, config: config)]
  }
}
