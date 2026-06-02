//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown
@testable import SwiftStreamingMarkdown
import SwiftUI
import XCTest

final class UnorderedListViewTests: SnapshotTestCase {

  @MainActor
  func testUnorderedListView() async throws {
    let paragraphs = ["item 1", "item 2", "item 3, this is a very long item with a lot of texts. it may create a multi-line paragraph."]
    let parser = MarkdownParserImpl()
    var results: [[MarkdownRenderable]] = []
    for paragraph in paragraphs {
      let doc = await parser.parse(text: paragraph)
      results.append(doc.convert(with: .default))
    }
    let unorderedListView = UnorderedListView(items: [
      MarkdownListItem(children: [results[0][0]],
                       startsWithBold: false),
      MarkdownListItem(children: [results[1][0]],
                       startsWithBold: false),
      MarkdownListItem(children: [results[2][0]],
                       startsWithBold: false)
    ],
    nestedLevel: 0).padding()

    let view = CanvasView {
      unorderedListView
    }.environment(\.markdownConfig, MarkdownRenderConfig.default)

    assert(view)
  }

  @MainActor
  func testUnorderedListViewWithCitations() async throws {
    let citationMarker = "9F742443"
    let paragraphs = [
      "item 1",
      "Item with citation [\(citationMarker)](http://example.com?citationMarker=\(citationMarker)&citationTitle=ESPN&citationA11yValue=ESPN%20Sports)",
      "item 3"
    ]
    let parser = MarkdownParserImpl()
    var results: [[MarkdownRenderable]] = []
    for paragraph in paragraphs {
      let doc = await parser.parse(text: paragraph)
      results.append(doc.convert(with: .default))
    }
    let unorderedListView = UnorderedListView(items: [
      MarkdownListItem(children: [results[0][0]],
                       startsWithBold: false),
      MarkdownListItem(children: [results[1][0]],
                       startsWithBold: false),
      MarkdownListItem(children: [results[2][0]],
                       startsWithBold: false)
    ],
    nestedLevel: 0).padding()

    let view = CanvasView {
      unorderedListView
    }.environment(\.markdownConfig, MarkdownRenderConfig.default)

    assert(view)
  }

  @MainActor
  func testNestedUnorderedListView() async throws {
    let text = """
    - Top level item 1
      - Nested item A
        - Deeply nested item X
        - Deeply nested item Y with a longer trailing description to exercise wrapping
      - Nested item B
    - Top level item 2
      - Nested item C
    """
    let parser = MarkdownParserImpl()
    let document = await parser.parse(text: text)
    let renderables = document.convert(with: .default)
    guard case .unorderedList(_, let items, let nestedLevel) = renderables.first else {
      XCTFail("Expected the parsed document to start with an unordered list")
      return
    }

    let view = CanvasView {
      UnorderedListView(items: items, nestedLevel: nestedLevel).padding()
    }.environment(\.markdownConfig, MarkdownRenderConfig.default)

    assert(view)
  }
}
