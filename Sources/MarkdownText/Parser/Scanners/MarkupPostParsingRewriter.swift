//
//  Copyright © 2025 Microsoft. All rights reserved.
//

//
//  MarkupPostParsingRewriter.swift
//  MarkdownText
//
//  Created by Jun Yan on 6/13/25.
//
import Markdown

protocol MarkupPostParsingRewriter {

  func rewriteIfApplicable(document: Document) -> Document?
}

final class PartialStrongMarkupPostParsingRewriter: MarkupPostParsingRewriter {

  private let scanner: PartialEmphasisScanner

  init() {
    self.scanner = PartialEmphasisScanner()
  }

  func rewriteIfApplicable(document: Document) -> Document? {
    guard let targetNode = scanner.scan(document: document) else {
      return nil
    }

    var rewriter = PartialEmphasisRewriter(targetNode: targetNode)
    return rewriter.visit(document) as? Document
  }
}

final class PartialTableMarkupPostParsingRewriter: MarkupPostParsingRewriter {

  private let scanner: PartialTableScanner

  init() {
    self.scanner = PartialTableScanner()
  }

  func rewriteIfApplicable(document: Document) -> Document? {
    guard let targetNode = scanner.scan(document: document) else {
      return nil
    }

    var rewriter = PartialTableRewriter(targetParagraph: targetNode)
    return rewriter.visit(document) as? Document
  }
}
