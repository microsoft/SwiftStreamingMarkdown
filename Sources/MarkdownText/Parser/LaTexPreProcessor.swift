//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import RegexBuilder

/// Pre-process the inline and block latex in markdown.
/// This is a less heavy-weight approach than forking commonmark-gfm and swift-markdown to support parsing latex nodes.
protocol LaTexPreProcessor {
  func process(input: String, matchingRules: [MarkdownParseOption.LatexMatching]) -> String
}

extension LaTexPreProcessor {
  /// Convenience overload that enables every supported matching rule.
  func process(input: String) -> String {
    return process(input: input, matchingRules: MarkdownParseOption.LatexMatching.allCases)
  }
}

final class LaTexPreProcessorImpl: LaTexPreProcessor {

  static let latexRef = Reference(Substring.self)
  static let latexOpenIndentation = Reference(Substring.self)

  static let dollarBlockMath = Regex {
    Anchor.startOfLine
    Capture(as: latexOpenIndentation) {
      ZeroOrMore(.horizontalWhitespace)
    }
    "$$"
    Capture(as: latexRef) {
      OneOrMore(.any, .reluctant)
    }
    ZeroOrMore(.horizontalWhitespace)
    "$$"
    ZeroOrMore(.horizontalWhitespace)
    Anchor.endOfLine
  }

  static let slashBracketMath = Regex {
    Anchor.startOfLine
    Capture(as: latexOpenIndentation) {
      ZeroOrMore(.horizontalWhitespace)
    }
    "\\["
    Capture(as: latexRef) {
      OneOrMore(.any, .reluctant)
    }
    ZeroOrMore(.horizontalWhitespace)
    "\\]"
    ZeroOrMore(.horizontalWhitespace)
    Anchor.endOfLine
  }

  static let inlineParenthesisMath = Regex {
    "\\("
    Capture(as: latexRef) {
      OneOrMore(.any, .reluctant)
    }
    "\\)"
  }

  static let boxedLatex = Regex {
    Capture {
      "\\boxed"
    }
  }

  static let dfracLatex = Regex {
    Capture {
      "\\dfrac"
    }
  }

  static let tfracLatex = Regex {
    Capture {
      "\\tfrac"
    }
  }

  static let bracketSize = Regex {
    Capture {
      ChoiceOf {
        "\\bigl"
        "\\biggl"
        "\\Bigl"
        "\\Biggl"
        "\\bigr"
        "\\biggr"
        "\\Bigr"
        "\\Biggr"
        "\\big"
      }
    }
  }

  static let primeLatex = Regex {
    Capture {
      "'"
    }
  }

  static let vectorLatex = Regex {
    Capture {
      "\\overrightarrow"
    }
  }

  static let rightArrowLatex = Regex {
    Capture {
      "\\implies"
    }
  }

  static let harpoonsLatex = Regex {
    Capture {
      "\\rightleftharpoons"
    }
  }

  static let dotsLatex = Regex {
    Capture {
      "\\dots"
    }
  }

  static let customCodeType = "blockmath"
  static let inlineCodePrefix = "\\("
  static let inlineCodeSuffix = "\\)"
  static let newline = "\n"

  init() {}

  func process(input: String, matchingRules: [MarkdownParseOption.LatexMatching]) -> String {
    let rules = Set(matchingRules)
    let result = processBlockMath(input: input, rules: rules)
    return processInlineMath(input: result, rules: rules)
  }

  /// This replace block math with a special code block node. By treating it as a code block it will avoid over escaping characters within latex.
  func processBlockMath(input: String, rules: Set<MarkdownParseOption.LatexMatching>) -> String {
    var result = input
    if rules.contains(.blockDollar) {
      result.replace(Self.dollarBlockMath, with: { match in
        let indentation = match[Self.latexOpenIndentation]
        let latex = match[Self.latexRef]
        return Self.buildCodeBlock(indentation: indentation, latex: latex)
      })
    }

    if rules.contains(.blockSlashBracket) {
      result.replace(Self.slashBracketMath, with: { match in
        let indentation = match[Self.latexOpenIndentation]
        let latex = match[Self.latexRef]
        return Self.buildCodeBlock(indentation: indentation, latex: latex)
      })
    }
    return result
  }

  /// This wraps inline math as inline code to avoid over-unescaping issue
  func processInlineMath(input: String, rules: Set<MarkdownParseOption.LatexMatching>) -> String {
    guard rules.contains(.inlineSlashBracket) else { return input }
    return input.replacing(Self.inlineParenthesisMath, with: { match in
      let latex = String(match[Self.latexRef]).filteringUnsupportedSyntaxes()
      return "`\\(\(latex)\\)`"
    })
  }

  // MARK: - Convenience overloads (default to every supported rule)

  func processBlockMath(input: String) -> String {
    return processBlockMath(input: input, rules: Set(MarkdownParseOption.LatexMatching.allCases))
  }

  func processInlineMath(input: String) -> String {
    return processInlineMath(input: input, rules: Set(MarkdownParseOption.LatexMatching.allCases))
  }

  private static func buildCodeBlock(indentation: Substring, latex: Substring) -> String {
    let processedLatex = latex.trimmingCharacters(in: .newlines).filteringUnsupportedSyntaxes()
    let nextLineIntendation = latex.hasPrefix(Self.newline) ? "" : indentation
    return "\(indentation)```\(Self.customCodeType)\(Self.newline)\(nextLineIntendation)\(processedLatex)\(Self.newline)\(indentation)```"
  }
}

extension String {

  func filteringUnsupportedSyntaxes() -> String {
    return self
      .strippingBoxedLatex()
      .replacingfrac()
      .replacingPrime()
      .replacingVector()
      .replacingImplies()
      .replacingHarpoons()
      .replacingDots()
      .strippingBracketSizeCommands()
  }

  /// This strips "\boxed" string from a given latex. This is because our rendering engine does not support \boxed{...} yet.
  func strippingBoxedLatex() -> String {
    return self.replacing(LaTexPreProcessorImpl.boxedLatex, with: "")
  }

  /// Replacing `dfrac` and `tfac` which is unsupported into simple `frac`
  func replacingfrac() -> String {
    return self
      .replacing(LaTexPreProcessorImpl.dfracLatex, with: "\\frac")
      .replacing(LaTexPreProcessorImpl.tfracLatex, with: "\\frac")
  }

  /// Replacing `'` which is unsupported into `^prime`
  func replacingPrime() -> String {
    return self.replacing(LaTexPreProcessorImpl.primeLatex, with: "^\\prime")
  }

  /// Replacing `overrightarrow` which is unsupported into `vec`
  func replacingVector() -> String {
    return self.replacing(LaTexPreProcessorImpl.vectorLatex, with: "\\vec")
  }

  /// Replacing `implies` which is unsupported into `Rightarrow`
  func replacingImplies() -> String {
    return self.replacing(LaTexPreProcessorImpl.rightArrowLatex, with: "\\Rightarrow")
  }

  /// Replacing `harpoons` which is unsupported into `Leftrightarrow`
  func replacingHarpoons() -> String {
    return self.replacing(LaTexPreProcessorImpl.harpoonsLatex, with: "\\Leftrightarrow")
  }

  /// Replacing `dots` which is unsupported into `ldots`
  func replacingDots() -> String {
    return self.replacing(LaTexPreProcessorImpl.dotsLatex, with: "\\ldots")
  }

  /// Stripping commands to specify bracket sizes(`\Biggl` etc) which is unsupported
  func strippingBracketSizeCommands() -> String {
    return self.replacing(LaTexPreProcessorImpl.bracketSize, with: "")
  }
}
