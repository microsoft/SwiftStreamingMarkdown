//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

/// Options that control how a `MarkdownParser` processes input text.
public struct MarkdownParseOption {
  /// Whether to speculative rewrite the markdown if it is considered as incomplete
  /// Such as a string ends with a partial table or partial emphasis
  public let speculativeRewrite: Bool

  /// Specify how to parse latex
  public let latexMatchingRules: [LatexMatching]

  /// Create a new parse option.
  /// - Parameters:
  ///   - speculativeRewrite: See `speculativeRewrite`.
  ///   - latexMatchingRules: See `latexMatchingRules`. Defaults to every supported rule.
  public init(speculativeRewrite: Bool, latexMatchingRules: [LatexMatching] = LatexMatching.allCases) {
    self.speculativeRewrite = speculativeRewrite
    self.latexMatchingRules = latexMatchingRules
  }

  /// The set of delimiter forms the LaTeX preprocessor will recognize. Omitting
  /// a case leaves text matching that delimiter as plain markdown.
  public enum LatexMatching: String, Hashable, CaseIterable {
    /// Inline LaTeX delimited by `\(` … `\)`.
    case inlineSlashBracket
    /// Block LaTeX delimited by `$$` … `$$`.
    case blockDollar
    /// Block LaTeX delimited by `\[` … `\]`.
    case blockSlashBracket
  }
}
