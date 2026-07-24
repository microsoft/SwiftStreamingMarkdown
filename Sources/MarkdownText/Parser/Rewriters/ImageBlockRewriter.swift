//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Markdown

final class ImageBlockRewriter: MarkupRewriter {

  func visitDocument(_ document: Document) -> Markup? {
    let paragraphChildren = document.children.filter { $0 is Paragraph }.compactMap { $0 as? Paragraph }
    var rewrittenParagraphs: [Int: [Paragraph]] = [:]
    for child in paragraphChildren {
      if let rewritten = rewriteParagraphIfApplicable(paragraph: child) {
        rewrittenParagraphs[child.indexInParent] = rewritten
      }
    }

    guard !rewrittenParagraphs.isEmpty else {
      return document
    }

    var mutableDocument = document
    let paragraphIndexesToReplace = rewrittenParagraphs.keys.sorted(by: { $0 >= $1 })
    for index in paragraphIndexesToReplace {
      if let nodes = rewrittenParagraphs[index] {
        mutableDocument.replaceChildrenInRange(index..<index+1, with: nodes)
      }
    }
    return mutableDocument
  }

  private func rewriteParagraphIfApplicable(paragraph: Paragraph) -> [Paragraph]? {
    guard paragraph.childCount > 1 else {
      return nil
    }

    guard paragraph.children.contains(where: { $0 is Image }) else {
      return nil
    }

    var rewrittenParagraphs: [Paragraph] = []
    var currentRun: [InlineMarkup] = []

    for child in paragraph.children {
      guard let inline = child as? InlineMarkup else {
        continue
      }
      if inline is Image {
        if !currentRun.isEmpty {
          rewrittenParagraphs.append(Paragraph(currentRun))
          currentRun = []
        }
        rewrittenParagraphs.append(Paragraph([inline]))
      } else {
        currentRun.append(inline)
      }
    }

    if !currentRun.isEmpty {
      rewrittenParagraphs.append(Paragraph(currentRun))
    }

    return rewrittenParagraphs
  }
}
