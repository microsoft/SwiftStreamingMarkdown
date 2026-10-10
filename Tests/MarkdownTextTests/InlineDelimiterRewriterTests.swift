//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import Markdown
import XCTest

final class InlineDelimiterRewriterTests: XCTestCase {

  private let parser = MarkdownParserImpl()

  /// Parses `text` through the full pipeline and returns the rendered
  /// paragraph's attributed content.
  private func renderedParagraph(_ text: String) async -> NSMutableAttributedString? {
    let renderables = await renderables(text)
    guard case .paragraph(_, let content) = renderables.first else { return nil }
    return content
  }

  private func renderables(_ text: String) async -> [MarkdownRenderable] {
    await parser.parse(text: text, config: .default).renderables
  }

  private func background(at index: Int, in content: NSMutableAttributedString?) -> MDColor? {
    content?.attribute(.backgroundColor, at: index, effectiveRange: nil) as? MDColor
  }

  private func baseline(at index: Int, in content: NSMutableAttributedString?) -> CGFloat {
    CGFloat((content?.attribute(.baselineOffset, at: index, effectiveRange: nil) as? NSNumber)?.doubleValue ?? 0)
  }

  // MARK: - Superscript

  func test_simple_superscript() async {
    let content = await renderedParagraph("a ^b^ c")
    XCTAssertEqual(content?.string, "a b c")
    XCTAssertGreaterThan(baseline(at: 2, in: content), 0)
    XCTAssertEqual(baseline(at: 0, in: content), 0)
  }

  func test_intraword_superscript() async {
    let content = await renderedParagraph("a^b^c")
    XCTAssertEqual(content?.string, "abc")
    XCTAssertGreaterThan(baseline(at: 1, in: content), 0)
    XCTAssertEqual(baseline(at: 0, in: content), 0)
  }

  func test_caret_without_closer_stays_literal() async {
    let content = await renderedParagraph("x^2 and 2^10")
    XCTAssertEqual(content?.string, "x^2 and 2^10")
  }

  func test_superscript_rejects_inner_whitespace() async {
    let content = await renderedParagraph("a ^b c^ d")
    XCTAssertEqual(content?.string, "a ^b c^ d")
  }

  func test_superscript_unclosed_stays_literal() async {
    let content = await renderedParagraph("a ^b")
    XCTAssertEqual(content?.string, "a ^b")
  }

  func test_superscript_inside_code_span_stays_literal() async {
    let content = await renderedParagraph("`^x^`")
    XCTAssertEqual(content?.string, "^x^")
  }

  func test_superscript_inside_highlight_keeps_both() async {
    let content = await renderedParagraph("==a ^b^==")
    XCTAssertEqual(content?.string, "a b")
    XCTAssertNotNil(background(at: 0, in: content))
    XCTAssertGreaterThan(baseline(at: 2, in: content), 0)
  }

  func test_escaped_caret_stays_literal() async {
    // A single-character marker can't rely on run-length remainders the way
    // `==` can; the source-span check keeps `\^` literal.
    let content = await renderedParagraph("a \\^x^ b")
    XCTAssertEqual(content?.string, "a ^x^ b")
    XCTAssertEqual(baseline(at: 3, in: content), 0)
  }

  func test_entity_caret_stays_literal() async {
    // `&#94;` decodes to `^`; entity-bearing nodes stay literal.
    let content = await renderedParagraph("&#94;x&#94;")
    XCTAssertEqual(content?.string, "^x^")
    XCTAssertEqual(baseline(at: 1, in: content), 0)
  }

  func test_punctuation_boundary_superscript_stays_literal() async {
    // Deliberate markdown-it flanking: `^` before `(` can't open after a
    // word character, so `x^(n)^` stays literal (Pandoc would superscript).
    let content = await renderedParagraph("x^(n)^")
    XCTAssertEqual(content?.string, "x^(n)^")
    XCTAssertEqual(baseline(at: 2, in: content), 0)
  }

  func test_adjacent_carets_nest() async {
    let content = await renderedParagraph("^^a^^")
    XCTAssertEqual(content?.string, "a")
    XCTAssertGreaterThan(baseline(at: 0, in: content), 0)
  }

  func test_ordinal_superscript() async {
    let content = await renderedParagraph("a^1^st")
    XCTAssertEqual(content?.string, "a1st")
    XCTAssertGreaterThan(baseline(at: 1, in: content), 0)
    XCTAssertEqual(baseline(at: 2, in: content), 0)
  }

  // MARK: - Multi-spec interactions

  func test_crossing_pairs_stay_literal_and_intact() async {
    // A `^` pair cannot close inside the `==` range it crossed; the `==` pair still wraps.
    let content = await renderedParagraph("==a ^b== c^")
    XCTAssertEqual(content?.string, "a ^b c^")
    for index in 0..<4 {
      XCTAssertNotNil(background(at: index, in: content), "expected highlight at \(index)")
    }
    XCTAssertNil(background(at: 4, in: content))
    XCTAssertEqual(baseline(at: 0, in: content), 0)
  }

  func test_crossing_pairs_reversed_spec_order() async {
    // The `^` inner range "a ==b" contains a space, which superscript
    // rejects — both pairs emit literally and no text is lost or doubled.
    let content = await renderedParagraph("^a ==b^ c==")
    XCTAssertEqual(content?.string, "^a ==b^ c==")
    XCTAssertEqual(baseline(at: 0, in: content), 0)
    XCTAssertNil(background(at: 0, in: content))
  }

  func test_footnote_like_text_stays_literal() async {
    // LLMs emit `[^n]` footnote-style references; `^` must not open after `[`.
    let content = await renderedParagraph("[^1][^2]")
    XCTAssertEqual(content?.string, "[^1][^2]")
    XCTAssertEqual(baseline(at: 0, in: content), 0)
  }

  func test_superscript_after_bracket_reference_still_works() async {
    // Blocking `[^` only suppresses that opener; a later clean pair still wraps.
    let content = await renderedParagraph("[^1] x^2^")
    XCTAssertEqual(content?.string, "[^1] x2")
    XCTAssertGreaterThan(baseline(at: 6, in: content), 0)
  }

  func test_caret_after_equals_remainder_can_open() async {
    // The `=` between `[` and `^` is foreign interior content, so `[^`'s
    // block does not reach through it; `^y^` pairs normally.
    let content = await renderedParagraph("x[=^y^")
    XCTAssertEqual(content?.string, "x[=y")
    XCTAssertGreaterThan(baseline(at: 3, in: content), 0)
  }

  func test_caret_equals_caret_stays_literal() async {
    let content = await renderedParagraph("^=^")
    XCTAssertEqual(content?.string, "^=^")
  }

  func test_whitespace_reject_keeps_piece_order() async {
    // A rejected pair emits literally in source order; the interior `=`
    // must not migrate across the markers.
    let content = await renderedParagraph("a ^=a b^")
    XCTAssertEqual(content?.string, "a ^=a b^")
  }

  // MARK: - Pairing

  func test_simple_highlight() async {
    let content = await renderedParagraph("a ==b== c")
    XCTAssertEqual(content?.string, "a b c")
    XCTAssertNotNil(background(at: 2, in: content))
    XCTAssertNil(background(at: 0, in: content))
    XCTAssertNil(background(at: 4, in: content))
  }

  func test_highlight_whole_paragraph() async {
    let content = await renderedParagraph("==x==")
    XCTAssertEqual(content?.string, "x")
    XCTAssertNotNil(background(at: 0, in: content))
  }

  func test_intraword_highlight() async {
    let content = await renderedParagraph("a==b==c")
    XCTAssertEqual(content?.string, "abc")
    XCTAssertNotNil(background(at: 1, in: content))
    XCTAssertNil(background(at: 0, in: content))
    XCTAssertNil(background(at: 2, in: content))
  }

  func test_marker_touching_spaces_stays_literal() async {
    let content = await renderedParagraph("== x ==")
    XCTAssertEqual(content?.string, "== x ==")
  }

  func test_intraword_marker_touching_spaces_stays_literal() async {
    let content = await renderedParagraph("x == y ==")
    XCTAssertEqual(content?.string, "x == y ==")
  }

  func test_close_marker_preceded_by_space_stays_literal() async {
    let content = await renderedParagraph("==x ==")
    XCTAssertEqual(content?.string, "==x ==")
  }

  func test_open_marker_followed_by_space_stays_literal() async {
    let content = await renderedParagraph("== x==")
    XCTAssertEqual(content?.string, "== x==")
  }

  func test_unclosed_marker_stays_literal() async {
    let content = await renderedParagraph("a ==b")
    XCTAssertEqual(content?.string, "a ==b")
  }

  func test_odd_run_leaves_one_literal_equals() async {
    let content = await renderedParagraph("===x===")
    XCTAssertEqual(content?.string, "=x=")
    XCTAssertNil(background(at: 0, in: content))
    XCTAssertNotNil(background(at: 1, in: content))
    XCTAssertNil(background(at: 2, in: content))
  }

  func test_double_run_nests_and_highlights() async {
    let content = await renderedParagraph("====x====")
    XCTAssertEqual(content?.string, "x")
    XCTAssertNotNil(background(at: 0, in: content))
  }

  func test_nested_highlight_is_absorbed() async {
    let content = await renderedParagraph("==a ==b== c==")
    XCTAssertEqual(content?.string, "a b c")
    for index in 0..<5 {
      XCTAssertNotNil(background(at: index, in: content), "expected highlight at \(index)")
    }
  }

  func test_highlight_wraps_strong() async {
    let content = await renderedParagraph("a ==**b**== c")
    XCTAssertEqual(content?.string, "a b c")
    XCTAssertNotNil(background(at: 2, in: content))
    let boldFont = content?.attribute(.font, at: 2, effectiveRange: nil) as? MDFont
    let plainFont = content?.attribute(.font, at: 0, effectiveRange: nil) as? MDFont
    XCTAssertNotNil(boldFont)
    XCTAssertNotEqual(boldFont, plainFont)
  }

  func test_strong_wraps_highlight() async {
    let content = await renderedParagraph("a **==b==** c")
    XCTAssertEqual(content?.string, "a b c")
    XCTAssertNotNil(background(at: 2, in: content))
    let boldFont = content?.attribute(.font, at: 2, effectiveRange: nil) as? MDFont
    let plainFont = content?.attribute(.font, at: 0, effectiveRange: nil) as? MDFont
    XCTAssertNotNil(boldFont)
    XCTAssertNotEqual(boldFont, plainFont)
  }

  func test_highlight_wraps_html_strong() async {
    let content = await renderedParagraph("==a <b>b</b> c==")
    XCTAssertEqual(content?.string, "a b c")
    for index in 0..<5 {
      XCTAssertNotNil(background(at: index, in: content), "expected highlight at \(index)")
    }
    let boldFont = content?.attribute(.font, at: 2, effectiveRange: nil) as? MDFont
    let plainFont = content?.attribute(.font, at: 0, effectiveRange: nil) as? MDFont
    XCTAssertNotNil(boldFont)
    XCTAssertNotEqual(boldFont, plainFont)
  }

  func test_empty_pair_stays_literal() async {
    let content = await renderedParagraph("a====b")
    XCTAssertEqual(content?.string, "a====b")
  }

  func test_punctuation_boundary_blocks_open() async {
    // markdown-it flanking: `(` punct after `==` next to alnum `a` can't open.
    let content = await renderedParagraph("a==(b)==c")
    XCTAssertEqual(content?.string, "a==(b)==c")
  }

  func test_punctuation_boundary_blocks_close() async {
    let content = await renderedParagraph("x==hi!==y")
    XCTAssertEqual(content?.string, "x==hi!==y")
  }

  func test_punctuation_picks_the_right_pair() async {
    // `==` after `)` can't close; the trailing `==` pairs with the
    // post-`)` opener instead, matching markdown-it's pair choice.
    let content = await renderedParagraph("x==a)==b==")
    XCTAssertEqual(content?.string, "x==a)b")
    XCTAssertNotNil(background(at: 5, in: content))
    XCTAssertNil(background(at: 0, in: content))
  }

  func test_highlight_preserves_link() async {
    let content = await renderedParagraph("==a [x](https://ex.com) b==")
    XCTAssertEqual(content?.string, "a x b")
    let link = content?.attribute(.link, at: 2, effectiveRange: nil) as? URL
    XCTAssertEqual(link?.absoluteString, "https://ex.com")
    XCTAssertNotNil(background(at: 0, in: content))
    XCTAssertNotNil(background(at: 4, in: content))
  }

  func test_image_inside_emphasis_highlight_degrades_to_alt_text() async {
    // Inside `**…**` an Image node would be dropped at conversion; the
    // alt text joins the styled run instead.
    let content = await renderedParagraph("**==a ![i](https://ex.com/i.png) b==**")
    XCTAssertEqual(content?.string, "a i b")
  }

  func test_highlight_preserves_paragraph_level_image() async {
    let renderables = await parser.parse(
      text: "==a ![alt](https://ex.com/i.png) b==",
      config: .default.withImageConfig(ImageConfig(enabled: true, allowedImageTypes: [.remote(allowedDomains: [])]))
    ).renderables
    XCTAssertTrue(renderables.contains { renderable in
      if case .image = renderable { return true }
      return false
    })
  }

  func test_image_in_quoted_paragraph_degrades_to_alt_text() async {
    // `ImageBlockRewriter` only hoists top-level paragraphs, so an Image
    // inside a block quote can't stay a node — it degrades to its alt text.
    let document = await parser.parse(text: "> ==a ![i](https://ex.com/i.png) b==")
    let dump = document.debugDescription()
    XCTAssertTrue(dump.contains("Text \"i\""), dump)
    XCTAssertFalse(dump.contains("Image"), dump)
  }

  func test_nested_attribute_nodes_compose() async {
    let content = await renderedParagraph("==a <sup>b</sup> c==")
    XCTAssertEqual(content?.string, "a b c")
    for index in 0..<5 {
      XCTAssertNotNil(background(at: index, in: content), "expected highlight at \(index)")
    }
    XCTAssertGreaterThan(baseline(at: 2, in: content), 0)
    XCTAssertEqual(baseline(at: 0, in: content), 0)
  }

  // MARK: - Constrained containers and code spans

  func test_marker_inside_link_text_stays_literal() async {
    let content = await renderedParagraph("[==x==](https://ex.com)")
    XCTAssertEqual(content?.string, "==x==")
    let link = content?.attribute(.link, at: 0, effectiveRange: nil) as? URL
    XCTAssertEqual(link?.absoluteString, "https://ex.com")
  }

  func test_marker_inside_code_span_stays_literal() async {
    let content = await renderedParagraph("`==x==`")
    XCTAssertEqual(content?.string, "==x==")
  }

  func test_escaped_marker_stays_literal() async {
    // cmark merges `\=` into the surrounding `Text` node; a source-span
    // check keeps the whole node literal rather than highlighting `x`.
    let content = await renderedParagraph("a \\==x== b")
    XCTAssertEqual(content?.string, "a ==x== b")
    XCTAssertNil(background(at: 4, in: content))
  }

  func test_entity_marker_stays_literal() async {
    // `&#61;` decodes to `=`; entity-bearing nodes stay literal.
    let content = await renderedParagraph("&#61;&#61;x&#61;&#61;")
    XCTAssertEqual(content?.string, "==x==")
    XCTAssertNil(background(at: 0, in: content))
  }

  // MARK: - Other blocks

  func test_highlight_in_heading() async {
    let renderables = await renderables("# ==x==")
    guard case .heading(_, let level, let content) = renderables.first else {
      return XCTFail("expected heading")
    }
    XCTAssertEqual(level, 1)
    XCTAssertEqual(content.string, "x")
    XCTAssertNotNil(content.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? MDColor)
  }

  func test_highlight_in_table_cell() async {
    let renderables = await renderables("| head |\n| --- |\n| ==x== |")
    guard case .table(_, _, let rows, _) = renderables.first else {
      return XCTFail("expected table")
    }
    let cell = rows.first?.first
    XCTAssertEqual(cell?.string, "x")
    XCTAssertNotNil(cell?.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? MDColor)
  }

  // MARK: - Non-regression

  func test_document_without_markers_is_untouched() async {
    let document = await parser.parse(text: "plain **bold** text")
    XCTAssertEqual(document.debugDescription(), Document(parsing: "plain **bold** text").debugDescription())
  }
}
