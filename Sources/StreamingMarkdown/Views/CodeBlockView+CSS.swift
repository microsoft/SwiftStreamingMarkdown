import SwiftUI

extension CodeBlockView {
    static func syntaxHighlightingCss(for colorScheme: ColorScheme) -> String {
        colorScheme == .dark ? darkSyntaxHighlightingCss : lightSyntaxHighlightingCss
    }

    private static let darkSyntaxHighlightingCss = """
    code {
    color: #FCFAF7
    }

    .hljs-comment,
    .hljs-meta {
    color: #AA9C87
    }

    .hljs-built_in,
    .hljs-class .hljs-title {
    color: #FFC42F
    }

    .hljs-doctag,
    .hljs-formula,
    .hljs-keyword,
    .hljs-literal {
    color: #67ABF1
    }
    .hljs-addition,
    .hljs-attribute,
    .hljs-meta-string,
    .hljs-regexp,
    .hljs-string {
    color: #00B360
    }
    .hljs-attr,
    .hljs-number,
    .hljs-selector-attr,
    .hljs-selector-class,
    .hljs-selector-pseudo,
    .hljs-template-variable,
    .hljs-type,
    .hljs-variable {
    color: #F96C00
    }

    .hljs-bullet,
    .hljs-link,
    .hljs-selector-id,
    .hljs-symbol,
    .hljs-title {
    color: #E3B5FA
    }
    """

    private static let lightSyntaxHighlightingCss = """
    code {
    color: #24292F
    }

    .hljs-comment,
    .hljs-meta {
    color: #6A737D
    }

    .hljs-built_in,
    .hljs-class .hljs-title {
    color: #6F42C1
    }

    .hljs-doctag,
    .hljs-formula,
    .hljs-keyword,
    .hljs-literal {
    color: #D73A49
    }
    .hljs-addition,
    .hljs-attribute,
    .hljs-meta-string,
    .hljs-regexp,
    .hljs-string {
    color: #22863A
    }
    .hljs-attr,
    .hljs-number,
    .hljs-selector-attr,
    .hljs-selector-class,
    .hljs-selector-pseudo,
    .hljs-template-variable,
    .hljs-type,
    .hljs-variable {
    color: #E36209
    }

    .hljs-bullet,
    .hljs-link,
    .hljs-selector-id,
    .hljs-symbol,
    .hljs-title {
    color: #005CC5
    }
    """
}
