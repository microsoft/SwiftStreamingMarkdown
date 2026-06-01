//
//  Copyright © 2025 Microsoft. All rights reserved.
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
