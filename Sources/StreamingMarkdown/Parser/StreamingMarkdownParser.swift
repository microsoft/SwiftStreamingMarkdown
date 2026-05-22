import Foundation
import Markdown

public protocol StreamingMarkdownParsing {
    func parse(_ text: String, configuration: StreamingMarkdownConfiguration) async -> StreamingMarkdownParseResult
}

public struct StreamingMarkdownParser: StreamingMarkdownParsing {
    private let defaultRewriters: [any PartialMarkdownRewriter]
    private let latexPreprocessor: LaTexPreProcessor

    public init(defaultRewriters: [any PartialMarkdownRewriter] = [PartialEmphasisRewriter(), PartialTableRewriter()]) {
        self.defaultRewriters = defaultRewriters
        self.latexPreprocessor = LaTexPreProcessorImpl()
    }

    public func parse(_ text: String, configuration: StreamingMarkdownConfiguration = .default) async -> StreamingMarkdownParseResult {
        let preprocessedText = latexPreprocessor.process(input: text)
        let rewriteResult = rewrite(preprocessedText, options: configuration.parseOptions)
        let document = Document(parsing: rewriteResult.text)
        let astBlocks = MarkdownASTBlockConverter(
            document: document,
            citationConfiguration: configuration.citationConfiguration
        ).parseBlocks()
        let blocks = astBlocks.isEmpty ? LineMarkdownParser(
            text: rewriteResult.text,
            citationConfiguration: configuration.citationConfiguration
        ).parseBlocks() : astBlocks
        return StreamingMarkdownParseResult(
            blocks: blocks,
            originalText: text,
            rewrittenText: rewriteResult.text,
            appliedRewriteNames: rewriteResult.names
        )
    }

    private func rewrite(_ text: String, options: StreamingMarkdownParseOptions) -> (text: String, names: [String]) {
        guard options.enablesSpeculativeRewrites else { return (text, []) }
        var current = text
        var names: [String] = []
        for rewriter in defaultRewriters + options.customRewriters {
            if let rewrite = rewriter.rewriteIfNeeded(current), rewrite.text != current {
                current = rewrite.text
                names.append(rewrite.name)
            }
        }
        return (current, names)
    }
}

private struct MarkdownASTBlockConverter {
    let document: Document
    let citationConfiguration: CitationParsingConfiguration

    func parseBlocks() -> [MarkdownBlock] {
        document.children.enumerated().compactMap { index, child in
            block(from: child, id: makeID("block", index))
        }
    }

    private func blocks(from markup: Markup, idPrefix: String) -> [MarkdownBlock] {
        markup.children.enumerated().compactMap { index, child in
            block(from: child, id: "\(idPrefix)-\(index)")
        }
    }

    private func block(from markup: Markup, id: String) -> MarkdownBlock? {
        switch markup {
        case let paragraph as Paragraph:
            return .paragraph(id: id, runs: inlineRuns(in: paragraph, idPrefix: id))
        case let heading as Heading:
            return .heading(id: id, level: heading.level, runs: inlineRuns(in: heading, idPrefix: id))
        case let quote as BlockQuote:
            return .blockQuote(id: id, children: blocks(from: quote, idPrefix: "\(id)-quote"))
        case let list as UnorderedList:
            return .unorderedList(id: id, items: listItems(in: list, idPrefix: "\(id)-item"))
        case let list as OrderedList:
            return .orderedList(
                id: id,
                startIndex: Int(list.startIndex),
                items: listItems(in: list, idPrefix: "\(id)-item")
            )
        case let code as CodeBlock:
            if code.language == LaTexPreProcessorImpl.customCodeType {
                return .blockMath(id: id, latex: code.code.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return .codeBlock(id: id, language: code.language, code: code.code.trimmingCharacters(in: .newlines))
        case let table as Markdown.Table:
            return .table(id: id, table: markdownTable(from: table))
        case let html as HTMLBlock:
            return .paragraph(id: id, runs: [.text(id: "\(id)-html", html.rawHTML)])
        case is ThematicBreak:
            return .horizontalRule(id: id)
        default:
            let childBlocks = blocks(from: markup, idPrefix: id)
            if !childBlocks.isEmpty {
                return .paragraph(id: id, runs: [.text(id: "\(id)-fallback", childBlocks.plainText)])
            }
            return nil
        }
    }

    private func listItems(in list: Markup, idPrefix: String) -> [MarkdownListItem] {
        list.children.enumerated().compactMap { index, child in
            guard let item = child as? ListItem else { return nil }
            let children = blocks(from: item, idPrefix: "\(idPrefix)-\(index)")
            return MarkdownListItem(
                id: "\(idPrefix)-\(index)",
                children: children,
                startsWithBold: children.first?.startsWithStrongText == true
            )
        }
    }

    private func markdownTable(from table: Markdown.Table) -> MarkdownTable {
        let headers = table.head.children.compactMap { cellText($0) }
        let rows = table.body.children.compactMap { row -> [String]? in
            guard row is Markdown.Table.Row else { return nil }
            let cells = row.children.compactMap { cellText($0) }
            return cells.count == headers.count ? cells : nil
        }
        let rawMarkdown = table.body.children.allSatisfy { $0.childCount == table.head.childCount } ? table.format() : ""
        return MarkdownTable(headers: headers, rows: rows, rawMarkdown: rawMarkdown)
    }

    private func cellText(_ markup: Markup) -> String? {
        guard markup is Markdown.Table.Cell else { return nil }
        return inlineRuns(in: markup, idPrefix: "cell").plainText
    }

    private func inlineRuns(in markup: Markup, idPrefix: String) -> [InlineRun] {
        let runs = markup.children.enumerated().flatMap { index, child in
            inlineRuns(from: child, idPrefix: "\(idPrefix)-inline-\(index)")
        }
        return runs.coalescingAdjacentText()
    }

    private func inlineRuns(from markup: Markup, idPrefix: String) -> [InlineRun] {
        switch markup {
        case let text as Markdown.Text:
            return InlineRunParser(
                text: text.string,
                citationConfiguration: citationConfiguration
            ).parse()
        case let strong as Strong:
            return [.strong(id: idPrefix, inlineRuns(in: strong, idPrefix: idPrefix).plainText)]
        case let emphasis as Emphasis:
            return [.emphasis(id: idPrefix, inlineRuns(in: emphasis, idPrefix: idPrefix).plainText)]
        case let strikethrough as Strikethrough:
            return [.strikethrough(id: idPrefix, inlineRuns(in: strikethrough, idPrefix: idPrefix).plainText)]
        case let code as InlineCode:
            let content = code.code
            if content.hasPrefix(LaTexPreProcessorImpl.inlineCodePrefix),
               content.hasSuffix(LaTexPreProcessorImpl.inlineCodeSuffix) {
                let latex = String(
                    content
                        .dropFirst(LaTexPreProcessorImpl.inlineCodePrefix.count)
                        .dropLast(LaTexPreProcessorImpl.inlineCodeSuffix.count)
                )
                return [.inlineMath(id: idPrefix, latex: latex)]
            }
            return [.code(id: idPrefix, content)]
        case let link as Link:
            let title = inlineRuns(in: link, idPrefix: idPrefix).plainText
            guard let destination = link.destination else {
                return [.text(id: idPrefix, title)]
            }
            if let citation = citationConfiguration.citation(from: title, destination: destination) {
                return [.citation(id: idPrefix, citation)]
            }
            if let url = URL(string: destination) {
                return [.link(id: idPrefix, title: title, url: url)]
            }
            return [.text(id: idPrefix, title)]
        case is SoftBreak:
            return [.text(id: idPrefix, " ")]
        case is LineBreak:
            return [.text(id: idPrefix, "\n")]
        default:
            if let citation = citationConfiguration.markerCitation(in: Substring(markup.format()), anchoredToStart: true) {
                return [.citation(id: idPrefix, citation.citation)]
            }
            return inlineRuns(in: markup, idPrefix: idPrefix)
        }
    }

    private func makeID(_ prefix: String, _ index: Int) -> String {
        "\(prefix)-\(index)"
    }
}

private struct LineMarkdownParser {
    let text: String
    let citationConfiguration: CitationParsingConfiguration

    func parseBlocks() -> [MarkdownBlock] {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [MarkdownBlock] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                index += 1
            } else if isFootnoteDefinitionLine(trimmed) {
                index += 1
            } else if trimmed == "---" || trimmed == "***" {
                blocks.append(.horizontalRule(id: makeID("rule", index)))
                index += 1
            } else if trimmed.hasPrefix("$$") {
                let parsed = collectBlockMath(lines: lines, from: index)
                blocks.append(.blockMath(id: makeID("math", index), latex: parsed.latex))
                index = parsed.nextIndex
            } else if trimmed.hasPrefix("```") {
                let parsed = collectCodeBlock(lines: lines, from: index)
                if parsed.language == LaTexPreProcessorImpl.customCodeType {
                    blocks.append(.blockMath(id: makeID("math", index), latex: parsed.code))
                } else {
                    blocks.append(.codeBlock(id: makeID("code", index), language: parsed.language, code: parsed.code))
                }
                index = parsed.nextIndex
            } else if isTableStart(lines: lines, index: index) {
                let parsed = collectTable(lines: lines, from: index)
                blocks.append(.table(id: makeID("table", index), table: parsed.table))
                index = parsed.nextIndex
            } else if let heading = parseHeading(line) {
                blocks.append(.heading(id: makeID("heading", index), level: heading.level, runs: inlineRuns(heading.text)))
                index += 1
            } else if trimmed.hasPrefix(">") {
                let parsed = collectBlockQuote(lines: lines, from: index)
                blocks.append(.blockQuote(id: makeID("quote", index), children: [.paragraph(id: makeID("quote-paragraph", index), runs: inlineRuns(parsed.text))]))
                index = parsed.nextIndex
            } else if isUnorderedListLine(trimmed) {
                let parsed = collectList(lines: lines, from: index, ordered: false)
                blocks.append(.unorderedList(id: makeID("ul", index), items: parsed.items.enumerated().map { itemIndex, runs in
                    MarkdownListItem(id: makeID("ul-item", index) + "-\(itemIndex)", runs: runs)
                }))
                index = parsed.nextIndex
            } else if isOrderedListLine(trimmed) {
                let parsed = collectList(lines: lines, from: index, ordered: true)
                blocks.append(.orderedList(id: makeID("ol", index), startIndex: parsed.startIndex, items: parsed.items.enumerated().map { itemIndex, runs in
                    MarkdownListItem(id: makeID("ol-item", index) + "-\(itemIndex)", runs: runs)
                }))
                index = parsed.nextIndex
            } else {
                let parsed = collectParagraph(lines: lines, from: index)
                blocks.append(.paragraph(id: makeID("paragraph", index), runs: inlineRuns(parsed.text)))
                index = parsed.nextIndex
            }
        }

        return blocks
    }

    private func collectParagraph(lines: [String], from start: Int) -> (text: String, nextIndex: Int) {
        var paragraph: [String] = []
        var index = start
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("```") || trimmed.hasPrefix("$$") || trimmed.hasPrefix("|") || parseHeading(lines[index]) != nil || trimmed.hasPrefix(">") || isUnorderedListLine(trimmed) || isOrderedListLine(trimmed) || isFootnoteDefinitionLine(trimmed) {
                break
            }
            paragraph.append(trimmed)
            index += 1
        }
        return (paragraph.joined(separator: " "), index)
    }

    private func collectCodeBlock(lines: [String], from start: Int) -> (language: String?, code: String, nextIndex: Int) {
        let opening = lines[start].trimmingCharacters(in: .whitespaces)
        let language = String(opening.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        var codeLines: [String] = []
        var index = start + 1
        while index < lines.count {
            if lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                return (language.isEmpty ? nil : language, codeLines.joined(separator: "\n"), index + 1)
            }
            codeLines.append(lines[index])
            index += 1
        }
        return (language.isEmpty ? nil : language, codeLines.joined(separator: "\n"), index)
    }

    private func collectBlockMath(lines: [String], from start: Int) -> (latex: String, nextIndex: Int) {
        var latexLines: [String] = []
        let firstLine = lines[start].trimmingCharacters(in: .whitespaces)
        let firstRemainder = String(firstLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        if !firstRemainder.isEmpty, firstRemainder.hasSuffix("$$") {
            return (String(firstRemainder.dropLast(2)).trimmingCharacters(in: .whitespaces), start + 1)
        }
        if !firstRemainder.isEmpty {
            latexLines.append(firstRemainder)
        }
        var index = start + 1
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed.hasSuffix("$$") {
                let closingLineRemainder = String(trimmed.dropLast(2)).trimmingCharacters(in: .whitespaces)
                if !closingLineRemainder.isEmpty {
                    latexLines.append(closingLineRemainder)
                }
                return (latexLines.joined(separator: "\n"), index + 1)
            }
            latexLines.append(lines[index])
            index += 1
        }
        return (latexLines.joined(separator: "\n"), index)
    }

    private func collectTable(lines: [String], from start: Int) -> (table: MarkdownTable, nextIndex: Int) {
        var tableLines: [String] = []
        var index = start
        while index < lines.count, lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("|") {
            tableLines.append(lines[index])
            index += 1
        }

        let rows = tableLines.map(parseTableRow)
        let headers = rows.first ?? []
        let bodyStart = rows.dropFirst().first.map(isDelimiterRow) == true ? 2 : 1
        let body = rows.dropFirst(bodyStart).filter { !$0.isEmpty }
        return (MarkdownTable(headers: headers, rows: Array(body), rawMarkdown: tableLines.joined(separator: "\n")), index)
    }

    private func collectBlockQuote(lines: [String], from start: Int) -> (text: String, nextIndex: Int) {
        var quoteLines: [String] = []
        var index = start
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix(">") else { break }
            quoteLines.append(String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces))
            index += 1
        }
        return (quoteLines.joined(separator: " "), index)
    }

    private func collectList(lines: [String], from start: Int, ordered: Bool) -> (items: [[InlineRun]], startIndex: Int, nextIndex: Int) {
        var items: [[InlineRun]] = []
        var index = start
        let startIndex = ordered ? orderedListMarkerValue(lines[start]) ?? 1 : 1
        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard ordered ? isOrderedListLine(trimmed) : isUnorderedListLine(trimmed) else { break }
            var itemParts = [listItemText(from: trimmed, ordered: ordered)]
            let baseIndent = leadingWhitespaceCount(line)
            index += 1
            while index < lines.count {
                let continuationLine = lines[index]
                if continuationLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { break }
                let continuationIndent = leadingWhitespaceCount(continuationLine)
                guard continuationIndent > baseIndent else { break }
                itemParts.append(stripNestedListMarker(continuationLine.trimmingCharacters(in: .whitespaces)))
                index += 1
            }
            items.append(inlineRuns(itemParts.filter { !$0.isEmpty }.joined(separator: " ")))
        }
        return (items, startIndex, index)
    }

    private func listItemText(from trimmed: String, ordered: Bool) -> String {
        if ordered, let range = trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
            return String(trimmed[range.upperBound...])
        }
        return String(trimmed.dropFirst(2))
    }

    private func inlineRuns(_ text: String) -> [InlineRun] {
        InlineRunParser(text: text, citationConfiguration: citationConfiguration).parse()
    }

    private func parseHeading(_ line: String) -> (level: Int, text: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let markerCount = trimmed.prefix { $0 == "#" }.count
        guard (1...6).contains(markerCount), trimmed.dropFirst(markerCount).first == " " else { return nil }
        return (markerCount, String(trimmed.dropFirst(markerCount + 1)))
    }

    private func isTableStart(lines: [String], index: Int) -> Bool {
        guard index < lines.count else { return false }
        let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("|") && trimmed.contains("|")
    }

    private func parseTableRow(_ line: String) -> [String] {
        var row = line.trimmingCharacters(in: .whitespaces)
        if row.hasPrefix("|") { row.removeFirst() }
        if row.hasSuffix("|") { row.removeLast() }
        var cells: [String] = []
        var current = ""
        var index = row.startIndex
        while index < row.endIndex {
            let character = row[index]
            let next = row.index(after: index)
            if character == "\\", next < row.endIndex, row[next] == "|" {
                current.append("|")
                index = row.index(after: next)
            } else if character == "|" {
                cells.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
                index = next
            } else {
                current.append(character)
                index = next
            }
        }
        cells.append(current.trimmingCharacters(in: .whitespaces))
        return cells
    }

    private func isDelimiterRow(_ row: [String]) -> Bool {
        row.allSatisfy { cell in
            cell.allSatisfy { $0 == "-" || $0 == ":" || $0 == " " } && cell.contains("-")
        }
    }

    private func isUnorderedListLine(_ text: String) -> Bool {
        text.hasPrefix("- ") || text.hasPrefix("* ")
    }

    private func isOrderedListLine(_ text: String) -> Bool {
        text.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil
    }

    private func orderedListMarkerValue(_ line: String) -> Int? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let range = trimmed.range(of: #"^\d+"#, options: .regularExpression) else { return nil }
        return Int(trimmed[range])
    }

    private func leadingWhitespaceCount(_ line: String) -> Int {
        line.prefix { $0.isWhitespace }.count
    }

    private func stripNestedListMarker(_ line: String) -> String {
        if isUnorderedListLine(line) {
            return String(line.dropFirst(2))
        }
        if let range = line.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
            return String(line[range.upperBound...])
        }
        return line
    }

    private func isFootnoteDefinitionLine(_ text: String) -> Bool {
        text.range(of: #"^\[\^[^\]]+\]:"#, options: .regularExpression) != nil
    }

    private func makeID(_ prefix: String, _ index: Int) -> String {
        "\(prefix)-\(index)"
    }
}

private struct InlineRunParser {
    let text: String
    let citationConfiguration: CitationParsingConfiguration

    func parse() -> [InlineRun] {
        var runs: [InlineRun] = []
        var remainder = text[...]
        var ordinal = 0

        while !remainder.isEmpty {
            if remainder.hasPrefix("**"), let end = remainder.dropFirst(2).range(of: "**") {
                let content = String(remainder[remainder.index(remainder.startIndex, offsetBy: 2)..<end.lowerBound])
                runs.append(.strong(id: id("strong", ordinal), content))
                remainder = remainder[end.upperBound...]
            } else if remainder.hasPrefix("~~"), let end = remainder.dropFirst(2).range(of: "~~") {
                let content = String(remainder[remainder.index(remainder.startIndex, offsetBy: 2)..<end.lowerBound])
                runs.append(.strikethrough(id: id("strikethrough", ordinal), content))
                remainder = remainder[end.upperBound...]
            } else if remainder.hasPrefix("`"), let end = remainder.dropFirst().firstIndex(of: "`") {
                let content = String(remainder[remainder.index(after: remainder.startIndex)..<end])
                if content.hasPrefix(LaTexPreProcessorImpl.inlineCodePrefix),
                   content.hasSuffix(LaTexPreProcessorImpl.inlineCodeSuffix) {
                    let latex = String(
                        content
                            .dropFirst(LaTexPreProcessorImpl.inlineCodePrefix.count)
                            .dropLast(LaTexPreProcessorImpl.inlineCodeSuffix.count)
                    )
                    runs.append(.inlineMath(id: id("math", ordinal), latex: latex))
                } else {
                    runs.append(.code(id: id("code", ordinal), content))
                }
                remainder = remainder[remainder.index(after: end)...]
            } else if remainder.hasPrefix("$"), let end = remainder.dropFirst().firstIndex(of: "$") {
                let content = String(remainder[remainder.index(after: remainder.startIndex)..<end])
                runs.append(.inlineMath(id: id("math", ordinal), latex: content))
                remainder = remainder[remainder.index(after: end)...]
            } else if remainder.hasPrefix("*"), let end = remainder.dropFirst().firstIndex(of: "*") {
                let content = String(remainder[remainder.index(after: remainder.startIndex)..<end])
                runs.append(.emphasis(id: id("emphasis", ordinal), content))
                remainder = remainder[remainder.index(after: end)...]
            } else if let parsedCitation = citationConfiguration.markerCitation(in: remainder, anchoredToStart: true) {
                runs.append(.citation(id: id("citation", ordinal), parsedCitation.citation))
                remainder = remainder[parsedCitation.range.upperBound...]
            } else if remainder.hasPrefix("["), let parsedLink = parseLink(in: remainder) {
                if let citation = citationConfiguration.citation(from: parsedLink.title, destination: parsedLink.destination) {
                    runs.append(.citation(id: id("citation", ordinal), citation))
                } else if let url = URL(string: parsedLink.destination) {
                    runs.append(.link(id: id("link", ordinal), title: parsedLink.title, url: url))
                } else {
                    runs.append(.text(id: id("text", ordinal), parsedLink.raw))
                }
                remainder = parsedLink.remainder
            } else {
                let nextSpecial = remainder.dropFirst().firstIndex { "*[`$~".contains($0) } ?? remainder.endIndex
                let nextCitation = citationConfiguration.markerCitation(in: remainder, anchoredToStart: false)?.range.lowerBound
                let nextIndex = [nextSpecial, nextCitation].compactMap { $0 }.min() ?? remainder.endIndex
                let content = String(remainder[..<nextIndex])
                runs.append(.text(id: id("text", ordinal), content))
                remainder = remainder[nextIndex...]
            }
            ordinal += 1
        }

        return coalesceTextRuns(runs)
    }

    private func parseLink(in text: Substring) -> (title: String, destination: String, raw: String, remainder: Substring)? {
        guard let closeBracket = text.firstIndex(of: "]"),
              text.index(after: closeBracket) < text.endIndex,
              text[text.index(after: closeBracket)] == "(",
              let closeParen = text[text.index(after: closeBracket)...].firstIndex(of: ")") else {
            return nil
        }
        let title = String(text[text.index(after: text.startIndex)..<closeBracket])
        let destinationStart = text.index(closeBracket, offsetBy: 2)
        let destination = String(text[destinationStart..<closeParen])
        let raw = String(text[...closeParen])
        let remainder = text[text.index(after: closeParen)...]
        return (title, destination, raw, remainder)
    }

    private func coalesceTextRuns(_ runs: [InlineRun]) -> [InlineRun] {
        var result: [InlineRun] = []
        for run in runs where !run.isEmptyText {
            if case .text(let previousID, let previousText) = result.last, case .text(_, let text) = run {
                result[result.count - 1] = .text(id: previousID, previousText + text)
            } else {
                result.append(run)
            }
        }
        return result
    }

    private func id(_ prefix: String, _ ordinal: Int) -> String {
        "\(prefix)-\(ordinal)-\(abs(text.hashValue))"
    }
}

private extension InlineRun {
    var isEmptyText: Bool {
        if case .text(_, let value) = self { return value.isEmpty }
        return false
    }
}

private extension Array where Element == InlineRun {
    func coalescingAdjacentText() -> [InlineRun] {
        var result: [InlineRun] = []
        for run in self where !run.isEmptyText {
            if case .text(let previousID, let previousText) = result.last, case .text(_, let text) = run {
                result[result.count - 1] = .text(id: previousID, previousText + text)
            } else {
                result.append(run)
            }
        }
        return result
    }
}

private extension MarkdownBlock {
    var startsWithStrongText: Bool {
        switch self {
        case .paragraph(_, let runs),
             .heading(_, _, let runs):
            if case .strong = runs.first { return true }
            return false
        case .blockQuote(_, let children):
            return children.first?.startsWithStrongText == true
        case .unorderedList(_, let items),
             .orderedList(_, _, let items):
            return items.first?.startsWithBold == true
        case .codeBlock,
             .table,
             .blockMath,
             .horizontalRule:
            return false
        }
    }
}
