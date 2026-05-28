//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown
@testable import SwiftStreamingMarkdown
import SwiftUI
import UIKit
import XCTest

@MainActor
final class MarkdownTextSnapshotTests: SnapshotTestCase {

  let parser: MarkdownParser = MarkdownParserImpl()

  override func setUp() {
    super.setUp()
  }

  func testMarkdownLists_uikit() async throws {
    let text = """
     I found some resources that can help you compare gyms in your neighborhood. Here's a brief overview:

    1. **The Ultimate Gym Guide** provides a comprehensive database of gyms where you can compare amenities, locations with pools, saunas, childcare, and more.
    2. **Best Gyms Near Me** on Yelp lists gyms with a variety of classes, equipment, and amenities, from budget-friendly options to high-end gyms with all the bells and whistles.

    You can visit these sites to get detailed information on **membership prices** and **amenities** for each gym. Remember to consider what's most important for your fitness routine when making your decision!

    Here are some other lists:
    - **The Ultimate Gym Guide** provides a comprehensive database of gyms where you can compare amenities, locations with pools, saunas, childcare, and more.
    - **Best Gyms Near Me** on Yelp lists gyms with a variety of classes, equipment, and amenities, from budget-friendly options to high-end gyms with all the bells and whistles.

    """

    let document = await parser.parse(text: text)
    let renderables = await RenderableDocument(document: document, config: .default, colorScheme: .light)
    let view = CanvasView {
      DocumentView(renderableDocument: renderables, config: .init()).padding(.horizontal, 24)
    }
    assert(view)
  }

  func testMarkdownWithLatex() async throws {
    let text = """
    This is a **test** string _with_ Latex content:
    $$x+2=3$$
    and more
    $$LaTeX$$
    $$x^2 + 2x + 3$$
    how about that? This is a **bold** test string with _italic_ text and `highlighted code`. Here's some Latex:
    $$E=mc^2$$
    Isn't that great?
    """
    let document = await parser.parse(text: text)
    let renderables = await RenderableDocument(document: document, config: .default, colorScheme: .light)
    let view = CanvasView {
      DocumentView(renderableDocument: renderables, config: .init()).padding(.horizontal, 24)
    }
    assert(view)
  }

  func testMarkdownWithInlineLatex_uikit() async throws {
    let text = """
    This double integral:
    - Sweeps across a rectangular region from \\( \\boxed{x = 0} \\) to \\( \\pi \\), and \\( y = 1 \\) to \\( e \\)
    - Combines a sine of a product \\( xy \\), a logarithmic denominator, and a cosine term multiplied by a polynomial
    - Now we have this matrix \\(\\begin{bmatrix} 1 & 2\\\\ 3 & 4 \\end{bmatrix}\\\\)

    ## Very *important* title \\( x = 0 \\)
    """
    let document = await parser.parse(text: text)
    let renderables = await RenderableDocument(document: document, config: .default, colorScheme: .light)
    let view = CanvasView {
      DocumentView(renderableDocument: renderables, config: .init()).padding(.horizontal, 24)
    }
    assert(view)
  }

  func testMarkdownWithComplexLatex() async throws {
    let text = """
    Here are a couple of most famous math formulas
    $$\\boxed {a^2 + b^2 = c^}$$

    $$e^{i\\pi} + 1 = 0$$

    $$\\boxed{x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}}$$
    $$A = \\pi r^2$$

    $$F = ma$$

    $$\\text{Mass-Energy Equivalence: } E = mc^2 $$

    $$(a + b)^n = \\sum_{k=0}^{n} \\binom{n}{k} a^{n-k} b^k$$

    $$f(x) = \\sum_{n=0}^{\\infty} \\frac{f^{(n)}(a)}{n!}(x - a)^n$$

    $$f'(x) = \\lim_{h \\to 0} \\frac{f(x+h) - f(x)}{h}$$

    $$\\int_a^b f(x)\\,dx = \\lim_{n \\to \\infty} \\sum_{i=1}^{n} f(x_i^*) \\Delta x$$

    $$C = S_0 N(d_1) - K e^{-rT} N(d_2)$$
    $$d_1 = \\dfrac{\\ln\\left(\\tfrac{S_0}{K}\\right) + \\left(r + \\frac{\\sigma^2}{2}\\right)T}{\\sigma \\sqrt{T}}, \\quad$$
    $$d_2 = d_1 - \\sigma \\sqrt{T}$$
    """
    let document = await parser.parse(text: text)
    let renderables = await RenderableDocument(document: document, config: .default, colorScheme: .light)
    let view = CanvasView {
      DocumentView(renderableDocument: renderables, config: .init()).padding(.horizontal, 24)
    }
    assert(view)
  }

  func testLatexWithNewLines() async throws {
    let text = """
    Here's the most **famous** one:

    $$\\text{Pythagorean theorem} \\\\ a^2 + b^2 = c^$$

    and here's a 2x2 matrix
    \\[
    \\begin{bmatrix}
    1 & 2 \\\\
    3 & 4
    \\end{bmatrix}
    \\]
    """
    let document = await parser.parse(text: text)
    let renderables = await RenderableDocument(document: document, config: .default, colorScheme: .light)
    let view = CanvasView {
      DocumentView(renderableDocument: renderables, config: .init()).padding(.horizontal, 24)
    }
    assert(view)
  }

  func testCompositeLatex() async throws {
    let text = """
    ## (1) Ring’s acceleration during the first rebound

    - Just after the rod elastically rebounds,
      • rod velocity \\(+v\\),
      • ring velocity \\(-v\\).
    - The surfaces slip: the ring slides downward relative to the rod
      so kinetic friction \\(f = k\\,m\\,g\\) acts upward on the ring.
    - Net force on the ring:
      \\[
        F = f - m\\,g = \\bigl(k\\,m\\,g\\bigr) - m\\,g = (k-1)\\,m\\,g.
      \\]
    - Therefore the ring’s acceleration is
      \\[
        a_{\\rm ring} = \\frac{F}{m} = (k-1)\\,g
        \\quad\\text{(upward).}
      \\]
    """
    let document = await parser.parse(text: text)
    let renderables = await RenderableDocument(document: document, config: .default, colorScheme: .light)
    let view = CanvasView {
      DocumentView(renderableDocument: renderables, config: .init()).padding(.horizontal, 24)
    }
    assert(view)
  }

  func testLatexWithIndentation() async throws {
    let text = """
    Here are five widely recognized mathematical equations, each formatted with two spaces after the LaTeX expression before the line break:
    1. **Pythagorean Theorem**
       \\[a^2 + b^2 = c^2\\]

    2. **Quadratic Formula**
       \\[x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}\\]

    3. **Euler's Identity**
       \\[e^{i\\pi} + 1 = 0\\]

    4. **Area of a Circle**
       \\[A = \\pi r^2\\]

    5. **Newton's Second Law**
       \\[F = ma\\]
    Each equation is a cornerstone in its respective domain—geometry, algebra, complex analysis, calculus, and physics. Want to riff on these with a cosmic twist or dive deeper into their origins?
    """
    let document = await parser.parse(text: text)
    let renderables = await RenderableDocument(document: document, config: .default, colorScheme: .light)
    let view = CanvasView {
      DocumentView(renderableDocument: renderables, config: .init()).padding(.horizontal, 24)
    }
    assert(view)
  }

  func testLatexWithSpecificSymbols() async throws {
    let text = """
    \\[
    \\varphi(x) = f(x) - \\big(f(a) + f'(a)(x-a)\\big).
    \\]

    - Vector \\(\\overrightarrow{FA} = (a+c,0)\\)

    \\[
    2+2(2q-1) = 2q^2 \\implies 2+4q-2 = 2q^2 \\implies 4q = 2q^2 \\implies q^2 - 2q = 0.
    \\]

    \\[
    Fe^{3+}_{(aq)} + xCl^-_{(aq)} \\rightleftharpoons [FeCl_x]^{3-x}_{(aq)} \\quad (x = 1,2,3,4)
    \\]

    \\(a_1, \\dots, a_n\\)
    """

    let document = await parser.parse(text: text)
    let renderables = await RenderableDocument(document: document, config: .default, colorScheme: .light)
    let view = CanvasView {
      DocumentView(renderableDocument: renderables, config: .init()).padding(.horizontal, 24)
    }
    assert(view)
  }

  func testCitations() async throws {
    let text = """
    This paragraph contains a titled inline citation [9F742443-6C92-4C44-BF58-8F5A7C53B6F1](http://www.microsoft.com?citationMarker=9F742443-6C92-4C44-BF58-8F5A7C53B6F1&citationId=987&citationTitle=microsoft.com&citationFullTitle=microsoft.com&chatItemId=chatItemId). And here are more citations [9F742443-6C92-4C44-BF58-8F5A7C53B6F1](http://www.microsoft.com?citationMarker=9F742443-6C92-4C44-BF58-8F5A7C53B6F1&citationId%3D1%2C2&citationTitle=microsoft.com%20%2B1&citationFullTitle=microsoft.com&chatItemId=chatItemId).
    """
    let document = await parser.parse(text: text)
    let renderables = await RenderableDocument(document: document, config: .default, colorScheme: .light)
    let view = CanvasView {
      DocumentView(renderableDocument: renderables, config: .init()).padding(.horizontal, 24)
    }
    assert(view)
  }

  func testLatexInTable() async throws {
    let text = """
    | Power (mW) | Calculation                          | Result (dBm) |
    |------------|--------------------------------------|--------------|
    | 0.001      | \\(10 \\cdot \\log_{10}(0.001)\\)    | -30 dBm      |
    | 0.01       | \\(10 \\cdot \\log_{10}(0.01)\\)       | -20 dBm      |
    | 0.1        | \\(10 \\cdot \\log_{10}(0.1)\\)      | -10 dBm      |
    """
    let document = await parser.parse(text: text)
    print(document.debugDescription())
    let renderables = await RenderableDocument(document: document, config: .default, colorScheme: .light)
    let view = CanvasView {
      DocumentView(renderableDocument: renderables, config: .init()).padding(.horizontal, 24)
    }
    assert(view)

  }

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

    // 1. Inspect Heading
    guard case let .heading(_, level, headingContent) = renderables[0] else {
      XCTFail("First renderable should be a heading")
      return
    }
    XCTAssertEqual(level, 1)

    // Check that "italic" has italic typography
    let italicRange = (headingContent.string as NSString).range(of: "italic")
    let italicTypography = headingContent.attribute(.typography, at: italicRange.location, effectiveRange: nil) as? Typography
    XCTAssertEqual(italicTypography, Typography.extraLarge.italicVariant)

    // Check that "bold" has bold typography
    let boldRange = (headingContent.string as NSString).range(of: "bold")
    let boldTypography = headingContent.attribute(.typography, at: boldRange.location, effectiveRange: nil) as? Typography
    XCTAssertEqual(boldTypography, Typography.extraLarge.boldVariant)

    // Check that "both" has bold typography (since nested Strong(Emphasis) result in boldVariant)
    let bothRange = (headingContent.string as NSString).range(of: "both")
    let bothTypography = headingContent.attribute(.typography, at: bothRange.location, effectiveRange: nil) as? Typography
    XCTAssertEqual(bothTypography, Typography.extraLarge.boldVariant.italicVariant)

    // 2. Inspect Paragraph
    guard case let .paragraph(_, paragraphContent) = renderables[1] else {
      XCTFail("Second renderable should be a paragraph")
      return
    }

    // Check "nested " (part of **nested *italic* inside**)
    let nestedRange = (paragraphContent.string as NSString).range(of: "nested ")
    let nestedTypography = paragraphContent.attribute(.typography, at: nestedRange.location, effectiveRange: nil) as? Typography
    XCTAssertEqual(nestedTypography, Typography.base.boldVariant)

    // Check "italic" (nested inside bold)
    let nestedItalicRange = (paragraphContent.string as NSString).range(of: "italic")
    let nestedItalicTypography = paragraphContent.attribute(.typography, at: nestedItalicRange.location, effectiveRange: nil) as? Typography
    // Typography.base.boldVariant.italicVariant -> returns italic version of that size per current design
    XCTAssertEqual(nestedItalicTypography, Typography.base.boldVariant.italicVariant)
  }

  func testBlockLatexWithCustomColor() async throws {
    let text = """
    Here is a block LaTeX formula:
    $$x^2 + 2x + 3$$
    End of formula.
    """
    let config = MarkdownRenderConfig(
      paragraphStyle: .init(textFont: .base, boldTextFont: .baseStrong, textColor: .red)
    )
    let document = await parser.parse(text: text)
    let renderables = await RenderableDocument(document: document, config: config, colorScheme: .light)
    let view = CanvasView {
      DocumentView(renderableDocument: renderables, config: config).padding(.horizontal, 24)
    }
    assert(view)
  }

  func testInlineLatexWithCustomColor() async throws {
    let text = """
    The solution is \\(3x^2 + 4x - 5\\) for all values.
    """
    let config = MarkdownRenderConfig(
      paragraphStyle: .init(textFont: .base, boldTextFont: .baseStrong, textColor: .red)
    )
    let document = await parser.parse(text: text)
    let renderables = await RenderableDocument(document: document, config: config, colorScheme: .light)
    let view = CanvasView {
      DocumentView(renderableDocument: renderables, config: config).padding(.horizontal, 24)
    }
    assert(view)
  }

  func testMixedLatexWithCustomColor() async throws {
    let text = """
    Inline formula \\(E = mc^2\\) and block formula:
    $$a^2 + b^2 = c^2$$
    Both should use custom color.
    """
    let config = MarkdownRenderConfig(
      paragraphStyle: .init(textFont: .base, boldTextFont: .baseStrong, textColor: .green)
    )
    let document = await parser.parse(text: text)
    let renderables = await RenderableDocument(document: document, config: config, colorScheme: .light)
    let view = CanvasView {
      DocumentView(renderableDocument: renderables, config: config).padding(.horizontal, 24)
    }
    assert(view)
  }
}
