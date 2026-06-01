//
//  Copyright © 2025 Microsoft. All rights reserved.
//

public struct MarkdownParseOption {
  /// Whether to speculative rewrite the markdown if it is considered as incomplete
  /// Such as a string ends with a partial table or partial emphasis
  public let speculativeRewrite: Bool
  
  /// Specify how to parse latex
  public let latexMatchingRules: [LatexMatching]

  public init(speculativeRewrite: Bool, latexMatchingRules: [LatexMatching] = LatexMatching.allCases) {
    self.speculativeRewrite = speculativeRewrite
    self.latexMatchingRules = latexMatchingRules
  }
  
  public enum LatexMatching: String, Hashable, CaseIterable {
    case inlineSlashBracket // \(<inline latex>\)
    case blockDollar // $$ <block latex> $$
    case blockSlashBracket // \[ <block latex> \]
  }
}
