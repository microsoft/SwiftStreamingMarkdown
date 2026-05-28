//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown
@testable import SwiftStreamingMarkdown
import SwiftUI
import XCTest

final class UnorderedListViewTests: SnapshotTestCase {

  override func setUp() {
    super.setUp()
  }

  @MainActor
  func testUnorderedListView() async throws {
    let paragraphs = ["item 1", "item 2", "item 3, this is a very long item with a lot of texts. it may create a multi-line paragraph."]
    let parser = MarkdownParserImpl()
    var results: [[MarkdownRenderable]] = []
    for paragraph in paragraphs {
      let doc = await parser.parse(text: paragraph)
      results.append(doc.convert(with: .default, colorScheme: .light))
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
    let citationMarker = "9F742443-6C92-4C44-BF58-8F5A7C53B6F1"
    let paragraphs = [
      "item 1",
      "Item with citation [\(citationMarker)](http://example.com?citationMarker=\(citationMarker)&citationTitle=ESPN&citationFullTitle=ESPN%20Sports)",
      "item 3"
    ]
    let parser = MarkdownParserImpl()
    var results: [[MarkdownRenderable]] = []
    for paragraph in paragraphs {
      let doc = await parser.parse(text: paragraph)
      results.append(doc.convert(with: .default, colorScheme: .light))
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
}
