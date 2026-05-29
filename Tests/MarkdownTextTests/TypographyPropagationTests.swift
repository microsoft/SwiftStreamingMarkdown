//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown
@testable import SwiftStreamingMarkdown
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
    // Level 1 usually maps to extraLarge or similar in the rendering logic.
    let baseTypography = Typography.extraLarge // This is the expected base for H1

    let renderable = heading.convert(attributeContainer: .init(), config: config, colorScheme: .light)

    if case .heading(_, let level, let attributedString) = renderable {
      XCTAssertEqual(level, 1)

      // The attributed string should have the .typography attribute set to extraLarge
      // and for the italic part, it should be extraLargeItalic

      let fullRange = NSRange(location: 0, length: attributedString.length)

      // Find the range of "header" (which is italicized)
      let string = attributedString.string
      guard let headerRange = string.range(of: "header") else {
        XCTFail("Should find 'header' in string")
        return
      }
      let nsHeaderRange = NSRange(headerRange, in: string)

      // Check attribute for "This is a "
      let regularFont = attributedString.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
      XCTAssertEqual(regularFont, baseTypography.uiFont)

      // Check attribute for "header"
      let italicFont = attributedString.attribute(.font, at: nsHeaderRange.location, effectiveRange: nil) as? UIFont
      XCTAssertEqual(italicFont, Typography.extraLargeItalic.uiFont)
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
    let renderable = paragraph.convert(attributeContainer: .init(), config: config, colorScheme: .light)

    if case .paragraph(_, let attributedString) = renderable {
      let string = attributedString.string
      guard let strongItalicRange = string.range(of: "strong italic") else {
        XCTFail("Should find 'strong italic' in string")
        return
      }
      let nsRange = NSRange(strongItalicRange, in: string)

      let font = attributedString.attribute(.font, at: nsRange.location, effectiveRange: nil) as? UIFont
      XCTAssertEqual(font, Typography.baseStrongItalic.uiFont)
    } else {
      XCTFail("Renderable should be a paragraph")
    }
  }
}
