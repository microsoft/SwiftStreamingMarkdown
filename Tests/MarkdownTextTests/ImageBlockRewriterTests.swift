//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Markdown
@testable import SwiftStreamingMarkdown
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable force_cast
final class ImageBlockRewriterTests: XCTestCase {

  private func rewrite(_ text: String) -> Document {
    var rewriter = ImageBlockRewriter()
    let document = Document(parsing: text)
    return rewriter.visit(document) as! Document
  }

  func test_paragraph_with_leading_text_and_image_is_split() {
    let rewritten = rewrite("hello ![alt](https://example.com/a.png)")

    XCTAssertEqual(rewritten.childCount, 2)

    let first = rewritten.child(at: 0) as? Paragraph
    XCTAssertEqual(first?.plainText, "hello ")
    XCTAssertNil(first?.child(at: 0) as? Image)

    let second = rewritten.child(at: 1) as? Paragraph
    XCTAssertEqual(second?.childCount, 1)
    let image = second?.child(at: 0) as? Image
    XCTAssertEqual(image?.source, "https://example.com/a.png")
  }

  func test_image_surrounded_by_text_is_split_into_three_paragraphs() {
    let rewritten = rewrite("before ![alt](https://example.com/a.png) after")

    XCTAssertEqual(rewritten.childCount, 3)

    XCTAssertEqual((rewritten.child(at: 0) as? Paragraph)?.plainText, "before ")

    let middle = rewritten.child(at: 1) as? Paragraph
    XCTAssertEqual((middle?.child(at: 0) as? Image)?.source, "https://example.com/a.png")

    XCTAssertEqual((rewritten.child(at: 2) as? Paragraph)?.plainText, " after")
  }

  func test_multiple_images_with_text_between_are_each_isolated() {
    let rewritten = rewrite("a ![one](https://example.com/1.png) b ![two](https://example.com/2.png) c")

    XCTAssertEqual(rewritten.childCount, 5)

    XCTAssertEqual((rewritten.child(at: 0) as? Paragraph)?.plainText, "a ")
    XCTAssertEqual(((rewritten.child(at: 1) as? Paragraph)?.child(at: 0) as? Image)?.source, "https://example.com/1.png")
    XCTAssertEqual((rewritten.child(at: 2) as? Paragraph)?.plainText, " b ")
    XCTAssertEqual(((rewritten.child(at: 3) as? Paragraph)?.child(at: 0) as? Image)?.source, "https://example.com/2.png")
    XCTAssertEqual((rewritten.child(at: 4) as? Paragraph)?.plainText, " c")
  }

  func test_image_only_paragraph_is_left_unchanged() {
    let rewritten = rewrite("![alt](https://example.com/a.png)")

    XCTAssertEqual(rewritten.childCount, 1)
    let paragraph = rewritten.child(at: 0) as? Paragraph
    XCTAssertEqual(paragraph?.childCount, 1)
    XCTAssertEqual((paragraph?.child(at: 0) as? Image)?.source, "https://example.com/a.png")
  }

  func test_paragraph_without_image_is_left_unchanged() {
    let rewritten = rewrite("just some **bold** text")

    XCTAssertEqual(rewritten.childCount, 1)
    let paragraph = rewritten.child(at: 0) as? Paragraph
    XCTAssertNotNil(paragraph)
    XCTAssertNil(paragraph?.children.first { $0 is Image })
  }
}
