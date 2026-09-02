//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Markdown

/// The built-in `MarkdownParser` implementation.
public final class MarkdownParserImpl: MarkdownParser {

  private let rewriters: [MarkupPostParsingRewriter] = [
    PartialStrongMarkupPostParsingRewriter(),
    PartialTableMarkupPostParsingRewriter()
  ]

  private let imageBlockRewriter = ImageBlockMarkupPostParsingRewriter()

  private let latexPreprocessor: LaTexPreProcessor
  private let footnotePreprocessor: FootnotePreProcessor

  /// Create a new parser instance using the default LaTeX and footnote preprocessors.
  public init() {
    self.latexPreprocessor = LaTexPreProcessorImpl()
    self.footnotePreprocessor = FootnotePreProcessorImpl()
  }

  /// Parse `text` into a `MarkdownParseResult`. See `MarkdownParser.parse(text:option:)`.
  public func parse(text: String, option: MarkdownParseOption) async -> MarkdownParseResult {
    // Footnotes run after LaTeX so their fence guard also protects the code
    // blocks and inline code spans the LaTeX preprocessor emits.
    let targetString = footnotePreprocessor.process(
      input: latexPreprocessor.process(input: text, matchingRules: option.latexMatchingRules)
    )

    var result: MarkdownParseResult = MarkdownParseResult(
      document: Document(parsing: targetString),
      speculativeRewritten: false
    )

    if option.speculativeRewrite {
      for rewriter in rewriters {
        if let rewrittenDoc = rewriter.rewriteIfApplicable(document: result.document) {
          result = MarkdownParseResult(document: rewrittenDoc, speculativeRewritten: true)
        }
      }
    }

    if option.imageSupport {
      if let rewrittenDoc = imageBlockRewriter.rewriteIfApplicable(document: result.document) {
        result = MarkdownParseResult(
          document: rewrittenDoc,
          speculativeRewritten: result.speculativeRewritten
        )
      }
    }
    return result
  }
}
