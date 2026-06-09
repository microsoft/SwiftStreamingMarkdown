//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
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

  /// Convenience overload that parses `text` and produces a fully laid-out
  /// `RenderableDocument` ready to hand to `DocumentView`.
  /// - Parameters:
  ///   - text: The incoming text.
  ///   - config: Render configuration applied when building the renderable.
  /// - Returns: A `RenderableDocument` built from the parsed `Document`.
  public func parse(text: String, config: MarkdownRenderConfig) async -> RenderableDocument {
    let document = await parse(text: text)
    return await RenderableDocument(document: document, config: config)
  }
}
