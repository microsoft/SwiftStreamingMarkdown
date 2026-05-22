import Foundation

public struct StreamingMarkdownFixture: Identifiable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let text: String

    public init(id: String, title: String, text: String) {
        self.id = id
        self.title = title
        self.text = text
    }
}

public enum StreamingMarkdownFixtures {
    public static let plain = fixture(id: "plain", title: "Plain markdown", fileName: "plain.md")
    public static let partialTable = fixture(id: "partial-table", title: "Partial table", fileName: "partial-table.md")
    public static let code = fixture(id: "code-block", title: "Code block", fileName: "code-block.md")
    public static let citations = fixture(id: "citations", title: "Citations", fileName: "citations.md")
    public static let partialEmphasis = fixture(id: "partial-emphasis", title: "Partial emphasis", fileName: "partial-emphasis.md")
    public static let math = fixture(id: "math", title: "Math", fileName: "math.md")
    public static let links = fixture(id: "links", title: "Links", fileName: "links.md")
    public static let formattingShowcase = fixture(id: "formatting-showcase", title: "Formatting showcase", fileName: "formatting-showcase.md")
    public static let limitationsShowcase = fixture(id: "limitations-showcase", title: "Limitations showcase", fileName: "limitations-showcase.md")
    public static let incompleteCodeFence = fixture(id: "incomplete-code-fence", title: "Incomplete code fence", fileName: "incomplete-code-fence.md")
    public static let mixed = fixture(id: "mixed-long-response", title: "Mixed long response", fileName: "mixed-long-response.md")

    public static let all: [StreamingMarkdownFixture] = [
        plain,
        partialTable,
        code,
        citations,
        partialEmphasis,
        math,
        links,
        formattingShowcase,
        limitationsShowcase,
        incompleteCodeFence,
        mixed
    ]

    private static func fixture(id: String, title: String, fileName: String) -> StreamingMarkdownFixture {
        guard let url = Bundle.module.url(forResource: fileName.removingMarkdownExtension, withExtension: "md") ??
            Bundle.module.url(forResource: fileName.removingMarkdownExtension, withExtension: "md", subdirectory: "StreamingFixtures") else {
            fatalError("Missing streaming fixture resource: \(fileName). Run `make sync-fixtures` from the package root.")
        }

        do {
            return StreamingMarkdownFixture(
                id: id,
                title: title,
                text: try String(contentsOf: url, encoding: .utf8)
            )
        } catch {
            fatalError("Could not read streaming fixture resource \(fileName): \(error)")
        }
    }
}

private extension String {
    var removingMarkdownExtension: String {
        hasSuffix(".md") ? String(dropLast(3)) : self
    }
}
