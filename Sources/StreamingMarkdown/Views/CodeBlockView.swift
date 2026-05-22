import SwiftUI
import HighlightSwift

#if canImport(UIKit)
import UIKit
#endif

private actor CodeBlockHighlightTaskManager {
    static let shared = CodeBlockHighlightTaskManager()

    private let highlighter = Highlight()

    func highlightedText(for code: String, css: String) async -> AttributedString? {
        try? await highlighter.attributedText(
            code,
            colors: .custom(css: css, background: "")
        )
    }
}

struct CodeBlockView: View {
    let code: String
    let language: String?
    let configuration: StreamingMarkdownConfiguration
    let actionHandlers: MarkdownActionHandlers
    @Environment(\.colorScheme) private var colorScheme
    @State private var copied = false
    @State private var copyFeedbackGeneration = 0
    @State private var highlightedCode: AttributedString?
    @State private var highlightedCodeSource: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(language?.isEmpty == false ? language! : "Code")
                    .font(configuration.theme.captionFont)
                    .foregroundStyle(configuration.theme.secondaryTextColor)
                Spacer()
                Button {
                    copy(code)
                    actionHandlers.onCodeCopy?(code, language)
                    actionHandlers.onEvent?(.codeCopied(language: language))
                    showCopiedFeedback()
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "doc.on.doc")
                        Text(copied ? "Copied" : "Copy")
                    }
                }
                .font(configuration.theme.captionFont)
                .foregroundStyle(configuration.theme.codeActionForeground)
                .buttonStyle(.plain)
                .accessibilityLabel(copied ? "Code copied" : "Copy code")
            }
            .padding(.horizontal, configuration.designSystem.layout.codeInnerPadding)
            .padding(.vertical, 8)
            .background(configuration.theme.codeBlockBackground)

            ScrollView(.horizontal) {
                codeText
                    .padding(configuration.designSystem.layout.codeInnerPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(configuration.theme.codeBackground)
        }
        .background(
            configuration.theme.codeBlockBackground,
            in: RoundedRectangle(cornerRadius: configuration.designSystem.layout.codeCornerRadius)
        )
        .clipShape(RoundedRectangle(cornerRadius: configuration.designSystem.layout.codeCornerRadius))
        .padding(configuration.designSystem.layout.codeOuterPadding)
        .task(id: highlightTaskID) {
            await updateHighlightedCode()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(codeAccessibilityLabel)
    }

    private var codeText: some View {
        Group {
            if let highlighted = configuration.syntaxHighlighter?(code, language) {
                Text(highlighted)
                    .font(configuration.theme.codeFont)
            } else if let highlightedCode, highlightedCodeSource == code {
                Text(highlightedCode)
                    .font(configuration.theme.codeFont)
            } else {
                Text(code)
                    .font(configuration.theme.codeFont)
                    .foregroundStyle(configuration.theme.codeForeground)
            }
        }
        .textSelection(.enabled)
        .accessibilityLabel(code)
    }

    private var codeAccessibilityLabel: String {
        if let language, !language.isEmpty {
            return "\(language) code block"
        }
        return "Code block"
    }

    private var highlightTaskID: String {
        "\(language ?? "")\u{0}\(colorScheme == .dark ? "dark" : "light")\u{0}\(code)"
    }

    private func copy(_ string: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = string
        #endif
    }

    @MainActor
    private func updateHighlightedCode() async {
        guard configuration.syntaxHighlighter?(code, language) == nil else {
            highlightedCode = nil
            highlightedCodeSource = nil
            return
        }
        let source = code
        let css = CodeBlockView.syntaxHighlightingCss(for: colorScheme)
        try? await Task.sleep(nanoseconds: 180_000_000)
        guard !Task.isCancelled else { return }
        let highlighted = await CodeBlockHighlightTaskManager.shared.highlightedText(for: source, css: css)
        guard !Task.isCancelled else { return }
        highlightedCode = highlighted
        highlightedCodeSource = source
    }

    private func showCopiedFeedback() {
        copied = true
        copyFeedbackGeneration += 1
        let generation = copyFeedbackGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if copyFeedbackGeneration == generation {
                copied = false
            }
        }
    }
}
