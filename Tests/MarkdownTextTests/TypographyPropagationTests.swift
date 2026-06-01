//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown
@testable import SwiftStreamingMarkdown
import UIKit
import XCTest

@MainActor
final class TypographyPropagationTests: XCTestCase {
  let parser: MarkdownParser = MarkdownParserImpl()

  func testHeaderTypographyPropagation() async throws {
    let text = "# This is a *header*"
    let document = await parser.parse(text: text)

    // Check if the document has a Heading
    guard let heading = document.child(at: 0) as? Heading else {
      XCTFail("Should have a heading")
      return
    }

    // Convert the heading to renderable
    let config = MarkdownRenderConfig.default
    // Headings use different typography based on level.
    // Level 1 maps to extraLargeTextFonts in the rendering logic.
    let headingFonts = Typography.extraLargeTextFonts

    let renderable = heading.convert(attributeContainer: .init(), config: config)

    if case .heading(_, let level, let attributedString) = renderable {
      XCTAssertEqual(level, 1)

      // The attributed string should have the .font attribute set to extraLarge normal
      // and for the italic part, it should be extraLarge italic.

      // Find the range of "header" (which is italicized)
      let string = attributedString.string
      guard let headerRange = string.range(of: "header") else {
        XCTFail("Should find 'header' in string")
        return
      }
      let nsHeaderRange = NSRange(headerRange, in: string)

      // Check attribute for "This is a "
      let regularFont = attributedString.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
      XCTAssertEqual(regularFont, headingFonts.normal)

      // Check attribute for "header"
      let italicFont = attributedString.attribute(.font, at: nsHeaderRange.location, effectiveRange: nil) as? UIFont
      XCTAssertEqual(italicFont, headingFonts.italic)
    } else {
      XCTFail("Renderable should be a heading")
    }
  }

  func testStrongItalicTypographyPropagation() async throws {
    let text = "Text with ***strong italic***"
    let document = await parser.parse(text: text)

    guard let paragraph = document.child(at: 0) as? Paragraph else {
      XCTFail("Should have a paragraph")
      return
    }

    let config = MarkdownRenderConfig.default
    let renderable = paragraph.convert(attributeContainer: .init(), config: config)

    if case .paragraph(_, let attributedString) = renderable {
      let string = attributedString.string
      guard let strongItalicRange = string.range(of: "strong italic") else {
        XCTFail("Should find 'strong italic' in string")
        return
      }
      let nsRange = NSRange(strongItalicRange, in: string)

      let font = attributedString.attribute(.font, at: nsRange.location, effectiveRange: nil) as? UIFont
      XCTAssertEqual(font, Typography.baseTextFonts.boldItalic)
    } else {
      XCTFail("Renderable should be a paragraph")
    }
  }
}
