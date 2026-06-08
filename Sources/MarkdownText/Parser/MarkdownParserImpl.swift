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

  private let latexPreprocessor: LaTexPreProcessor

  /// Create a new parser instance using the default LaTeX preprocessor.
  public init() {
    self.latexPreprocessor = LaTexPreProcessorImpl()
  }

  /// Parse `text` into a `MarkdownParseResult`. See `MarkdownParser.parse(text:option:)`.
  public func parse(text: String, option: MarkdownParseOption) async -> MarkdownParseResult {
    let targetString = latexPreprocessor.process(input: text, matchingRules: option.latexMatchingRules)

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
    return result
  }
}
