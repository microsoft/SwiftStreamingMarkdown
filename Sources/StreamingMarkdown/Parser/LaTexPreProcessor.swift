import Foundation
import RegexBuilder

protocol LaTexPreProcessor {
    func process(input: String) -> String
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

    func process(input: String) -> String {
        let result = processBlockMath(input: input)
        return processInlineMath(input: result)
    }

    func processBlockMath(input: String) -> String {
        var result = input
        result.replace(Self.dollarBlockMath, with: { match in
            let indentation = match[Self.latexOpenIndentation]
            let latex = match[Self.latexRef]
            return Self.buildCodeBlock(indentation: indentation, latex: latex)
        })

        result.replace(Self.slashBracketMath, with: { match in
            let indentation = match[Self.latexOpenIndentation]
            let latex = match[Self.latexRef]
            return Self.buildCodeBlock(indentation: indentation, latex: latex)
        })
        return result
    }

    func processInlineMath(input: String) -> String {
        input.replacing(Self.inlineParenthesisMath, with: { match in
            let latex = String(match[Self.latexRef]).filteringUnsupportedLatexSyntaxes()
            return "`\\(\(latex)\\)`"
        })
    }

    private static func buildCodeBlock(indentation: Substring, latex: Substring) -> String {
        let processedLatex = latex.trimmingCharacters(in: .newlines).filteringUnsupportedLatexSyntaxes()
        let nextLineIntendation = latex.hasPrefix(Self.newline) ? "" : indentation
        return "\(indentation)```\(Self.customCodeType)\(Self.newline)\(nextLineIntendation)\(processedLatex)\(Self.newline)\(indentation)```"
    }
}

extension String {
    func filteringUnsupportedLatexSyntaxes() -> String {
        self
            .strippingBoxedLatex()
            .replacingfrac()
            .replacingPrime()
            .replacingVector()
            .replacingImplies()
            .replacingHarpoons()
            .replacingDots()
            .strippingBracketSizeCommands()
    }

    func strippingBoxedLatex() -> String {
        replacing(LaTexPreProcessorImpl.boxedLatex, with: "")
    }

    func replacingfrac() -> String {
        replacing(LaTexPreProcessorImpl.dfracLatex, with: "\\frac")
            .replacing(LaTexPreProcessorImpl.tfracLatex, with: "\\frac")
    }

    func replacingPrime() -> String {
        replacing(LaTexPreProcessorImpl.primeLatex, with: "^\\prime")
    }

    func replacingVector() -> String {
        replacing(LaTexPreProcessorImpl.vectorLatex, with: "\\vec")
    }

    func replacingImplies() -> String {
        replacing(LaTexPreProcessorImpl.rightArrowLatex, with: "\\Rightarrow")
    }

    func replacingHarpoons() -> String {
        replacing(LaTexPreProcessorImpl.harpoonsLatex, with: "\\Leftrightarrow")
    }

    func replacingDots() -> String {
        replacing(LaTexPreProcessorImpl.dotsLatex, with: "\\ldots")
    }

    func strippingBracketSizeCommands() -> String {
        replacing(LaTexPreProcessorImpl.bracketSize, with: "")
    }
}
