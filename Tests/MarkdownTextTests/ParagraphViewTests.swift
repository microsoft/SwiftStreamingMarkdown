//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(UIKit)
import Foundation
import Markdown
@testable import SwiftStreamingMarkdown
import SwiftUI
import Testing
import UIKit

@Suite("ParagraphView Tests")
struct ParagraphViewTests {

  // MARK: - Helper Methods

  /// Create a simple attributed string with a citation attachment
  private func makeAttributedStringWithCitation(title: String = "ESPN") -> NSMutableAttributedString {
    // Create a proper citation URL with query parameters
    let baseURL = "http://example.com"
    let citationURL = "\(baseURL)?citationMarker=9F742443&citationTitle=\(title)&citationA11yValue=\(title)"

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

  @Test("Reused paragraph clears stale accessibility content")
  @MainActor
  func prepareForReuseClearsAccessibilityContent() {
    let view = ParagraphUIView()
    view.setParagraphContents(
      NSMutableAttributedString(string: "Previous paragraph"),
      textAnimation: .none,
      isStreamComplete: true
    )

    #expect(view.accessibilityLabel == "Previous paragraph")

    view.prepareForReuse()

    #expect(view.attributedText.length == 0)
    #expect(view.accessibilityLabel == nil)
    #expect(view.accessibilityCustomActions == nil)
  }

  @Test("Character Streaming keeps one attributed paragraph and full accessibility")
  @MainActor
  func characterStreamingParagraphIntegration() throws {
    let url = try #require(URL(string: "https://example.com"))
    let contents = NSMutableAttributedString(string: "AB")
    contents.addAttribute(
      .link,
      value: url,
      range: NSRange(location: 0, length: 1)
    )
    let view = ParagraphUIView(characterStreaming: true)

    view.setParagraphContents(
      contents,
      textAnimation: .characterStreaming,
      isStreamComplete: false
    )

    #expect(view.attributedText.string == "A")
    #expect(view.accessibilityLabel == "AB")
    #expect(view.layoutManager is CharacterStreamingLayoutManager)
    #expect(
      view.attributedText.attribute(
        .shadow,
        at: 0,
        effectiveRange: nil
      ) == nil
    )
    #expect(
      view.attributedText.attribute(
        .link,
        at: 0,
        effectiveRange: nil
      ) as? URL == url
    )

    view.finishTextAnimation()

    #expect(view.attributedText.string == "AB")
    #expect(view.accessibilityLabel == "AB")
  }

  @Test("Rapid snapshots preserve the pending Character Streaming deadline")
  @MainActor
  func characterStreamingRapidSnapshots() {
    let view = ParagraphUIView(characterStreaming: true)
    view.setParagraphContents(
      NSMutableAttributedString(string: "ABCDE"),
      textAnimation: .characterStreaming,
      isStreamComplete: false
    )
    #expect(view.attributedText.string == "A")

    view.setParagraphContents(
      NSMutableAttributedString(string: "ABCDEF"),
      textAnimation: .characterStreaming,
      isStreamComplete: false
    )

    #expect(view.attributedText.string == "A")
    view.finishTextAnimation()
  }

  @Test("A drained queue still enforces Character Streaming cadence")
  @MainActor
  func characterStreamingDrainedQueueCadence() {
    let view = ParagraphUIView(characterStreaming: true)
    view.setParagraphContents(
      NSMutableAttributedString(string: "A"),
      textAnimation: .characterStreaming,
      isStreamComplete: true
    )
    #expect(view.attributedText.string == "A")

    view.setParagraphContents(
      NSMutableAttributedString(string: "AB"),
      textAnimation: .characterStreaming,
      isStreamComplete: true
    )

    #expect(view.attributedText.string == "A")
    view.finishTextAnimation()
  }

  @Test("Detaching settles Character Streaming and stops scheduled work")
  @MainActor
  func characterStreamingSettlesWhenDetached() {
    let view = ParagraphUIView(characterStreaming: true)
    view.setParagraphContents(
      NSMutableAttributedString(string: "AB"),
      textAnimation: .characterStreaming,
      isStreamComplete: true
    )
    #expect(view.attributedText.string == "A")

    let window = UIWindow()
    window.addSubview(view)
    view.removeFromSuperview()

    #expect(view.attributedText.string == "AB")
  }

  @Test("Character Streaming remains settled when Reduce Motion turns off")
  @MainActor
  func characterStreamingReduceMotionToggle() {
    let contents = NSMutableAttributedString(string: "Already visible")
    let view = ParagraphUIView(characterStreaming: true)
    view.setParagraphContents(
      contents,
      textAnimation: .none,
      isStreamComplete: false
    )

    view.setParagraphContents(
      contents,
      textAnimation: .characterStreaming,
      isStreamComplete: false
    )

    #expect(view.attributedText.string == contents.string)
    #expect(view.layoutManager is CharacterStreamingLayoutManager)
    view.finishTextAnimation()
  }

  @Test("Completion-only updates preserve an active Fade")
  @MainActor
  func fadeCompletionPreservesAnimation() throws {
    let view = ParagraphUIView()
    let initial = NSMutableAttributedString(
      string: "A",
      attributes: [.foregroundColor: UIColor.black]
    )
    view.setParagraphContents(
      initial,
      textAnimation: .none,
      isStreamComplete: false
    )

    let updated = NSMutableAttributedString(
      string: "AB",
      attributes: [.foregroundColor: UIColor.black]
    )
    view.setParagraphContents(
      updated,
      textAnimation: .fade,
      isStreamComplete: false
    )
    let before = try #require(
      view.attributedText.attribute(
        .foregroundColor,
        at: 1,
        effectiveRange: nil
      ) as? UIColor
    ).cgColor.alpha

    view.setParagraphContents(
      updated,
      textAnimation: .fade,
      isStreamComplete: true
    )
    let after = try #require(
      view.attributedText.attribute(
        .foregroundColor,
        at: 1,
        effectiveRange: nil
      ) as? UIColor
    ).cgColor.alpha

    #expect(before < 1)
    #expect(after == before)
    view.finishTextAnimation()
  }

  @Test("Character Streaming wrapped size grows with its visible prefix")
  @MainActor
  func characterStreamingWrappedMeasurement() {
    let view = ParagraphUIView(characterStreaming: true)
    view.setParagraphContents(
      NSMutableAttributedString(
        string: "This paragraph grows across several narrow wrapped lines."
      ),
      textAnimation: .characterStreaming,
      isStreamComplete: true
    )
    let initial = view.sizeThatFits(
      CGSize(width: 70, height: CGFloat.greatestFiniteMagnitude)
    )

    view.finishTextAnimation()
    let settled = view.sizeThatFits(
      CGSize(width: 70, height: CGFloat.greatestFiniteMagnitude)
    )

    #expect(settled.height > initial.height)
  }

  @Test("Streaming size cache evicts prior visible prefixes")
  @MainActor
  func characterStreamingSizeCacheIsBounded() {
    let coordinator = ParagraphView.Coordinator()
    let key = ParagraphSizeCacheKey(width: 70, visibleUTF16Length: 1)
    coordinator.sizeCache[key] = CGSize(width: 70, height: 20)

    coordinator.updateVisibleUTF16Length(2)

    #expect(coordinator.sizeCache.isEmpty)
    #expect(coordinator.lastVisibleUTF16Length == 2)
  }

  @Test("UIKit Character Streaming translates positive offsets below baseline")
  func characterStreamingBaselineDirection() {
    #expect(CharacterStreamingLayoutManager.baselineTranslation(5) == 5)
  }

  @Test("UIKit renders blurred glyph pixels before crossfading to sharp")
  @MainActor
  func characterStreamingBitmapBlur() throws {
    let initial = try renderedGlyphMetrics(
      for: .value(at: 0)
    )
    let intermediate = try renderedGlyphMetrics(
      for: .value(at: 0.5)
    )
    let settled = try renderedGlyphMetrics(
      for: .value(at: 1)
    )

    #expect(initial.maximumAlpha > 0)
    #expect(initial.maximumAlpha < intermediate.maximumAlpha)
    #expect(intermediate.maximumAlpha < settled.maximumAlpha)
    #expect(initial.faintPixelCount > 0)
    #expect(initial.opaquePixelCount == 0)
    #expect(settled.opaquePixelCount > 0)
    #expect(initial.redPixelCount > 0)
    #expect(intermediate.redPixelCount > 0)
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

  @MainActor
  private func renderedGlyphMetrics(
    for transform: CharacterStreamingTransform
  ) throws -> CharacterStreamingGlyphImageMetrics {
    let textStorage = NSTextStorage(
      attributedString: NSAttributedString(
        string: "A",
        attributes: [
          .font: UIFont.systemFont(ofSize: 40),
          .foregroundColor: UIColor.red
        ]
      )
    )
    let layoutManager = CharacterStreamingLayoutManager()
    let textContainer = NSTextContainer(
      size: CGSize(width: 100, height: 100)
    )
    textContainer.lineFragmentPadding = 0
    layoutManager.addTextContainer(textContainer)
    textStorage.addLayoutManager(layoutManager)
    let glyphRange = layoutManager.glyphRange(for: textContainer)
    layoutManager.updateAnimationFrames([
      CharacterStreamingGlyphAnimationFrame(
        range: NSRange(location: 0, length: 1),
        transform: transform,
        startTime: 0
      )
    ])

    func renderImage() -> UIImage {
      UIGraphicsImageRenderer(
        size: CGSize(width: 100, height: 100)
      ).image { _ in
        layoutManager.drawGlyphs(
          forGlyphRange: glyphRange,
          at: CGPoint(x: 20, y: 20)
        )
      }
    }

    let image = renderImage()
    if transform.blurRadius > 0 {
      let sourceCount = layoutManager.cachedGlyphImageCount
      let blurredCount = layoutManager.cachedBlurredImageCount
      _ = renderImage()
      #expect(sourceCount == 1)
      #expect(blurredCount == 1)
      #expect(layoutManager.cachedGlyphImageCount == sourceCount)
      #expect(layoutManager.cachedBlurredImageCount == blurredCount)
      #expect(layoutManager.renderedGlyphImageCount == 1)
      textStorage.addAttribute(
        .foregroundColor,
        value: UIColor.blue,
        range: NSRange(location: 0, length: textStorage.length)
      )
      _ = renderImage()
      #expect(layoutManager.renderedGlyphImageCount == 2)
      #expect(layoutManager.cachedGlyphImageCount == 1)
      #expect(layoutManager.cachedBlurredImageCount == 1)
      layoutManager.clearAnimations()
      #expect(layoutManager.cachedGlyphImageCount == 0)
      #expect(layoutManager.cachedBlurredImageCount == 0)
    }
    return characterStreamingGlyphImageMetrics(
      for: try #require(image.cgImage)
    )
  }
}
#endif
