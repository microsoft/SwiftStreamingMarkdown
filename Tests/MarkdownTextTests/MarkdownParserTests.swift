//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
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

  func test_imageSupport_disabled_keeps_image_inline() async {
    let text = """
beforebeforebeforebeforebefore

middlemiddle![alt](https://example.com/img.png)middlemiddlemiddlemiddle

afterafterafterafterafterafter
"""

    let parsed = await parser.parse(text: text, option: .init(speculativeRewrite: false))
    XCTAssertEqual(parsed.document.childCount, 3)
    XCTAssertEqual(parsed.document.child(at: 1)?.childCount, 3)
  }

  func test_imageSupport_enabled_splits_image_into_block_paragraphs() async {
    let text = """
beforebeforebeforebeforebefore

middlemiddle![alt](https://example.com/img.png)middlemiddlemiddlemiddle

afterafterafterafterafterafter
"""

    let parsed = await parser.parse(
      text: text,
      option: .init(speculativeRewrite: false, imageSupport: true)
    )

    XCTAssertEqual(parsed.document.childCount, 5)
    XCTAssertFalse(parsed.speculativeRewritten)
  }
}
