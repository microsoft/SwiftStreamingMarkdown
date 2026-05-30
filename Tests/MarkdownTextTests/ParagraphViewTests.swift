//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown
@testable import SwiftStreamingMarkdown
import SwiftUI
import Testing
import UIKit

@Suite("ParagraphView Tests")
struct ParagraphViewTests {

  init() {
  }

  // MARK: - Helper Methods

  /// Create a simple attributed string with a citation attachment
  private func makeAttributedStringWithCitation(title: String = "ESPN") -> NSMutableAttributedString {
    // Create a proper citation URL with query parameters
    let baseURL = "http://example.com"
    let citationURL = "\(baseURL)?citationMarker=9F742443-6C92-4C44-BF58-8F5A7C53B6F1&citationTitle=\(title)&citationFullTitle=\(title)"

    guard let citationData = CitationCoder.default.decode(linkDestination: citationURL),
          let attachment = InlineCitationAttachment(citationData: citationData, citationConfig: .default) else {
      return NSMutableAttributedString(string: "")
    }

    return NSMutableAttributedString(attachment: attachment)
  }

  /// Create attributed string with text and citation
  private func makeAttributedStringWithTextAndCitation(text: String, citationTitle: String = "ESPN") -> NSMutableAttributedString {
    let result = NSMutableAttributedString(string: text)
    result.append(makeAttributedStringWithCitation(title: citationTitle))
    return result
  }

  /// Helper to create ParagraphView from NSAttributedString (for testing table cell functionality)
  private func createParagraphView(from attributedString: NSAttributedString) -> ParagraphView {
    let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
    return ParagraphView(
      contents: mutableAttributedString,
      lineSpacing: nil
    )
  }

  // MARK: - Functional Tests

  @Test("Citation in simple table cell - functional validation")
  func citationInTableSimple_functional() {
    // Create attributed string with citation using helper
    let attributedString = makeAttributedStringWithCitation(title: "ESPN")

    // Create ParagraphView
    let paragraphView = createParagraphView(from: attributedString)

    // Test functional aspects
    #expect(paragraphView.contents.length > 0, "ParagraphView should have contents")

    // Verify citation attachment exists in the content
    let textContent = paragraphView.contents
    var citationFound = false
    textContent.enumerateAttribute(NSAttributedString.Key.attachment, in: NSRange(location: 0, length: textContent.length), options: []) { (attachment, _, _) in
      if let citationAttachment = attachment as? InlineCitationAttachment,
         let citationData = citationAttachment.citationData {
        #expect(citationData.title == "ESPN", "Citation should have correct title")
        #expect(citationData.accessibilityLabel == "ESPN", "Citation should have correct accessibility label")
        citationFound = true
      }
    }
    #expect(citationFound, "Should find citation attachment in content")
  }

  @Test("Citation with regular text - functional validation")
  func citationWithRegularText_functional() {
    // Create attributed string with text and citation
    let attributedString = makeAttributedStringWithTextAndCitation(
      text: "LeBron scored 30 points according to ",
      citationTitle: "ESPN"
    )

    let paragraphView = createParagraphView(from: attributedString)

    // Should have text content
    #expect(paragraphView.contents.length > 0, "ParagraphView should have contents")

    let textContent = paragraphView.contents
    // Should have both text and citation
    #expect(textContent.string.contains("LeBron scored 30 points according to"), "Should contain regular text")

    // Check citation attachment exists
    var citationFound = false
    textContent.enumerateAttribute(NSAttributedString.Key.attachment, in: NSRange(location: 0, length: textContent.length), options: []) { (attachment, _, _) in
      if attachment is InlineCitationAttachment {
        citationFound = true
      }
    }
    #expect(citationFound, "Should find citation attachment alongside regular text")
  }

  @Test("Citation with link - functional validation")
  func citationWithLink_functional() {
    // Create attributed string with link and citation
    let attributedString = NSMutableAttributedString(string: "Visit ")

    // Add link
    let linkText = NSMutableAttributedString(string: "NBA.com")
    guard let nbaURL = URL(string: "https://nba.com") else {
      Issue.record("Failed to create NBA URL")
      return
    }
    linkText.addAttribute(.link, value: nbaURL, range: NSRange(location: 0, length: 7))
    attributedString.append(linkText)

    // Add text and citation
    attributedString.append(NSMutableAttributedString(string: " and "))
    attributedString.append(makeAttributedStringWithCitation(title: "ESPN"))
    attributedString.append(NSMutableAttributedString(string: " for info"))

    let paragraphView = createParagraphView(from: attributedString)

    // Should have text content
    #expect(paragraphView.contents.length > 0, "ParagraphView should have contents")

    let textContent = paragraphView.contents
    // Should have text, link, and citation
    var hasLink = false
    var hasCitation = false

    textContent.enumerateAttributes(in: NSRange(location: 0, length: textContent.length), options: []) { (attrs, _, _) in
      if attrs[NSAttributedString.Key.link] != nil {
        hasLink = true
      }
      if attrs[NSAttributedString.Key.attachment] is InlineCitationAttachment {
        hasCitation = true
      }
    }

    #expect(hasLink, "Should contain regular link")
    #expect(hasCitation, "Should contain citation attachment")
  }

  @Test("Two citations in same cell - functional validation")
  func twoCitationsInTable_functional() {
    // Create attributed string with two citations
    let attributedString = NSMutableAttributedString()
    attributedString.append(makeAttributedStringWithCitation(title: "ESPN"))
    attributedString.append(NSMutableAttributedString(string: " and "))
    attributedString.append(makeAttributedStringWithCitation(title: "TNT"))

    let paragraphView = createParagraphView(from: attributedString)

    // Should have text content
    #expect(paragraphView.contents.length > 0, "ParagraphView should have contents")

    let textContent = paragraphView.contents
    // Count citation attachments
    var citationCount = 0
    var espnFound = false
    var tntFound = false

    textContent.enumerateAttribute(NSAttributedString.Key.attachment, in: NSRange(location: 0, length: textContent.length), options: []) { (attachment, _, _) in
      if let citationAttachment = attachment as? InlineCitationAttachment,
         let citationData = citationAttachment.citationData {
        citationCount += 1

        if citationData.title == "ESPN" {
          espnFound = true
        } else if citationData.title == "TNT" {
          tntFound = true
        }
      }
    }

    #expect(citationCount == 2, "Should find exactly 2 citation attachments")
    #expect(espnFound, "Should find ESPN citation")
    #expect(tntFound, "Should find TNT citation")
  }

  // MARK: - Edge Case Tests for Comprehensive Coverage

  @Test("Empty table cell handling")
  func emptyTableCell() {
    let attributedString = NSMutableAttributedString(string: "")
    let paragraphView = createParagraphView(from: attributedString)

    // Should handle empty content correctly
    let textContent = paragraphView.contents
    #expect(textContent.length == 0, "Empty string should remain empty")
    #expect(textContent.string == "", "Text content should be empty")
  }

  @Test("Long text overflow handling")
  func longTextOverflow() {
    let longText = String(repeating: "This is a very long text that should test overflow behavior. ", count: 20)
    let attributedString = NSMutableAttributedString(string: longText)
    let paragraphView = createParagraphView(from: attributedString)

    // Should have text content
    #expect(paragraphView.contents.length > 0, "ParagraphView should have contents")

    let textContent = paragraphView.contents
    #expect(textContent.length > 0, "Long text should not be empty")
    #expect(textContent.string.contains("This is a very long text"), "Should contain original text")
  }

  @Test("Special characters and unicode handling")
  func specialCharactersAndUnicode() {
    let specialText = "Test with émojis 🧮, unicode çhars, and symbols: ±∞≤≥∑∫"
    let attributedString = NSMutableAttributedString(string: specialText)
    let paragraphView = createParagraphView(from: attributedString)

    // Should have text content
    #expect(paragraphView.contents.length > 0, "ParagraphView should have contents")

    let textContent = paragraphView.contents
    #expect(textContent.string.contains("🧮"), "Should preserve emojis")
    #expect(textContent.string.contains("émojis"), "Should preserve unicode characters")
    #expect(textContent.string.contains("±∞≤≥∑∫"), "Should preserve mathematical symbols")
  }

  @Test("Mixed content with all element types")
  func mixedContentAllTypes() {
    // Create complex attributed string with text, link, and citation
    let attributedString = NSMutableAttributedString(string: "Text with ")

    // Add link
    let linkText = NSMutableAttributedString(string: "documentation")
    guard let devURL = URL(string: "https://developer.apple.com") else {
      Issue.record("Failed to create developer URL")
      return
    }
    linkText.addAttribute(.link, value: devURL, range: NSRange(location: 0, length: 13))
    attributedString.append(linkText)

    // Add more text and citation
    attributedString.append(NSMutableAttributedString(string: " and "))
    attributedString.append(makeAttributedStringWithCitation(title: "Source"))

    let paragraphView = createParagraphView(from: attributedString)

    // Should have text content
    #expect(paragraphView.contents.length > 0, "ParagraphView should have contents")

    let textContent = paragraphView.contents
    // Verify all content types exist
    var hasLink = false
    var hasCitation = false
    var hasRegularText = false

    textContent.enumerateAttributes(in: NSRange(location: 0, length: textContent.length), options: []) { (attrs, _, _) in
      if attrs[NSAttributedString.Key.link] != nil {
        hasLink = true
      }
      if attrs[NSAttributedString.Key.attachment] is InlineCitationAttachment {
        hasCitation = true
      }
    }

    hasRegularText = textContent.string.contains("Text with") && textContent.string.contains(" and ")

    #expect(hasLink, "Should contain link")
    #expect(hasCitation, "Should contain citation")
    #expect(hasRegularText, "Should contain regular text")
  }

  @Test("Citation data integrity")
  func citationDataIntegrity() {
    let citation = makeAttributedStringWithCitation(title: "Test Source")
    let paragraphView = createParagraphView(from: citation)

    // Should have text content
    #expect(paragraphView.contents.length > 0, "ParagraphView should have contents")

    let textContent = paragraphView.contents
    var citationData: InlineAttachmentData?
    textContent.enumerateAttribute(NSAttributedString.Key.attachment, in: NSRange(location: 0, length: textContent.length), options: []) { (attachment, _, _) in
      if let citationAttachment = attachment as? InlineCitationAttachment {
        citationData = citationAttachment.citationData
      }
    }

    #expect(citationData != nil, "Should have citation data")
    #expect(citationData?.title == "Test Source", "Should preserve citation title")
    #expect(citationData?.accessibilityLabel == "Test Source", "Should preserve accessibility label")
    #expect(citationData?.url != nil, "Should have valid URL")
  }
}
