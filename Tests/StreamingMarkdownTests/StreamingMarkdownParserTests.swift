import StreamingMarkdown
import XCTest

final class StreamingMarkdownParserTests: XCTestCase {
    func testParsesAllSharedStreamingFixtures() async throws {
        let fixtureNames = [
            "partial-table.md",
            "code-block.md",
            "mixed-long-response.md",
            "links.md",
            "citations.md",
            "partial-emphasis.md",
            "math.md",
            "incomplete-code-fence.md",
            "formatting-showcase.md",
            "limitations-showcase.md",
            "plain.md"
        ]
        let parser = StreamingMarkdownParser()

        for fixtureName in fixtureNames {
            let source = try readSharedFixture(fixtureName)
            let result = await parser.parse(source)
            XCTAssertFalse(result.blocks.isEmpty, "Expected parsed blocks for \(fixtureName)")
        }
    }

    func testParsesSharedStreamingFixturesAtChunkBoundaries() async throws {
        let fixtureNames = [
            "partial-table.md",
            "code-block.md",
            "mixed-long-response.md",
            "links.md",
            "citations.md",
            "partial-emphasis.md",
            "math.md",
            "incomplete-code-fence.md",
            "formatting-showcase.md",
            "limitations-showcase.md",
            "plain.md"
        ]
        let parser = StreamingMarkdownParser()

        for fixtureName in fixtureNames {
            let source = try readSharedFixture(fixtureName)
            var length = 0
            while length < source.count {
                length = min(length + 8, source.count)
                let chunkEnd = source.index(source.startIndex, offsetBy: length)
                _ = await parser.parse(String(source[..<chunkEnd]))
            }
        }
    }

    func testParsesMixedFixtureSpecialBlocks() async throws {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(try readSharedFixture("mixed-long-response.md"))

        XCTAssertTrue(result.blocks.contains { block in
            if case .orderedList = block { return true }
            return false
        })
        XCTAssertTrue(result.blocks.contains { block in
            if case .table = block { return true }
            return false
        })
        XCTAssertTrue(result.blocks.contains { block in
            if case .codeBlock = block { return true }
            return false
        })
        XCTAssertTrue(result.blocks.contains { block in
            if case .blockMath = block { return true }
            return false
        })
        XCTAssertTrue(result.blocks.contains { block in
            if case .blockQuote(_, let children) = block {
                return children.plainText.contains("Multi-line block quotes")
            }
            return false
        })
        XCTAssertTrue(result.blocks.contains { block in
            if case .orderedList(_, _, let items) = block {
                return items.contains { item in
                    item.plainText.contains("Preserve nested ordered-list details") &&
                        item.plainText.contains("Continue the nested ordered-list explanation")
                }
            }
            return false
        })
        XCTAssertTrue(result.blocks.contains { block in
            if case .paragraph(_, let runs) = block {
                return runs.contains { run in
                    if case .citation = run { return true }
                    return false
                }
            }
            return false
        })
    }

    func testParsesCitationLink() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse("See [1](citation://source?title=1&fullTitle=Source).")

        guard case .paragraph(_, let runs) = result.blocks.first else {
            return XCTFail("Expected paragraph")
        }
        XCTAssertTrue(runs.contains { run in
            if case .citation(_, let citation) = run {
                return citation.title == "1" && citation.fullTitle == "Source"
            }
            return false
        })
    }

    func testParsesMarkerQueryCitationLink() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse("See [2](https://example.com/source?citation=true&title=2&fullTitle=Research%20Source).")

        XCTAssertEqual(
            result.citations,
            [
                Citation(
                    id: "example.com",
                    title: "2",
                    source: "https://example.com/source?citation=true&title=2&fullTitle=Research%20Source",
                    url: URL(string: "https://example.com/source?citation=true&title=2&fullTitle=Research%20Source"),
                    fullTitle: "Research Source",
                    accessibilityLabel: "Citation: Research Source"
                )
            ]
        )
    }

    func testParsesStrikethroughInlineRuns() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse("Keep ~~removed~~ text.")

        guard case .paragraph(_, let runs) = result.blocks.first else {
            return XCTFail("Expected paragraph")
        }
        XCTAssertTrue(runs.contains { run in
            if case .strikethrough(_, "removed") = run { return true }
            return false
        })
        XCTAssertEqual(runs.plainText, "Keep removed text.")
    }

    func testParsesCustomCitationLinkConfiguration() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(
            "See [ignored](source://item-42?label=Docs&name=Design%20Doc).",
            configuration: StreamingMarkdownConfiguration(
                citationConfiguration: CitationParsingConfiguration(
                    accessibilityLabelPrefix: "Reference ",
                    markerQueryItemName: "ref",
                    markerQueryItemValue: "1",
                    citationScheme: "source",
                    titleQueryItemName: "label",
                    fullTitleQueryItemName: "name"
                )
            )
        )

        XCTAssertEqual(
            result.citations,
            [
                Citation(
                    id: "item-42",
                    title: "Docs",
                    source: "source://item-42?label=Docs&name=Design%20Doc",
                    url: URL(string: "source://item-42?label=Docs&name=Design%20Doc"),
                    fullTitle: "Design Doc",
                    accessibilityLabel: "Reference Design Doc"
                )
            ]
        )
    }

    func testParsesCustomCitationMarkerGroupsInsideText() async throws {
        let markerPattern = try CitationMarkerPattern(
            pattern: #"@@cite\(([^|]+)\|([^|]+)\|([^)]+)\)"#,
            idGroup: 1,
            labelGroup: 2,
            sourceGroup: 3
        )
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(
            "Before @@cite(source-42|Docs|https://example.com/doc) after.",
            configuration: StreamingMarkdownConfiguration(
                citationConfiguration: CitationParsingConfiguration(
                    markerPattern: markerPattern,
                    accessibilityLabelPrefix: "Reference "
                )
            )
        )

        XCTAssertEqual(result.citations.count, 1)
        XCTAssertEqual(result.citations.first?.id, "source-42")
        XCTAssertEqual(result.citations.first?.title, "Docs")
        XCTAssertEqual(result.citations.first?.source, "https://example.com/doc")
        XCTAssertEqual(result.citations.first?.url, URL(string: "https://example.com/doc"))
        XCTAssertEqual(result.citations.first?.accessibilityLabel, "Reference Docs")
        XCTAssertEqual(result.paragraphPlainText, "Before Docs after.")
    }

    func testSpeculativePartialTableRewrite() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse("| A | B |")
        XCTAssertTrue(result.wasSpeculativelyRewritten)
        XCTAssertEqual(result.appliedRewriteNames, ["partial-table"])
    }

    func testSpeculativePartialStrongRewrite() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse("This is **still streaming")
        XCTAssertTrue(result.wasSpeculativelyRewritten)
        XCTAssertEqual(result.appliedRewriteNames, ["partial-emphasis"])
    }

    func testSpeculativePartialStrongRewriteWithTrailingSingleDelimiter() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse("This is **still streaming*")
        XCTAssertTrue(result.wasSpeculativelyRewritten)
        XCTAssertEqual(result.appliedRewriteNames, ["partial-emphasis"])
        XCTAssertTrue(result.paragraphPlainText.contains("still streaming"))
    }

    func testSpeculativePartialItalicRewrite() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse("This is *still streaming")
        XCTAssertTrue(result.wasSpeculativelyRewritten)
        XCTAssertEqual(result.appliedRewriteNames, ["partial-emphasis"])
        XCTAssertTrue(result.paragraphPlainText.contains("still streaming"))
    }

    func testSpeculativePartialEmphasisIgnoresCodeBlocks() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(
            """
            ```swift
            let marker = "**"
            ```
            """
        )
        XCTAssertFalse(result.wasSpeculativelyRewritten)
        XCTAssertTrue(result.appliedRewriteNames.isEmpty)
    }

    func testSpeculativePartialEmphasisOnlyRepairsTrailingTextSegment() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(
            """
            This is **not the active segment

            ```swift
            let value = "done"
            ```
            """
        )
        XCTAssertFalse(result.wasSpeculativelyRewritten)
        XCTAssertTrue(result.appliedRewriteNames.isEmpty)
    }

    func testParsesOrderedList() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(
            """
            1. First
            2. Second
            """
        )

        guard case .orderedList(_, let startIndex, let items) = result.blocks.first else {
            return XCTFail("Expected ordered list")
        }
        XCTAssertEqual(startIndex, 1)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].plainText, "First")
    }

    func testFoldsNestedListTextIntoParentItem() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(
            """
            - Parent item
              - Nested child
                Continued child detail
            - Sibling item
            """
        )

        guard case .unorderedList(_, let items) = result.blocks.first else {
            return XCTFail("Expected unordered list")
        }
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].plainText, "Parent item\nNested child Continued child detail")
        XCTAssertTrue(items[0].children.contains { child in
            if case .unorderedList = child { return true }
            return false
        })
        XCTAssertEqual(items[1].plainText, "Sibling item")
    }

    func testFoldsIndentedOrderedListTextIntoParentItem() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(
            """
            7. Parent item
               1. Nested child
                  Continued child detail
            8. Sibling item
            """
        )

        guard case .orderedList(_, let startIndex, let items) = result.blocks.first else {
            return XCTFail("Expected ordered list")
        }
        XCTAssertEqual(startIndex, 7)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].plainText, "Parent item\nNested child Continued child detail")
        XCTAssertTrue(items[0].children.contains { child in
            if case .orderedList = child { return true }
            return false
        })
        XCTAssertEqual(items[1].plainText, "Sibling item")
    }

    func testGroupsMultilineBlockQuote() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(
            """
            > First quoted line
            > second quoted line with **strong text**
            """
        )

        guard case .blockQuote(_, let children) = result.blocks.first else {
            return XCTFail("Expected block quote")
        }
        XCTAssertEqual(children.plainText, "First quoted line second quoted line with strong text")
        XCTAssertTrue(children.inlineRuns.contains { run in
            if case .strong = run { return true }
            return false
        })
    }

    func testParsesInlineAndBlockMath() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(
            """
            Inline math $x + y$.

            $$
            a^2 + b^2 = c^2
            $$
            """
        )

        guard case .paragraph(_, let runs) = result.blocks.first else {
            return XCTFail("Expected paragraph")
        }
        XCTAssertTrue(runs.contains { run in
            if case .inlineMath(_, "x + y") = run { return true }
            return false
        })
        XCTAssertTrue(result.blocks.contains { block in
            if case .blockMath(_, let latex) = block {
                return latex == "a^2 + b^2 = c^2"
            }
            return false
        })
    }

    func testParsesLimitationsFixtureAsFallbacks() async throws {
        let parser = StreamingMarkdownParser()
        let source = try readSharedFixture("limitations-showcase.md")
        let result = await parser.parse(source)

        XCTAssertTrue(result.blocks.contains { block in
            if case .paragraph(_, let runs) = block {
                return runs.plainText.contains("<aside>") && runs.plainText.contains("Raw HTML callout")
            }
            return false
        })
        XCTAssertTrue(result.blocks.contains { block in
            if case .codeBlock(_, let language, let code) = block {
                return language == "mermaid" && code.contains("flowchart TD")
            }
            return false
        })
    }

    func testPreprocessesSourceAppInlineParenthesisLatex() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(
            """
            This double integral sweeps from \\( x = 0 \\) to \\( \\pi \\).
            """
        )

        guard case .paragraph(_, let runs) = result.blocks.first else {
            return XCTFail("Expected paragraph")
        }
        XCTAssertTrue(runs.contains { run in
            if case .inlineMath(_, " x = 0 ") = run { return true }
            return false
        })
        XCTAssertTrue(runs.contains { run in
            if case .inlineMath(_, " \\pi ") = run { return true }
            return false
        })
        XCTAssertTrue(result.rewrittenText.contains("`\\( x = 0 \\)`"))
    }

    func testPreprocessesSourceAppSlashBracketBlockLatex() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(
            """
            Before
            \\[
            f'(x) = \\boxed{x} + \\dfrac{1}{2}
            \\]
            After
            """
        )

        XCTAssertTrue(result.blocks.contains { block in
            if case .blockMath(_, let latex) = block {
                return latex == "f^\\prime(x) = {x} + \\frac{1}{2}"
            }
            return false
        })
        XCTAssertTrue(result.rewrittenText.contains("```blockmath"))
    }

    func testPreprocessesSourceAppConsecutiveBlockLatex() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(
            """
            Here are formulas
            $$a^2 + b^2 = c^$$

            $$e^{i\\pi} + 1 = 0$$

            $$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$
            $$A = \\pi r^2$$

            $$f'(x) = \\lim_{h \\to 0} \\frac{f(x+h) - f(x)}{h}$$
            """
        )

        let equations = result.blockMathEquations
        XCTAssertEqual(equations.count, 5)
        XCTAssertEqual(equations[0], "a^2 + b^2 = c^")
        XCTAssertEqual(equations[1], "e^{i\\pi} + 1 = 0")
        XCTAssertEqual(equations[2], "x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}")
        XCTAssertEqual(equations[3], "A = \\pi r^2")
        XCTAssertEqual(equations[4], "f^\\prime(x) = \\lim_{h \\to 0} \\frac{f(x+h) - f(x)}{h}")
    }

    func testPreprocessesSourceAppLatexSpecificSymbols() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(
            """
            \\[
            \\varphi(x) = f(x) - \\big(f(a) + f'(a)(x-a)\\big).
            \\]

            - Vector \\(\\overrightarrow{FA} = (a+c,0)\\)

            \\[
            2+2(2q-1) = 2q^2 \\implies 2+4q-2 = 2q^2
            \\]

            \\[
            Fe^{3+}_{(aq)} + xCl^-_{(aq)} \\rightleftharpoons [FeCl_x]^{3-x}_{(aq)}
            \\]

            \\(a_1, \\dots, a_n\\)
            """
        )

        let equations = result.blockMathEquations
        XCTAssertEqual(equations[0], "\\varphi(x) = f(x) - (f(a) + f^\\prime(a)(x-a)).")
        XCTAssertEqual(equations[1], "2+2(2q-1) = 2q^2 \\Rightarrow 2+4q-2 = 2q^2")
        XCTAssertEqual(equations[2], "Fe^{3+}_{(aq)} + xCl^-_{(aq)} \\Leftrightarrow [FeCl_x]^{3-x}_{(aq)}")
        XCTAssertTrue(result.inlineMathEquations.contains("\\vec{FA} = (a+c,0)"))
        XCTAssertTrue(result.inlineMathEquations.contains("a_1, \\ldots, a_n"))
    }

    func testDoesNotTreatTableDollarSignsAsLatex() async {
        let parser = StreamingMarkdownParser()
        let source = """
        | Restaurant | Price |
        | --- | --- |
        | January | $$$$ |
        | February | $$$$ |
        """

        let result = await parser.parse(source)

        XCTAssertEqual(result.rewrittenText, source)
        XCTAssertTrue(result.blocks.contains { block in
            if case .table = block { return true }
            return false
        })
    }

    func testParsesEscapedPipesInsideTableCells() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse(
            """
            | Name | Value |
            | --- | --- |
            | A \\| B | line \\| break |
            """
        )

        guard case .table(_, let table) = result.blocks.first else {
            return XCTFail("Expected table")
        }
        XCTAssertEqual(table.headers, ["Name", "Value"])
        XCTAssertEqual(table.rows, [["A | B", "line | break"]])
    }

    func testIncompleteInlineMathStaysReadableText() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse("Pending equation $x + y is still streaming.")

        XCTAssertEqual(result.paragraphPlainText, "Pending equation $x + y is still streaming.")
        XCTAssertTrue(result.inlineMathEquations.isEmpty)
    }

    func testPipeHeavyParagraphStaysReadableText() async {
        let parser = StreamingMarkdownParser()
        let result = await parser.parse("A malformed row with | pipes | but no table marker stays readable.")

        XCTAssertEqual(result.paragraphPlainText, "A malformed row with | pipes | but no table marker stays readable.")
    }

    func testTableCSVExportEscapesCells() {
        let table = MarkdownTable(headers: ["Name", "Value"], rows: [["A", "1,2"]], rawMarkdown: "")
        XCTAssertEqual(table.csvString, "Name,Value\nA,\"1,2\"")
    }

    func testTableExportPayloadIncludesAllFormats() {
        let table = MarkdownTable(
            headers: ["Name", "Unsafe"],
            rows: [["Alpha", "<script>alert(\"x\")</script>\nNext & 'done'"]],
            rawMarkdown: ""
        )
        let payload = table.exportPayload

        XCTAssertEqual(payload.markdown, "| Name | Unsafe |\n| --- | --- |\n| Alpha | <script>alert(\"x\")</script> Next & 'done' |")
        XCTAssertEqual(payload.csv, "Name,Unsafe\nAlpha,\"<script>alert(\"\"x\"\")</script>\nNext & 'done'\"")
        XCTAssertEqual(
            payload.html,
            "<table><thead><tr><th>Name</th><th>Unsafe</th></tr></thead><tbody><tr><td>Alpha</td><td>&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;<br>Next &amp; &#39;done&#39;</td></tr></tbody></table>"
        )
        XCTAssertEqual(payload.plainText, "Name\tUnsafe\nAlpha\t<script>alert(\"x\")</script>\nNext & 'done'")
    }

    func testBundledSampleFixtureMatchesSharedFile() throws {
        XCTAssertEqual(StreamingMarkdownFixtures.mixed.text, try readSharedFixture("mixed-long-response.md"))
    }

    private func readSharedFixture(_ name: String) throws -> String {
        var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0..<6 {
            let fixture = directory.appendingPathComponent("samples/streaming-fixtures/\(name)")
            if FileManager.default.fileExists(atPath: fixture.path) {
                return try String(contentsOf: fixture, encoding: .utf8)
            }
            directory.deleteLastPathComponent()
        }
        throw FixtureError.missing(name)
    }

    private enum FixtureError: Error {
        case missing(String)
    }
}

private extension Array where Element == InlineRun {
    var plainText: String {
        map { run in
            switch run {
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
        }.joined()
    }
}

private extension Array where Element == MarkdownBlock {
    var inlineRuns: [InlineRun] {
        flatMap { block -> [InlineRun] in
            switch block {
            case .paragraph(_, let runs),
                 .heading(_, _, let runs):
                return runs
            case .blockQuote(_, let children):
                return children.inlineRuns
            case .unorderedList(_, let items),
                 .orderedList(_, _, let items):
                return items.flatMap { $0.children.inlineRuns }
            case .table,
                 .codeBlock,
                 .blockMath,
                 .horizontalRule:
                return []
            }
        }
    }
}

private extension StreamingMarkdownParseResult {
    var blockMathEquations: [String] {
        blocks.compactMap { block in
            if case .blockMath(_, let latex) = block {
                return latex
            }
            return nil
        }
    }

    var inlineMathEquations: [String] {
        inlineRuns.compactMap { run in
            if case .inlineMath(_, let latex) = run {
                return latex
            }
            return nil
        }
    }

    var citations: [Citation] {
        inlineRuns.compactMap { run in
            if case .citation(_, let citation) = run {
                return citation
            }
            return nil
        }
    }

    var paragraphPlainText: String {
        blocks.compactMap { block in
            if case .paragraph(_, let runs) = block {
                return runs.plainText
            }
            return nil
        }.joined(separator: "\n")
    }

    private var inlineRuns: [InlineRun] {
        blocks.flatMap { block -> [InlineRun] in
            switch block {
            case .paragraph(_, let runs),
                 .heading(_, _, let runs):
                return runs
            case .blockQuote(_, let children):
                return children.inlineRuns
            case .unorderedList(_, let items),
                 .orderedList(_, _, let items):
                return items.flatMap { $0.children.inlineRuns }
            case .table,
                 .codeBlock,
                 .blockMath,
                 .horizontalRule:
                return []
            }
        }
    }
}
