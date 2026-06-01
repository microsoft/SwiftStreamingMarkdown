//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown

/// Parse a given text into a markdown tree, represented by `Document`
public protocol MarkdownParser {

  /// Perform the parsing
  /// - Parameter text: The incoming text
  /// - Parameter option: The option for parsing
  /// - Returns: The parse result
  func parse(text: String, option: MarkdownParseOption) async -> MarkdownParseResult
}

extension MarkdownParser {

  public func parse(text: String) async -> Document {
    return await parse(text: text, option: .init(speculativeRewrite: false)).document
  }
}
