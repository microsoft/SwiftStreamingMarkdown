import Foundation

public struct StreamingMarkdownParseResult: Equatable {
    public let blocks: [MarkdownBlock]
    public let originalText: String
    public let rewrittenText: String
    public let appliedRewriteNames: [String]

    public var wasSpeculativelyRewritten: Bool {
        !appliedRewriteNames.isEmpty
    }

    public init(blocks: [MarkdownBlock], originalText: String, rewrittenText: String, appliedRewriteNames: [String]) {
        self.blocks = blocks
        self.originalText = originalText
        self.rewrittenText = rewrittenText
        self.appliedRewriteNames = appliedRewriteNames
    }
}

public enum MarkdownBlock: Identifiable, Equatable {
    case paragraph(id: String, runs: [InlineRun])
    case heading(id: String, level: Int, runs: [InlineRun])
    case unorderedList(id: String, items: [MarkdownListItem])
    case orderedList(id: String, startIndex: Int, items: [MarkdownListItem])
    case blockQuote(id: String, children: [MarkdownBlock])
    case codeBlock(id: String, language: String?, code: String)
    case table(id: String, table: MarkdownTable)
    case blockMath(id: String, latex: String)
    case horizontalRule(id: String)

    public var id: String {
        switch self {
        case .paragraph(let id, _),
             .heading(let id, _, _),
             .unorderedList(let id, _),
             .orderedList(let id, _, _),
             .blockQuote(let id, _),
             .codeBlock(let id, _, _),
             .table(let id, _),
             .blockMath(let id, _),
             .horizontalRule(let id):
            id
        }
    }
}

public struct MarkdownListItem: Equatable, Identifiable {
    public let id: String
    public var children: [MarkdownBlock]
    public var startsWithBold: Bool

    public init(id: String, children: [MarkdownBlock], startsWithBold: Bool = false) {
        self.id = id
        self.children = children
        self.startsWithBold = startsWithBold
    }

    public init(id: String, runs: [InlineRun], startsWithBold: Bool = false) {
        self.init(
            id: id,
            children: [.paragraph(id: "\(id)-paragraph", runs: runs)],
            startsWithBold: startsWithBold
        )
    }
}

public enum InlineRun: Identifiable, Equatable {
    case text(id: String, String)
    case strong(id: String, String)
    case emphasis(id: String, String)
    case strikethrough(id: String, String)
    case code(id: String, String)
    case link(id: String, title: String, url: URL)
    case citation(id: String, Citation)
    case inlineMath(id: String, latex: String)

    public var id: String {
        switch self {
        case .text(let id, _),
             .strong(let id, _),
             .emphasis(let id, _),
             .strikethrough(let id, _),
             .code(let id, _),
             .link(let id, _, _),
             .citation(let id, _),
             .inlineMath(let id, _):
            id
        }
    }
}

public extension InlineRun {
    var plainText: String {
        switch self {
        case .text(_, let value),
             .strong(_, let value),
             .emphasis(_, let value),
             .strikethrough(_, let value),
             .code(_, let value):
            value
        case .link(_, let title, _):
            title
        case .citation(_, let citation):
            citation.title
        case .inlineMath(_, let latex):
            latex
        }
    }
}

public extension Array where Element == InlineRun {
    var plainText: String {
        map(\.plainText).joined()
    }
}

public extension MarkdownBlock {
    var plainText: String {
        switch self {
        case .paragraph(_, let runs),
             .heading(_, _, let runs):
            runs.plainText
        case .unorderedList(_, let items),
             .orderedList(_, _, let items):
            items.map(\.plainText).joined(separator: "\n")
        case .blockQuote(_, let children):
            children.plainText
        case .codeBlock(_, _, let code),
             .blockMath(_, let code):
            code
        case .table(_, let table):
            ([table.headers] + table.rows).map { $0.joined(separator: "\t") }.joined(separator: "\n")
        case .horizontalRule:
            "---"
        }
    }
}

public extension MarkdownListItem {
    var plainText: String {
        children.plainText
    }
}

public extension Array where Element == MarkdownBlock {
    var plainText: String {
        map(\.plainText).joined(separator: "\n")
    }
}

public struct Citation: Identifiable, Equatable, Hashable {
    public let id: String
    public var title: String
    public var source: String?
    public var url: URL?
    public var fullTitle: String?
    public var accessibilityLabel: String

    public init(
        id: String,
        title: String,
        source: String? = nil,
        url: URL? = nil,
        fullTitle: String? = nil,
        accessibilityLabel: String? = nil
    ) {
        self.id = id
        self.title = title
        self.source = source
        self.url = url
        self.fullTitle = fullTitle
        self.accessibilityLabel = accessibilityLabel ?? "Citation: \(fullTitle ?? title)"
    }
}

public enum CitationPresentationStyle: Equatable, Hashable {
    case inlinePills
    case collapsed(maxVisible: Int = 1)
    #if canImport(UIKit)
    case uikitPills
    #endif
}

public enum TableExportFormat: String, Equatable, Hashable, Sendable {
    case markdown
    case csv
    case html
    case plainText
}

public struct MarkdownTable: Equatable, Hashable {
    public var headers: [String]
    public var rows: [[String]]
    public var rawMarkdown: String

    public init(headers: [String], rows: [[String]], rawMarkdown: String) {
        self.headers = headers
        self.rows = rows
        self.rawMarkdown = rawMarkdown
    }

    public var csvString: String {
        ([headers] + rows)
            .map { row in row.map(Self.csvEscaped).joined(separator: ",") }
            .joined(separator: "\n")
    }

    public var markdownString: String {
        if !rawMarkdown.isEmpty { return rawMarkdown }
        let delimiter = Array(repeating: "---", count: headers.count)
        return ([headers, delimiter] + rows.map { normalized($0) })
            .map { row in "| " + row.map(Self.markdownEscaped).joined(separator: " | ") + " |" }
            .joined(separator: "\n")
    }

    public var htmlString: String {
        let headerHTML = "<thead><tr>" + headers.map { "<th>\(Self.htmlEscaped($0))</th>" }.joined() + "</tr></thead>"
        let bodyHTML = "<tbody>" + rows.map { row in
            "<tr>" + normalized(row).map { "<td>\(Self.htmlEscaped($0).replacingOccurrences(of: "\n", with: "<br>"))</td>" }.joined() + "</tr>"
        }.joined() + "</tbody>"
        return "<table>\(headerHTML)\(bodyHTML)</table>"
    }

    public var plainTextString: String {
        ([headers] + rows.map(normalized)).map { $0.joined(separator: "\t") }.joined(separator: "\n")
    }

    public var exportPayload: MarkdownTableExport {
        MarkdownTableExport(table: self)
    }

    private static func csvEscaped(_ value: String) -> String {
        let needsEscaping = value.contains(",") || value.contains("\"") || value.contains("\n")
        guard needsEscaping else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private func normalized(_ row: [String]) -> [String] {
        if row.count < headers.count { return row + Array(repeating: "", count: headers.count - row.count) }
        if row.count > headers.count { return Array(row.prefix(headers.count)) }
        return row
    }

    private static func markdownEscaped(_ value: String) -> String {
        value.replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: "")
    }

    private static func htmlEscaped(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

public struct MarkdownTableExport: Equatable, Hashable {
    public var table: MarkdownTable
    public var markdown: String
    public var csv: String
    public var html: String
    public var plainText: String

    public init(table: MarkdownTable) {
        self.table = table
        self.markdown = table.markdownString
        self.csv = table.csvString
        self.html = table.htmlString
        self.plainText = table.plainTextString
    }

    public func value(for format: TableExportFormat) -> String {
        switch format {
        case .markdown: markdown
        case .csv: csv
        case .html: html
        case .plainText: plainText
        }
    }
}

public enum StreamingMarkdownEvent: Equatable {
    case documentParsed(blockCount: Int, wasSpeculativelyRewritten: Bool)
    case rewriteApplied(names: [String])
    case blockDisplayed(id: String, kind: String)
    case linkTapped(URL)
    case citationTapped(Citation)
    case citationGroupTapped([Citation])
    case codeCopied(language: String?)
    case tableCopied(format: TableExportFormat)
    case tableExported(format: TableExportFormat)
}

public struct MarkdownActionHandlers {
    public var onLinkTap: ((URL) -> Void)?
    public var onCitationTap: ((Citation) -> Void)?
    public var onCitationGroupTap: (([Citation]) -> Void)?
    public var onCodeCopy: ((_ code: String, _ language: String?) -> Void)?
    public var onTableExport: ((MarkdownTableExport, TableExportFormat) -> Void)?
    public var onEvent: ((StreamingMarkdownEvent) -> Void)?

    public init(
        onLinkTap: ((URL) -> Void)? = nil,
        onCitationTap: ((Citation) -> Void)? = nil,
        onCitationGroupTap: (([Citation]) -> Void)? = nil,
        onCodeCopy: ((_ code: String, _ language: String?) -> Void)? = nil,
        onTableExport: ((MarkdownTableExport, TableExportFormat) -> Void)? = nil,
        onEvent: ((StreamingMarkdownEvent) -> Void)? = nil
    ) {
        self.onLinkTap = onLinkTap
        self.onCitationTap = onCitationTap
        self.onCitationGroupTap = onCitationGroupTap
        self.onCodeCopy = onCodeCopy
        self.onTableExport = onTableExport
        self.onEvent = onEvent
    }

    public static let empty = MarkdownActionHandlers()
}
