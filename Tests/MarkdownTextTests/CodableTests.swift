//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
@testable import SwiftStreamingMarkdown
import XCTest

/// Verifies that `RenderableDocument` round-trips through `Codable`.
///
/// `AttributedString` runs that carry an `NSTextAttachment` (inline LaTeX, citations)
/// have no Cocoa value equality — two attachments built from identical data are never
/// `==`, with or without encoding involved — so those cases assert on decoded structure
/// and plain text instead of full `RenderableDocument` equality.
final class CodableTests: XCTestCase {

  private let parser = MarkdownParserImpl()

  // MARK: - Full document round trip

  func test_fullDocument_roundTripsThroughJSON() async throws {
    let text = """
    # Heading with *italic* and **bold**

    Paragraph with **bold**, *italic*, ~~strikethrough~~, `inline code`, and a [link](https://example.com).

    1. ordered item one
    2. ordered item two

    - unordered item
    - [x] completed task
    - [ ] open task

    > outer quote
    > > nested quote

    ---

    ```swift
    let x = 1
    ```

    | header one | header two |
    | --- | --- |
    | **bold** cell | [link](https://example.com/2) |

    $$ x^2 + y^2 = z^2 $$
    """

    let document = await parser.parse(text: text)
    let renderable = await RenderableDocument(document: document, config: .default)
    XCTAssertFalse(renderable.renderables.isEmpty, "Fixture should exercise every block kind")

    let data = try JSONEncoder().encode(renderable)
    let decoded = try JSONDecoder().decode(RenderableDocument.self, from: data)

    XCTAssertEqual(renderable, decoded)
  }

  func test_emptyDocument_roundTripsThroughJSON() throws {
    let data = try JSONEncoder().encode(RenderableDocument.empty)
    let decoded = try JSONDecoder().decode(RenderableDocument.self, from: data)

    XCTAssertEqual(RenderableDocument.empty, decoded)
  }

  func test_imageRenderable_roundTripsThroughJSON() async throws {
    let config = MarkdownRenderConfig.default.withImageConfig(
      ImageConfig(enabled: true, allowedImageTypes: [.remote(allowedDomains: [])])
    )
    let document = await parser.parse(
      text: "![a logo](https://example.com/logo.png)",
      option: .init(speculativeRewrite: false, imageSupport: true)
    ).document
    let renderable = await RenderableDocument(document: document, config: config)

    guard case .image = renderable.renderables.first else {
      return XCTFail("Expected an image renderable")
    }

    let data = try JSONEncoder().encode(renderable)
    let decoded = try JSONDecoder().decode(RenderableDocument.self, from: data)

    XCTAssertEqual(renderable, decoded)
  }

  // MARK: - Attachment-bearing content
  //
  // `NSTextAttachment` compares by identity, so a freshly decoded attachment is never
  // `==` to the original even though the encode/decode itself is lossless. These tests
  // confirm the round trip doesn't throw and that the attachment survives structurally.

  func test_citationContent_roundTripsWithoutThrowing() async throws {
    let text = "See [9F742443](https://example.com?citationMarker=9F742443&citationTitle=Docs&citationA11yValue=Docs) for details."
    let document = await parser.parse(text: text)
    let renderable = await RenderableDocument(document: document, config: .default)

    let data = try JSONEncoder().encode(renderable)
    let decoded = try JSONDecoder().decode(RenderableDocument.self, from: data)

    XCTAssertEqual(renderable.renderables.count, decoded.renderables.count)
    XCTAssertEqual(renderable.plainText, decoded.plainText, "Citation title should survive the round trip")

    guard case .paragraph(_, let decodedContent) = decoded.renderables.first else {
      return XCTFail("Expected a paragraph")
    }
    let nsContent = NSAttributedString(decodedContent)
    var decodedCitations: [InlineCitationAttachment] = []
    nsContent.enumerateAttribute(.attachment, in: NSRange(location: 0, length: nsContent.length)) { value, _, _ in
      if let citation = value as? InlineCitationAttachment {
        decodedCitations.append(citation)
      }
    }

    XCTAssertEqual(decodedCitations.count, 1, "Decoded content should still carry the citation attachment")
    XCTAssertEqual(decodedCitations.first?.citationData?.title, "Docs")
  }

  func test_inlineLatexContent_roundTripsWithoutThrowing() async throws {
    let text = "Inline math \\(x^2\\) stays inline."
    let document = await parser.parse(text: text)
    let renderable = await RenderableDocument(document: document, config: .default)

    let data = try JSONEncoder().encode(renderable)
    let decoded = try JSONDecoder().decode(RenderableDocument.self, from: data)

    XCTAssertEqual(renderable.renderables.count, decoded.renderables.count)

    guard case .paragraph(_, let decodedContent) = decoded.renderables.first else {
      return XCTFail("Expected a paragraph")
    }
    let nsContent = NSAttributedString(decodedContent)
    var attachmentCount = 0
    nsContent.enumerateAttribute(.attachment, in: NSRange(location: 0, length: nsContent.length)) { value, _, _ in
      if value is NSTextAttachment { attachmentCount += 1 }
    }

    XCTAssertEqual(attachmentCount, 1, "Decoded content should still carry the inline LaTeX attachment")
  }
}
