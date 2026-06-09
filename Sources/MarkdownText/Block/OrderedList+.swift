//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import Markdown
import SwiftUI

extension OrderedList: BlockConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> MarkdownRenderable {
    let nodes: [ListItem] = self.children.compactMap { $0 as? ListItem }
    let items: [MarkdownListItem] = nodes.map { listItem in
      MarkdownListItem(children: listItem.blockConvertibleChildren.map { $0.convert(attributeContainer: attributeContainer, config: config)},
                       startsWithBold: listItem.startsWithBold)
    }
    return .orderedList(id: self.id, items: items)
  }
}
