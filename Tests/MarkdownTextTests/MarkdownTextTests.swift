//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown
@testable import SwiftStreamingMarkdown
import SwiftUI
import UIKit
import XCTest

@MainActor
final class MarkdownTextTests: XCTestCase {

  let parser: MarkdownParser = MarkdownParserImpl()

  /// Tests regular citation format (old format) by directly testing the convert method
  func testRegularCitationFormat() async throws {
    let markdown = """
    [Microsoft](http://example.com?citationMarker=9F742443-6C92-4C44-BF58-8F5A7C53B6F1)
    """

    let document = await parser.parse(text: markdown)

    // Find the link in the parsed document
    var link: Markdown.Link?
    for child in document.children {
      if let paragraph = child as? Markdown.Paragraph {
        for paragraphChild in paragraph.children {
          if let foundLink = paragraphChild as? Markdown.Link {
            link = foundLink
            break
          }
        }
      }
      if link != nil { break }
    }

    guard let link = link else {
      XCTFail("Expected to find a link in the parsed markdown")
      return
    }

    // Verify this is NOT an attachment citation (it's a regular citation)
    XCTAssertFalse(link.isAttachmentCitation, "Link should NOT be detected as attachment citation")

    // Test the convert method directly
    let attributeContainer: [NSAttributedString.Key: Any] = [:]
    let convertedString = link.convert(
      attributeContainer: attributeContainer,
      config: .default,
      colorScheme: .light
    )

    // Regular citations should show the link text "Microsoft", not the internal marker
    XCTAssertTrue(
      convertedString.string.contains("Microsoft"),
      "DIRECT convert() call should return the link text for regular citations. Got: '\(convertedString.string)'"
    )
    XCTAssertFalse(
      convertedString.string.contains("9F742443-6C92-4C44-BF58-8F5A7C53B6F1"),
      "Regular citations should not show the internal marker UUID"
    )
  }

  /// Tests attachment citation format by directly testing the convert method
  func testAttachmentCitationFormat() async throws {
    let markdown = """
    [9F742443-6C92-4C44-BF58-8F5A7C53B6F1](http://example.com?citationMarker=9F742443-6C92-4C44-BF58-8F5A7C53B6F1&citationTitle=Microsoft&citationFullTitle=Microsoft)
    """

    let document = await parser.parse(text: markdown)

    // Find the link in the parsed document - need to traverse children properly
    var link: Markdown.Link?
    for child in document.children {
      if let paragraph = child as? Markdown.Paragraph {
        for paragraphChild in paragraph.children {
          if let foundLink = paragraphChild as? Markdown.Link {
            link = foundLink
            break
          }
        }
      }
      if link != nil { break }
    }

    guard let link = link else {
      XCTFail("Expected to find a link in the parsed markdown")
      return
    }

    // Verify this is an attachment citation
    XCTAssertTrue(link.isAttachmentCitation, "Link should be detected as attachment citation")

    // Test the convert method directly - this should expose the bug
    let attributeContainer: [NSAttributedString.Key: Any] = [:]
    let convertedString = link.convert(
      attributeContainer: attributeContainer,
      config: .default,
      colorScheme: .light
    )

    // Verify that we get an attachment, not plain text
    XCTAssertEqual(convertedString.length, 1, "Should have exactly one attachment character")

    // Get the attachment and verify it contains the correct data
    var attachmentFound = false
    convertedString.enumerateAttribute(.attachment, in: NSRange(location: 0, length: convertedString.length), options: []) { (attachment, _, _) in
      if let citationAttachment = attachment as? InlineCitationAttachment,
         let citationData = citationAttachment.citationData {
        XCTAssertEqual(citationData.title, "Microsoft", "Citation attachment should contain title 'Microsoft'")
        XCTAssertEqual(citationData.accessibilityLabel, "Microsoft", "Citation attachment should have accessibility label 'Microsoft'")
        attachmentFound = true
      }
    }

    XCTAssertTrue(attachmentFound, "Should find a citation attachment with proper data")
  }

  /// Tests fallback behavior when attachment citation data is malformed
  func testAttachmentCitationFallbackBehavior() async throws {
    // Malformed attachment citation - missing citationTitle parameter
    let markdown = """
    [9F742443-6C92-4C44-BF58-8F5A7C53B6F1](http://example.com?citationMarker=9F742443-6C92-4C44-BF58-8F5A7C53B6F1&brokenParam=value)
    """

    let document = await parser.parse(text: markdown)

    // Find the link in the parsed document
    var link: Markdown.Link?
    for child in document.children {
      if let paragraph = child as? Markdown.Paragraph {
        for paragraphChild in paragraph.children {
          if let foundLink = paragraphChild as? Markdown.Link {
            link = foundLink
            break
          }
        }
      }
      if link != nil { break }
    }

    guard let link = link else {
      XCTFail("Expected to find a link in the parsed markdown")
      return
    }

    // Verify this is an attachment citation (UUID in link text)
    XCTAssertTrue(link.isAttachmentCitation, "Link should be detected as attachment citation")

    // Test the convert method - should return empty for malformed attachment citations
    let attributeContainer: [NSAttributedString.Key: Any] = [:]
    let convertedString = link.convert(
      attributeContainer: attributeContainer,
      config: .default,
      colorScheme: .light
    )

    // Should return empty string when attachment data extraction fails (better UX than showing UUID)
    XCTAssertEqual(
      convertedString.string,
      "",
      "Malformed attachment citations should return empty string rather than showing confusing UUIDs to users"
    )
  }

  // MARK: - BlockQuote Citation Integration Tests

  /// Tests that BlockQuote correctly renders attachment citations without showing UUIDs
  func testBlockQuoteWithAttachmentCitations() async throws {
    let markdown = """
    > This quote contains an attachment citation [9F742443-6C92-4C44-BF58-8F5A7C53B6F1](http://example.com?citationMarker=9F742443-6C92-4C44-BF58-8F5A7C53B6F1&citationTitle=Microsoft&citationFullTitle=Microsoft) and regular citation [Google](http://example.com?citationMarker=9F742443-6C92-4C44-BF58-8F5A7C53B6F1)
    """

    let document = await parser.parse(text: markdown)

    // Find the BlockQuote in the parsed document
    var blockQuote: BlockQuote?
    for child in document.children {
      if let foundBlockQuote = child as? BlockQuote {
        blockQuote = foundBlockQuote
        break
      }
    }

    guard let blockQuote = blockQuote else {
      XCTFail("Expected to find a BlockQuote in the parsed markdown")
      return
    }

    // Test the quoteTypes property (this was the main bug)
    let quoteTypes = blockQuote.quoteTypes

    // Extract the text from the quote types
    var extractedText = ""
    switch quoteTypes {
    case .nested(let types):
      for type in types {
        switch type {
        case .text(let text):
          extractedText = text
        default:
          break
        }
      }
    default:
      XCTFail("Expected nested quote types")
    }

    // Verify that the extracted text contains the citation titles, not UUIDs
    XCTAssertTrue(
      extractedText.contains("Microsoft"),
      "BlockQuote should show attachment citation title 'Microsoft', not UUID. Got: '\(extractedText)'"
    )
    XCTAssertTrue(
      extractedText.contains("Google"),
      "BlockQuote should show regular citation title 'Google'. Got: '\(extractedText)'"
    )
    XCTAssertFalse(
      extractedText.contains("9F742443-6C92-4C44-BF58-8F5A7C53B6F1"),
      "BlockQuote should NOT show the UUID marker in plain text. Got: '\(extractedText)'"
    )
  }

  /// Tests that plain text extraction works correctly for both citation types
  func testPlainTextExtractionForCitations() async throws {
    let markdownWithBothTypes = """
    Regular citation: [Microsoft](http://example.com?citationMarker=9F742443-6C92-4C44-BF58-8F5A7C53B6F1)

    Attachment citation: [9F742443-6C92-4C44-BF58-8F5A7C53B6F1](http://example.com?citationMarker=9F742443-6C92-4C44-BF58-8F5A7C53B6F1&citationTitle=Google&citationFullTitle=Google)
    """

    let plainText = await markdownWithBothTypes.markdownToPlainText()

    // Verify both citation types show proper titles
    XCTAssertTrue(
      plainText.contains("Microsoft"),
      "Plain text should show regular citation title. Got: '\(plainText)'"
    )
    XCTAssertTrue(
      plainText.contains("Google"),
      "Plain text should show attachment citation title extracted from URL. Got: '\(plainText)'"
    )
    XCTAssertFalse(
      plainText.contains("9F742443-6C92-4C44-BF58-8F5A7C53B6F1"),
      "Plain text should NOT contain UUID marker. Got: '\(plainText)'"
    )
  }

  func testMarkdownNestedFormatting() async throws {
    let text = """
    # Header with *italic* and **bold** and ***both***

    Normal text with ***bold italic*** and **nested *italic* inside** bold.
    """

    let document = await parser.parse(text: text)
    let renderableDoc = await RenderableDocument(document: document, config: .default, colorScheme: .light)
    let renderables = renderableDoc.renderables

    // Verify it parses without error
    XCTAssertEqual(renderables.count, 2)

    let headingFonts = Typography.extraLargeTextFonts
    let paragraphFonts = Typography.baseTextFonts

    // 1. Inspect Heading
    guard case let .heading(_, level, headingContent) = renderables[0] else {
      XCTFail("First renderable should be a heading")
      return
    }
    XCTAssertEqual(level, 1)

    // Check that "italic" has italic font
    let italicRange = (headingContent.string as NSString).range(of: "italic")
    let italicFont = headingContent.attribute(.font, at: italicRange.location, effectiveRange: nil) as? UIFont
    XCTAssertEqual(italicFont, headingFonts.italic)

    // Check that "bold" has bold font
    let boldRange = (headingContent.string as NSString).range(of: "bold")
    let boldFont = headingContent.attribute(.font, at: boldRange.location, effectiveRange: nil) as? UIFont
    XCTAssertEqual(boldFont, headingFonts.bold)

    // Check that "both" has boldItalic font (nested Strong(Emphasis) resolves to boldItalic)
    let bothRange = (headingContent.string as NSString).range(of: "both")
    let bothFont = headingContent.attribute(.font, at: bothRange.location, effectiveRange: nil) as? UIFont
    XCTAssertEqual(bothFont, headingFonts.boldItalic)

    // 2. Inspect Paragraph
    guard case let .paragraph(_, paragraphContent) = renderables[1] else {
      XCTFail("Second renderable should be a paragraph")
      return
    }

    // Check "nested " (part of **nested *italic* inside**)
    let nestedRange = (paragraphContent.string as NSString).range(of: "nested ")
    let nestedFont = paragraphContent.attribute(.font, at: nestedRange.location, effectiveRange: nil) as? UIFont
    XCTAssertEqual(nestedFont, paragraphFonts.bold)

    // Check "italic" (nested inside bold) -> boldItalic
    let nestedItalicRange = (paragraphContent.string as NSString).range(of: "italic")
    let nestedItalicFont = paragraphContent.attribute(.font, at: nestedItalicRange.location, effectiveRange: nil) as? UIFont
    XCTAssertEqual(nestedItalicFont, paragraphFonts.boldItalic)
  }
}
