//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import CoreGraphics
import Foundation
@testable import SwiftStreamingMarkdown
import XCTest

final class FootnoteRenderingTests: XCTestCase {

  private let parser = MarkdownParserImpl()

  func test_footnote_rendersSuperscriptAndNotesSection() async {
    let text = """
    some text[^1] here

    [^1]: the note
    """
    let document = await parser.parse(text: text)
    let renderables = document.convert(with: .default)

    XCTAssertEqual(renderables.count, 3, "Expected paragraph + thematic break + notes list")

    guard case .paragraph(_, let content) = renderables[0] else {
      return XCTFail("Expected the first block to be a paragraph")
    }
    var superscriptText: String?
    content.enumerateAttribute(.baselineOffset, in: NSRange(location: 0, length: content.length)) { value, range, _ in
      if let offset = value as? CGFloat, offset > 0 {
        superscriptText = content.attributedSubstring(from: range).string
      }
    }
    XCTAssertEqual(superscriptText, "1", "Expected the reference to render as a raised superscript run")

    guard case .thematicBreak = renderables[1] else {
      return XCTFail("Expected a thematic break before the notes section")
    }
    guard case .orderedList(_, let items) = renderables[2] else {
      return XCTFail("Expected the notes section to render as an ordered list")
    }
    XCTAssertEqual(items.count, 1)
  }

  func test_undefinedReference_rendersLiteralText() async {
    let document = await parser.parse(text: "text[^nope]")
    let renderables = document.convert(with: .default)

    XCTAssertEqual(renderables.count, 1)
    guard case .paragraph(_, let content) = renderables[0] else {
      return XCTFail("Expected a single paragraph")
    }
    XCTAssertTrue(content.string.contains("[^nope]"))
  }

  func test_markerLookalikeWithNonNumericPayload_rendersAsInlineCode() async {
    let document = await parser.parse(text: "user-authored `[[fnref:abc]]` code")
    let renderables = document.convert(with: .default)

    guard case .paragraph(_, let content) = renderables.first else {
      return XCTFail("Expected a single paragraph")
    }
    XCTAssertTrue(content.string.contains("[[fnref:abc]]"), "Non-numeric payload must keep its inline-code text")
    content.enumerateAttribute(.baselineOffset, in: NSRange(location: 0, length: content.length)) { value, _, _ in
      if let offset = value as? CGFloat {
        XCTAssertLessThanOrEqual(offset, 0, "Non-numeric payload must not be raised as a superscript")
      }
    }
  }
}
