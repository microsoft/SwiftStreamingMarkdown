//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
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

/// Rewrites supported inline raw-HTML tags into Markdown equivalents. See
/// `InlineHTMLRewriter`. Runs unconditionally: it only touches subtrees that
/// contain `InlineHTML` nodes and is not a speculative repair.
final class InlineHTMLMarkupPostParsingRewriter: MarkupPostParsingRewriter {

  func rewriteIfApplicable(document: Document) -> Document? {
    guard InlineHTMLRewriter.containsInlineHTML(document) else { return nil }
    var rewriter = InlineHTMLRewriter()
    return rewriter.visit(document) as? Document
  }
}

/// Rewrites paired inline delimiter runs into `InlineAttributes` nodes. See
/// `InlineDelimiterRewriter`. Runs unconditionally: it only touches subtrees
/// with a `Text` node containing a spec marker and is not a speculative
/// repair.
final class InlineDelimiterMarkupPostParsingRewriter: MarkupPostParsingRewriter {

  private static let specs: [InlineDelimiterRewriter.DelimiterSpec] = [.highlight, .superscript]

  func rewriteIfApplicable(document: Document) -> Document? {
    guard InlineDelimiterRewriter.containsDelimiter(document, specs: Self.specs) else { return nil }
    var rewriter = InlineDelimiterRewriter(specs: Self.specs)
    return rewriter.visit(document) as? Document
  }
}

/// Splits paragraphs that contain images into block-level image-only
/// paragraphs. See `ImageBlockRewriter`.
///
/// - Important: Experimental. Only applied when `MarkdownParseOption.imageSupport`
///   is enabled.
final class ImageBlockMarkupPostParsingRewriter: MarkupPostParsingRewriter {

  func rewriteIfApplicable(document: Document) -> Document? {
    var rewriter = ImageBlockRewriter()
    return rewriter.visit(document) as? Document
  }
}
