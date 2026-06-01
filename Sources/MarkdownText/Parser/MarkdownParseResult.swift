//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown

/// The output of `MarkdownParser.parse(text:option:)`.
public struct MarkdownParseResult {
  /// The parsed markdown `Document` tree.
  public let document: Document
  /// `true` if the parser applied a speculative rewrite (e.g. completing a
  /// partial table or emphasis) before returning the document.
  public let speculativeRewritten: Bool
}
