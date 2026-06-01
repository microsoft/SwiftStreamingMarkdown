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

  /// Convenience overload that parses `text` with all options disabled and
  /// returns only the parsed `Document`.
  /// - Parameter text: The incoming text
  /// - Returns: The parsed markdown `Document` tree
  public func parse(text: String) async -> Document {
    return await parse(text: text, option: .init(speculativeRewrite: false)).document
  }
}
