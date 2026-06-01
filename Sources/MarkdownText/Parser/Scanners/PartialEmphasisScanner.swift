//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown

public final class PartialEmphasisScanner: MarkupScanner {

  public init() {}

  public func scan(document: Document) -> Text? {
    let result = document.rightMostDescendant
    if let textNode = result as? Text {
      return textNode
    }

    /// Handling a special case if suffix is a table. In this case we would need to ignore the trailing `Cell` nodes
    ///
    /// | Month | Savings |
    /// |  --------  |  -------  |
    /// | **Ja
    ///
    /// The above snippet, after parsing would produce an empty `Cell` at the right most descendant, which is not what we want.
    if let cellNode = result as? Table.Cell, let row = cellNode.parent as? Table.Row {
      let lastNonEmptyCell = row.children.compactMap { $0 as? Table.Cell }.last { cell in
        cell.childCount != 0
      }
      if let textNode = lastNonEmptyCell?.rightMostDescendant as? Text {
        return textNode
      }
    }
    return nil
  }
}

extension Markup {

  var rightMostDescendant: Markup? {
    var result: Markup = self
    while result.childCount > 0 {
      if let rightMostChild = result.child(at: result.childCount - 1) {
        result = rightMostChild
      } else {
        break
      }
    }
    return result
  }
}
