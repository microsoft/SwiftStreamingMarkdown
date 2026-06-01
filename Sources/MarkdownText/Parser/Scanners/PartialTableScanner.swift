//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown

// swiftlint:disable unused_optional_binding
public final class PartialTableScanner: MarkupScanner {

  public init() {}

  public func scan(document: Document) -> Paragraph? {
    var result: Markup = document
    while result.childCount > 0 {
      if let rightMostChild = result.child(at: result.childCount - 1) {
        result = rightMostChild
      } else {
        break
      }
    }

    guard let paragraph = result.parent as? Paragraph else {
      return nil
    }

    /// Only with table header
    /// Example:
    ///
    /// | Month | Savings | Column3 |
    if paragraph.childCount == 1, let text = paragraph.child(at: 0) as? Text {
      if text.string.hasPrefix("|") {
        return paragraph
      }
    }

    /// With header and line break
    /// Example:
    ///
    /// | Month | Savings | Column3 |
    ///
    if paragraph.childCount == 2 {
      if let text = paragraph.child(at: 0) as? Text, let _ = paragraph.child(at: 1) as? SoftBreak {
        if text.string.hasPrefix("|") {
          return paragraph
        }
      }
    }

    /// With table, line break and a partial delimiter
    /// Example
    ///
    /// | Month | Savings | Column3 |
    /// | :--
    if paragraph.childCount == 3 {
      if let possibleHeader = paragraph.child(at: 0) as? Text, let _ = paragraph.child(at: 1) as? SoftBreak, let possibleDelimiter = paragraph.child(at: 2) as? Text {
        if possibleHeader.string.hasPrefix("|") && possibleDelimiter.string.hasPrefix("|") {
          return paragraph
        }
      }
    }

    return nil
  }
}
// swiftlint:enable unused_optional_binding
