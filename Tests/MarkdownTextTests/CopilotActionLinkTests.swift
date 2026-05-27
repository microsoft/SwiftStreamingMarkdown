//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown
@testable import SwiftStreamingMarkdown
import SwiftUI
import XCTest

final class CopilotActionLinkTests: XCTestCase {
  private let parser: MarkdownParser = MarkdownParserImpl()

  func testCopilotActionLinkSchemeDetection() {
    XCTAssertTrue(URL(string: "copilot-action://composer_prefill?text=hello")?.isCopilotActionLink == true)
    XCTAssertTrue(URL(string: "COPILOT-ACTION://composer_prefill?text=hello")?.isCopilotActionLink == true)
    XCTAssertFalse(URL(string: "https://example.com")?.isCopilotActionLink == true)
  }

  func testCopilotActionShortSchemeDetection() {
    XCTAssertTrue(URL(string: "ca://composer_prefill?text=hello")?.isCopilotActionLink == true)
    XCTAssertTrue(URL(string: "CA://composer_prefill?text=hello")?.isCopilotActionLink == true)
  }

  func testCopilotActionLinkConversion() async throws {
    let markdown = "Click here to [learn more](copilot-action://composer_prefill?text=hello)"
    let link = try await extractSingleLink(from: markdown)
    let convertedString = link.convert(attributeContainer: [:], config: .default, colorScheme: .light)

    XCTAssertEqual(convertedString.string, "learn more", "Copilot action link should render as inline text")

    let fullRange = NSRange(location: 0, length: convertedString.length)
    var linkURL: URL?
    convertedString.enumerateAttribute(.link, in: fullRange, options: []) { value, _, _ in
      linkURL = value as? URL
    }

    XCTAssertNotNil(linkURL, "Should have a .link attribute")
    XCTAssertTrue(linkURL?.isCopilotActionLink == true, "Link URL should be a copilot action link")

    var underlineStyle: NSUnderlineStyle?
    convertedString.enumerateAttribute(.underlineStyle, in: fullRange, options: []) { value, _, _ in
      if let rawValue = value as? Int {
        underlineStyle = NSUnderlineStyle(rawValue: rawValue)
      }
    }

    XCTAssertNotNil(underlineStyle, "Should have an underline style")
    XCTAssertEqual(
      underlineStyle,
      NSUnderlineStyle.single.union(.patternDot),
      "Underline style should be single + patternDot"
    )
  }

  func testShortCopilotActionLinkConversion() async throws {
    let markdown = "Click here to [learn more](ca://composer_prefill?text=hello)"
    let link = try await extractSingleLink(from: markdown)
    let convertedString = link.convert(attributeContainer: [:], config: .default, colorScheme: .light)

    XCTAssertEqual(convertedString.string, "learn more", "Short copilot action link should render as inline text")

    let fullRange = NSRange(location: 0, length: convertedString.length)
    var linkURL: URL?
    convertedString.enumerateAttribute(.link, in: fullRange, options: []) { value, _, _ in
      linkURL = value as? URL
    }

    XCTAssertNotNil(linkURL, "Should have a .link attribute")
    XCTAssertTrue(linkURL?.isCopilotActionLink == true, "Link URL should be a copilot action link")
  }

  func testMalformedCopilotActionLinkFallsBackToPlainText() async throws {
    let markdown = "Click here to [learn more](copilot-action://?text=hello)"
    let link = try await extractSingleLink(from: markdown)
    let convertedString = link.convert(attributeContainer: [:], config: .default, colorScheme: .light)

    XCTAssertEqual(convertedString.string, "learn more", "Malformed copilot action links should still render text")

    let fullRange = NSRange(location: 0, length: convertedString.length)
    var hasLinkAttribute = false
    convertedString.enumerateAttribute(.link, in: fullRange, options: []) { value, _, _ in
      if value != nil {
        hasLinkAttribute = true
      }
    }

    XCTAssertFalse(hasLinkAttribute, "Malformed copilot action links should not produce a tappable .link attribute")
  }

  private func extractSingleLink(from markdown: String) async throws -> Markdown.Link {
    let document = await parser.parse(text: markdown)

    for child in document.children {
      guard let paragraph = child as? Markdown.Paragraph else { continue }
      for paragraphChild in paragraph.children {
        if let link = paragraphChild as? Markdown.Link {
          return link
        }
      }
    }

    XCTFail("Expected to find a link in the parsed markdown")
    throw NSError(domain: "CopilotActionLinkTests", code: 1)
  }
}
