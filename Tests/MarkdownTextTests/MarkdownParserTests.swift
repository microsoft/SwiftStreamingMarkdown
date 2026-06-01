//
//  Copyright © 2025 Microsoft. All rights reserved.
//

//
//  MarkdownParserTests.swift
//  MarkdownText
//
//  Created by Jun Yan on 6/13/25.
//
@testable import SwiftStreamingMarkdown
import SwiftUI
import XCTest

@MainActor
final class MarkdownParserTests: XCTestCase {

  let parser = MarkdownParserImpl()

  func test_rewrite() async {
    let text = """
    This is a paragraph

    ## This is a **title
    """
    var parsed = await parser.parse(text: text, option: .init(speculativeRewrite: false))
    XCTAssertFalse(parsed.speculativeRewritten)
    XCTAssertEqual(parsed.document.child(at: 1)?.childCount, 1)

    parsed = await parser.parse(text: text, option: .init(speculativeRewrite: true))
    XCTAssertTrue(parsed.speculativeRewritten)
    XCTAssertEqual(parsed.document.child(at: 1)?.childCount, 2)
  }

  //TODO: This does crash
  func skip_testTableWithExtraPipesInCellDoesNotCrash() async {
    let text = """
    | Jenis Kelamin | Jenis Tas     | Tally       | Jumlah |
    |---------------|---------------|-------------|--------|
    | Perempuan     | Tas Ransel    | ||||
    """

    let document = await parser.parse(text: text)
    let renderableDoc = await RenderableDocument(document: document, config: .default)

    guard case let .table(_, headers, rows, rawMarkdown) = renderableDoc.renderables.first else {
      XCTFail("Expected markdown to render as a table")
      return
    }

    XCTAssertEqual(headers.map(\.string), ["Jenis Kelamin", "Jenis Tas", "Tally", "Jumlah"])
    XCTAssertEqual(rows.first?.map(\.string), ["Perempuan", "Tas Ransel", "", ""])
    XCTAssertFalse(rawMarkdown.isEmpty)
  }
}
