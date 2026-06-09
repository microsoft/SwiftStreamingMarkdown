//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import Markdown
import SwiftUI

extension UnorderedList: BlockConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> MarkdownRenderable {
    let nodes: [ListItem] = self.children.compactMap { $0 as? ListItem }
    var items: [MarkdownListItem] = []
    for listItem in nodes {
      items.append(MarkdownListItem(children: listItem.blockConvertibleChildren.map { $0.convert(attributeContainer: attributeContainer, config: config) },
                                    startsWithBold: listItem.startsWithBold ))
    }
    return .unorderedList(id: self.id, items: items, nestedLevel: self.nestedLevel)
  }

  private var nestedLevel: Int {
    var nestedLevel = 0
    var currentParent = self.parent
    while currentParent != nil {
      if currentParent is UnorderedList {
        nestedLevel += 1
      }
      currentParent = currentParent?.parent
    }
    return nestedLevel
  }
}
