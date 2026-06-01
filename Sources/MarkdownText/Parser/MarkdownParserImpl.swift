//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown

public final class MarkdownParserImpl: MarkdownParser {

  private let rewriters: [MarkupPostParsingRewriter] = [
    PartialStrongMarkupPostParsingRewriter(),
    PartialTableMarkupPostParsingRewriter()
  ]

  private let latexPreprocessor: LaTexPreProcessor

  public init() {
    self.latexPreprocessor = LaTexPreProcessorImpl()
  }

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
