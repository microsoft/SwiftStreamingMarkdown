import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct InlineRunsView: View {
    let runs: [InlineRun]
    let configuration: StreamingMarkdownConfiguration
    let actionHandlers: MarkdownActionHandlers
    var textFont: Font?
    var strongTextFont: Font?
    var emphasisTextFont: Font?

    var body: some View {
        InlineFlowLayout(
            spacing: configuration.designSystem.layout.inlineSpacing,
            lineSpacing: configuration.designSystem.layout.inlineLineSpacing
        ) {
            ForEach(Array(displayRuns.enumerated()), id: \.offset) { _, run in
                InlineRunView(
                    run: run,
                    configuration: configuration,
                    actionHandlers: actionHandlers,
                    textFont: resolvedTextFont,
                    strongTextFont: strongTextFont ?? resolvedTextFont.bold(),
                    emphasisTextFont: emphasisTextFont ?? resolvedTextFont.italic()
                )
            }
        }
        .font(resolvedTextFont)
        .foregroundStyle(configuration.theme.textColor)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var displayRuns: [InlineDisplayRun] {
        var result: [InlineDisplayRun] = []
        var index = runs.startIndex
        while index < runs.endIndex {
            if case .collapsed = configuration.citationPresentation,
               case .citation(_, let firstCitation) = runs[index] {
                var citations = [firstCitation]
                var nextIndex = runs.index(after: index)
                while nextIndex < runs.endIndex {
                    if case .citation(_, let citation) = runs[nextIndex] {
                        citations.append(citation)
                        nextIndex = runs.index(after: nextIndex)
                    } else {
                        break
                    }
                }
                result.append(.citationGroup(citations))
                index = nextIndex
            } else {
                result.append(.run(runs[index]))
                index = runs.index(after: index)
            }
        }
        return result
    }

    private var resolvedTextFont: Font {
        textFont ?? configuration.theme.textFont
    }
}

private enum InlineDisplayRun {
    case run(InlineRun)
    case citationGroup([Citation])
}

private struct InlineRunView: View {
    let run: InlineDisplayRun
    let configuration: StreamingMarkdownConfiguration
    let actionHandlers: MarkdownActionHandlers
    let textFont: Font
    let strongTextFont: Font
    let emphasisTextFont: Font

    var body: some View {
        switch run {
        case .run(let run):
            inlineRunView(run)
        case .citationGroup(let citations):
            CitationGroupView(citations: citations, configuration: configuration, actionHandlers: actionHandlers)
        }
    }

    @ViewBuilder
    private func inlineRunView(_ run: InlineRun) -> some View {
        switch run {
        case .text(_, let text):
            FadingInlineText(text: text, font: textFont, configuration: configuration)
        case .strong(_, let text):
            FadingInlineText(text: text, font: strongTextFont, configuration: configuration)
        case .emphasis(_, let text):
            FadingInlineText(text: text, font: emphasisTextFont, configuration: configuration)
        case .strikethrough(_, let text):
            FadingInlineText(text: text, font: textFont, configuration: configuration, strikethrough: true)
        case .code(_, let code):
            Text(code)
                .font(configuration.theme.codeFont)
                .padding(.horizontal, configuration.designSystem.layout.inlineCodeHorizontalPadding)
                .padding(.vertical, configuration.designSystem.layout.inlineCodeVerticalPadding)
                .foregroundStyle(configuration.theme.codeForeground)
                .background(
                    configuration.theme.codeBackground,
                    in: RoundedRectangle(cornerRadius: configuration.designSystem.layout.inlineCodeCornerRadius)
                )
        case .link(_, let title, let url):
            Button {
                actionHandlers.onLinkTap?(url)
                actionHandlers.onEvent?(.linkTapped(url))
            } label: {
                Text(title)
                    .foregroundStyle(configuration.theme.linkColor)
                    .underline()
            }
            .buttonStyle(.plain)
            .accessibilityHint(url.absoluteString)
        case .citation(_, let citation):
            CitationButton(citation: citation, configuration: configuration, actionHandlers: actionHandlers)
        case .inlineMath(_, let latex):
            InlineMathView(latex: latex, color: configuration.theme.mathColor)
        }
    }
}

private struct CitationButton: View {
    let citation: Citation
    let configuration: StreamingMarkdownConfiguration
    let actionHandlers: MarkdownActionHandlers

    var body: some View {
        Button {
            actionHandlers.onCitationTap?(citation)
            actionHandlers.onEvent?(.citationTapped(citation))
        } label: {
            switch configuration.citationPresentation {
            #if canImport(UIKit)
            case .uikitPills:
                UIKitCitationPill(title: citation.title, configuration: configuration)
            #endif
            case .inlinePills, .collapsed(_):
                citationLabel(citation.title)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(citation.accessibilityLabel)
    }

    private func citationLabel(_ title: String) -> some View {
        Text(title)
            .font(configuration.theme.citationFont)
            .padding(.horizontal, configuration.designSystem.layout.citationHorizontalPadding)
            .padding(.vertical, configuration.designSystem.layout.citationVerticalPadding)
            .foregroundStyle(configuration.theme.citationForeground)
            .background(configuration.theme.citationBackground, in: Capsule())
    }
}

private struct CitationGroupView: View {
    let citations: [Citation]
    let configuration: StreamingMarkdownConfiguration
    let actionHandlers: MarkdownActionHandlers

    var body: some View {
        let title = groupTitle
        Button {
            actionHandlers.onCitationGroupTap?(citations)
            if let first = citations.first {
                actionHandlers.onCitationTap?(first)
            }
            actionHandlers.onEvent?(.citationGroupTapped(citations))
        } label: {
            Text(title)
                .font(configuration.theme.citationFont)
                .padding(.horizontal, configuration.designSystem.layout.citationHorizontalPadding)
                .padding(.vertical, configuration.designSystem.layout.citationVerticalPadding)
                .foregroundStyle(configuration.theme.citationForeground)
                .background(configuration.theme.citationBackground, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(citations.map(\.accessibilityLabel).joined(separator: ", "))
    }

    private var groupTitle: String {
        guard !citations.isEmpty else { return "" }
        let maxVisible: Int
        if case .collapsed(let configuredMaxVisible) = configuration.citationPresentation {
            maxVisible = max(1, configuredMaxVisible)
        } else {
            maxVisible = 1
        }
        let visible = citations.prefix(maxVisible).map(\.title).joined(separator: ", ")
        let remaining = citations.count - min(citations.count, maxVisible)
        return remaining > 0 ? "\(visible) +\(remaining)" : visible
    }
}

#if canImport(UIKit)
private struct UIKitCitationPill: UIViewRepresentable {
    let title: String
    let configuration: StreamingMarkdownConfiguration

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .center
        label.layer.masksToBounds = true
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        label.text = title
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textColor = UIColor(configuration.theme.citationForeground)
        label.backgroundColor = UIColor(configuration.theme.citationBackground)
        label.layer.cornerRadius = 10
        label.layoutMargins = UIEdgeInsets(
            top: configuration.designSystem.layout.citationVerticalPadding,
            left: configuration.designSystem.layout.citationHorizontalPadding,
            bottom: configuration.designSystem.layout.citationVerticalPadding,
            right: configuration.designSystem.layout.citationHorizontalPadding
        )
    }
}
#endif

private struct FadingInlineText: View {
    let text: String
    let font: Font
    let configuration: StreamingMarkdownConfiguration
    var strikethrough = false

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var stableText = ""
    @State private var fadingText = ""
    @State private var fadingOpacity = 1.0

    var body: some View {
        renderedText
            .onAppear {
                updateText(text)
            }
            .onChange(of: text) { newValue in
                updateText(newValue)
            }
    }

    private var renderedText: Text {
        let stable = Text(stableText).font(font).strikethrough(strikethrough)
        let fading = Text(fadingText)
            .font(font)
            .strikethrough(strikethrough)
            .foregroundColor(configuration.theme.textColor.opacity(fadingOpacity))
        return stable + fading
    }

    private func updateText(_ newText: String) {
        let rendered = stableText + fadingText
        guard newText != rendered else { return }

        if newText.hasPrefix(rendered) {
            stableText = rendered
            fadingText = String(newText.dropFirst(rendered.count))
            guard animationsEnabled else {
                fadingOpacity = 1
                return
            }
            fadingOpacity = 0
            withAnimation(.easeOut(duration: 0.18)) {
                fadingOpacity = 1
            }
        } else {
            stableText = newText
            fadingText = ""
            fadingOpacity = 1
        }
    }

    private var animationsEnabled: Bool {
        configuration.animationPolicy.shouldAnimate(accessibilityReduceMotion: accessibilityReduceMotion)
    }
}

struct InlineFlowLayout: Layout {
    var spacing: CGFloat = 0
    var lineSpacing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        var size = CGSize.zero
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let subviewSize = measuredSize(for: subview, maxWidth: maxWidth)
            if lineWidth > 0, lineWidth + spacing + subviewSize.width > maxWidth {
                size.width = max(size.width, lineWidth)
                size.height += lineHeight + lineSpacing
                lineWidth = 0
                lineHeight = 0
            }
            lineWidth += (lineWidth == 0 ? 0 : spacing) + subviewSize.width
            lineHeight = max(lineHeight, subviewSize.height)
        }

        size.width = min(max(size.width, lineWidth), maxWidth)
        size.height += lineHeight
        return size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let subviewSize = measuredSize(for: subview, maxWidth: bounds.width)
            if origin.x > bounds.minX, origin.x + spacing + subviewSize.width > bounds.maxX {
                origin.x = bounds.minX
                origin.y += lineHeight + lineSpacing
                lineHeight = 0
            }
            if origin.x > bounds.minX {
                origin.x += spacing
            }
            subview.place(
                at: CGPoint(x: origin.x, y: origin.y),
                proposal: ProposedViewSize(subviewSize)
            )
            origin.x += subviewSize.width
            lineHeight = max(lineHeight, subviewSize.height)
        }
    }

    private func measuredSize(for subview: LayoutSubview, maxWidth: CGFloat) -> CGSize {
        let unconstrainedSize = subview.sizeThatFits(.unspecified)
        guard maxWidth.isFinite, unconstrainedSize.width > maxWidth else {
            return unconstrainedSize
        }
        return subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
    }
}
