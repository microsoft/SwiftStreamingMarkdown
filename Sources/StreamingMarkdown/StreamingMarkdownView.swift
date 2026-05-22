import SwiftUI

public struct StreamingMarkdownView: View {
    private let text: String
    private let dependencies: StreamingMarkdownViewDependencies

    @StateObject private var controller = StreamingMarkdownController()
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var displayedBlockIDs = Set<String>()

    public init(
        text: String,
        configuration: StreamingMarkdownConfiguration = .default,
        parser: any StreamingMarkdownParsing = StreamingMarkdownParser(),
        showsRewriteDiagnostics: Bool = false,
        onLinkTap: ((URL) -> Void)? = nil,
        onCitationTap: ((Citation) -> Void)? = nil,
        onCodeCopy: ((_ code: String, _ language: String?) -> Void)? = nil,
        onTableExport: ((MarkdownTableExport, TableExportFormat) -> Void)? = nil,
        onEvent: ((StreamingMarkdownEvent) -> Void)? = nil
    ) {
        self.text = text
        self.dependencies = StreamingMarkdownViewDependencies(
            configuration: configuration,
            actionHandlers: MarkdownActionHandlers(
                onLinkTap: onLinkTap,
                onCitationTap: onCitationTap,
                onCodeCopy: onCodeCopy,
                onTableExport: onTableExport,
                onEvent: onEvent
            ),
            parser: parser,
            showsRewriteDiagnostics: showsRewriteDiagnostics
        )
    }

    public init(
        text: String,
        configuration: StreamingMarkdownConfiguration = .default,
        actionHandlers: MarkdownActionHandlers,
        parser: any StreamingMarkdownParsing = StreamingMarkdownParser(),
        showsRewriteDiagnostics: Bool = false
    ) {
        self.text = text
        self.dependencies = StreamingMarkdownViewDependencies(
            configuration: configuration,
            actionHandlers: actionHandlers,
            parser: parser,
            showsRewriteDiagnostics: showsRewriteDiagnostics
        )
    }

    public var body: some View {
        let configuration = dependencies.configuration
        VStack(alignment: .leading, spacing: configuration.designSystem.layout.blockSpacing) {
            if dependencies.showsRewriteDiagnostics, controller.result?.wasSpeculativelyRewritten == true {
                Text("Streaming rewrite: \(controller.result?.appliedRewriteNames.joined(separator: ", ") ?? "")")
                    .font(.caption)
                    .foregroundStyle(configuration.theme.secondaryTextColor)
                    .accessibilityLabel("Streaming markdown speculative rewrite applied")
            }

            ForEach(controller.result?.blocks ?? []) { block in
                FadingMarkdownBlock(animationsEnabled: animationsEnabled) {
                    MarkdownBlockView(
                        block: block,
                        configuration: configuration,
                        actionHandlers: dependencies.actionHandlers
                    )
                }
                .onAppear {
                    if displayedBlockIDs.insert(block.id).inserted {
                        dependencies.actionHandlers.onEvent?(.blockDisplayed(id: block.id, kind: block.eventKind))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: text) {
            displayedBlockIDs.removeAll()
            await controller.parse(text, parser: dependencies.parser, configuration: configuration)
            if let result = controller.result {
                dependencies.actionHandlers.onEvent?(
                    .documentParsed(
                        blockCount: result.blocks.count,
                        wasSpeculativelyRewritten: result.wasSpeculativelyRewritten
                    )
                )
                if !result.appliedRewriteNames.isEmpty {
                    dependencies.actionHandlers.onEvent?(.rewriteApplied(names: result.appliedRewriteNames))
                }
            }
        }
    }

    private var animationsEnabled: Bool {
        dependencies.configuration.animationPolicy.shouldAnimate(accessibilityReduceMotion: accessibilityReduceMotion)
    }
}

private extension MarkdownBlock {
    var eventKind: String {
        switch self {
        case .paragraph: "paragraph"
        case .heading: "heading"
        case .codeBlock: "codeBlock"
        case .table: "table"
        case .blockMath: "blockMath"
        case .blockQuote: "blockQuote"
        case .unorderedList: "unorderedList"
        case .orderedList: "orderedList"
        case .horizontalRule: "horizontalRule"
        }
    }
}

// Keep mixed value/reference dependencies behind one reference so SwiftUI copies a
// stable handle instead of repeatedly introspecting the full configuration layout.
private final class StreamingMarkdownViewDependencies {
    let configuration: StreamingMarkdownConfiguration
    let actionHandlers: MarkdownActionHandlers
    let parser: any StreamingMarkdownParsing
    let showsRewriteDiagnostics: Bool

    init(
        configuration: StreamingMarkdownConfiguration,
        actionHandlers: MarkdownActionHandlers,
        parser: any StreamingMarkdownParsing,
        showsRewriteDiagnostics: Bool
    ) {
        self.configuration = configuration
        self.actionHandlers = actionHandlers
        self.parser = parser
        self.showsRewriteDiagnostics = showsRewriteDiagnostics
    }
}

private struct FadingMarkdownBlock<Content: View>: View {
    @State private var isVisible = false
    let animationsEnabled: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .opacity(isVisible || !animationsEnabled ? 1 : 0)
            .animation(animationsEnabled ? .easeOut(duration: 0.18) : nil, value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

@MainActor
private final class StreamingMarkdownController: ObservableObject {
    @Published var result: StreamingMarkdownParseResult?

    func parse(
        _ text: String,
        parser: any StreamingMarkdownParsing,
        configuration: StreamingMarkdownConfiguration
    ) async {
        let parseResult = await parser.parse(text, configuration: configuration)
        result = parseResult
    }
}
