//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
@testable import SwiftStreamingMarkdown
import XCTest

final class ExtractPlainTextTests: XCTestCase {

  // MARK: - Formatting Tests

  func testExtractPlainTextFromMixedFormatting() async {
    let markdown = "This has **bold**, *italic* text"
    let result = await markdown.markdownToPlainText()
    XCTAssertEqual(result, "This has bold, italic text")
  }

  // MARK: - Link Tests

  func testExtractPlainTextFromMultipleLinks() async {
    let markdown = "Check out [Google](https://google.com) and [GitHub](https://github.com)"
    let result = await markdown.markdownToPlainText()
    XCTAssertEqual(result, "Check out Google and GitHub")
  }

  // MARK: - List Tests

  func testExtractPlainTextFromUnorderedList() async {
    let markdown = """
    - Item 1
    - Item 2
    - Item 3
    """
    let result = await markdown.markdownToPlainText()
    XCTAssertEqual(result, "• Item 1\n• Item 2\n• Item 3")
  }

  // MARK: - Citation Tests

  func testExtractPlainTextFromRegularCitation() async {
    let markdown = "[Microsoft](http://example.com?citationMarker=9F742443)"
    let result = await markdown.markdownToPlainText()
    XCTAssertEqual(result, "Microsoft", "Regular citations should show the link text")
  }

  func testExtractPlainTextFromAttachmentCitation() async {
    let markdown = "[9F742443](http://example.com?citationMarker=9F742443&citationTitle=Microsoft&citationA11yValue=Microsoft)"
    let result = await markdown.markdownToPlainText()
    XCTAssertEqual(result, "Microsoft", "Attachment citations should extract title from URL parameters, not show UUID")
  }

  func testExtractPlainTextFromMultipleCitations() async {
    let markdown = "Check [Microsoft](http://example.com?citationMarker=9F742443) and [9F742443](http://example.com?citationMarker=9F742443&citationTitle=Google&citationA11yValue=Google)"
    let result = await markdown.markdownToPlainText()
    XCTAssertEqual(result, "Check Microsoft and Google", "Should handle both old and new citation formats")
  }

  // MARK: - BlockQuote Tests

  func testExtractPlainTextFromBlockQuoteWithRegularCitation() async {
    let markdown = """
    > This quote contains [Microsoft](http://example.com?citationMarker=9F742443)
    """
    let result = await markdown.markdownToPlainText()
    XCTAssertEqual(result, "This quote contains Microsoft", "BlockQuote should show citation text, not UUID")
  }

  func testExtractPlainTextFromBlockQuoteWithAttachmentCitation() async {
    let markdown = """
    > This quote contains [9F742443](http://example.com?citationMarker=9F742443&citationTitle=Microsoft&citationA11yValue=Microsoft)
    """
    let result = await markdown.markdownToPlainText()
    XCTAssertEqual(result, "This quote contains Microsoft", "BlockQuote with attachment citation should extract title from URL, not show UUID")
  }

  func testExtractPlainTextFromNestedBlockQuoteWithCitations() async {
    let markdown = """
    > Level 1 with [Microsoft](http://example.com?citationMarker=9F742443)
    > > Level 2 with [9F742443](http://example.com?citationMarker=9F742443&citationTitle=Google&citationA11yValue=Google)
    """
    let result = await markdown.markdownToPlainText()
    XCTAssertTrue(result.contains("Microsoft"), "Nested BlockQuote should handle regular citations")
    XCTAssertTrue(result.contains("Google"), "Nested BlockQuote should handle attachment citations")
    XCTAssertFalse(result.contains("9F742443"), "Should not show UUID in plain text")
  }
}
