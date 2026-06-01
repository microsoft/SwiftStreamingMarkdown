//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown

public final class PartialTableRewriter: MarkupRewriter {

  private let targetParagraph: Paragraph

  init(targetParagraph: Paragraph) {
    self.targetParagraph = targetParagraph
  }

  public func visitParagraph(_ paragraph: Paragraph) -> Markup? {
    if paragraph.isIdentical(to: targetParagraph) {
      var mutabledParagraph = paragraph
      mutabledParagraph.replaceChildrenInRange(0..<paragraph.childCount, with: [])
      return mutabledParagraph
    } else {
      return paragraph
    }
  }
}
