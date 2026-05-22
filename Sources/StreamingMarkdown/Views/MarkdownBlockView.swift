import SwiftUI

struct MarkdownBlockView: View {
    let block: MarkdownBlock
    let configuration: StreamingMarkdownConfiguration
    let actionHandlers: MarkdownActionHandlers

    var body: some View {
        switch block {
        case .paragraph(_, let runs):
            InlineRunsView(runs: runs, configuration: configuration, actionHandlers: actionHandlers)
        case .heading(_, let level, let runs):
            let headingFont = configuration.theme.headingFont(level: level)
            InlineRunsView(
                runs: runs,
                configuration: configuration,
                actionHandlers: actionHandlers,
                textFont: headingFont,
                strongTextFont: headingFont.bold(),
                emphasisTextFont: headingFont.italic()
            )
                .padding(.top, level <= 2 ? configuration.designSystem.layout.headingTopPadding : configuration.designSystem.layout.headingTopPadding / 2)
                .accessibilityAddTraits(.isHeader)
        case .unorderedList(_, let items):
            VStack(alignment: .leading, spacing: configuration.designSystem.layout.listItemSpacing) {
                ForEach(items) { item in
                    MarkdownListItemView(
                        marker: "•",
                        item: item,
                        configuration: configuration,
                        actionHandlers: actionHandlers
                    )
                }
            }
        case .orderedList(_, let startIndex, let items):
            VStack(alignment: .leading, spacing: configuration.designSystem.layout.listItemSpacing) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    MarkdownListItemView(
                        marker: "\(startIndex + index).",
                        item: item,
                        configuration: configuration,
                        actionHandlers: actionHandlers
                    )
                }
            }
        case .blockQuote(_, let children):
            HStack(alignment: .top, spacing: configuration.designSystem.layout.quoteContentSpacing) {
                Rectangle()
                    .fill(configuration.theme.quoteBarColor)
                    .frame(width: configuration.designSystem.layout.quoteBarWidth)
                VStack(alignment: .leading, spacing: configuration.designSystem.layout.listItemSpacing) {
                    ForEach(children) { child in
                        MarkdownBlockView(
                            block: child,
                            configuration: configuration,
                            actionHandlers: actionHandlers
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
            .background(configuration.theme.quoteBackground, in: RoundedRectangle(cornerRadius: configuration.designSystem.layout.inlineCodeCornerRadius))
        case .codeBlock(_, let language, let code):
            CodeBlockView(code: code, language: language, configuration: configuration, actionHandlers: actionHandlers)
        case .table(_, let table):
            TableBlockView(table: table, configuration: configuration, actionHandlers: actionHandlers)
        case .blockMath(_, let latex):
            ScrollView(.horizontal) {
                BlockMathView(latex: latex, color: configuration.theme.mathColor)
                    .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .horizontalRule:
            Divider()
        }
    }
}

private struct MarkdownListItemView: View {
    let marker: String
    let item: MarkdownListItem
    let configuration: StreamingMarkdownConfiguration
    let actionHandlers: MarkdownActionHandlers

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: configuration.designSystem.layout.listMarkerSpacing) {
            Text(marker)
                .foregroundStyle(configuration.theme.textColor)
            VStack(alignment: .leading, spacing: configuration.designSystem.layout.listItemSpacing) {
                ForEach(item.children) { child in
                    MarkdownBlockView(
                        block: child,
                        configuration: configuration,
                        actionHandlers: actionHandlers
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
