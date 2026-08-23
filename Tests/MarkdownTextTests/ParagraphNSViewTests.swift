//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(AppKit)
import AppKit
@testable import SwiftStreamingMarkdown
import Testing

@Suite("ParagraphNSView Measurement Tests")
@MainActor
struct ParagraphNSViewTests {

  /// Regression: a paragraph is often measured before SwiftUI has given the view a frame
  /// (e.g. during a navigation transition). Measuring through the view's own text container
  /// used to return a zero height in that state because `widthTracksTextView` forces the
  /// container width to follow the frame width (0), collapsing the paragraph. Measurement
  /// must instead honor the requested width regardless of the view's frame.
  @Test("Measures a non-zero, width-dependent height without a frame")
  func measuresHeightWithoutFrame() {
    let view = ParagraphNSView()
    let longText = String(repeating: "word ", count: 200)
    view.setParagraphContents(
      NSMutableAttributedString(string: longText),
      textAnimation: .none,
      isStreamComplete: true
    )

    let narrow = view.measureSize(fittingWidth: 200)
    let wide = view.measureSize(fittingWidth: 1000)

    #expect(narrow.height > 0, "Wrapping content must have a non-zero height even without a frame")
    #expect(wide.height > 0, "Wrapping content must have a non-zero height even without a frame")
    #expect(
      narrow.height > wide.height,
      "A narrower width must wrap to more lines and therefore be taller, proving the requested width is honored"
    )
  }

  @Test("Empty content measures as zero")
  func measuresEmptyContentAsZero() {
    let view = ParagraphNSView()
    view.setParagraphContents(
      NSMutableAttributedString(string: ""),
      textAnimation: .none,
      isStreamComplete: true
    )

    #expect(view.measureSize(fittingWidth: 400) == .zero)
  }

  @Test("Character Streaming uses transformed TextKit rendering")
  func characterStreamingParagraphIntegration() {
    let view = ParagraphNSView(characterStreaming: true)
    view.setParagraphContents(
      NSMutableAttributedString(string: "AB"),
      textAnimation: .characterStreaming,
      isStreamComplete: false
    )

    #expect(view.string == "A")
    #expect(view.layoutManager is CharacterStreamingLayoutManager)
    #expect(
      view.textStorage?.attribute(
        .shadow,
        at: 0,
        effectiveRange: nil
      ) == nil
    )

    view.finishTextAnimation()

    #expect(view.string == "AB")
  }

  @Test("Rapid snapshots preserve the pending Character Streaming deadline")
  func characterStreamingRapidSnapshots() {
    let view = ParagraphNSView(characterStreaming: true)
    view.setParagraphContents(
      NSMutableAttributedString(string: "ABCDE"),
      textAnimation: .characterStreaming,
      isStreamComplete: false
    )
    #expect(view.string == "A")

    view.setParagraphContents(
      NSMutableAttributedString(string: "ABCDEF"),
      textAnimation: .characterStreaming,
      isStreamComplete: false
    )

    #expect(view.string == "A")
    view.finishTextAnimation()
  }

  @Test("A drained queue still enforces Character Streaming cadence")
  func characterStreamingDrainedQueueCadence() {
    let view = ParagraphNSView(characterStreaming: true)
    view.setParagraphContents(
      NSMutableAttributedString(string: "A"),
      textAnimation: .characterStreaming,
      isStreamComplete: true
    )
    #expect(view.string == "A")

    view.setParagraphContents(
      NSMutableAttributedString(string: "AB"),
      textAnimation: .characterStreaming,
      isStreamComplete: true
    )

    #expect(view.string == "A")
    view.finishTextAnimation()
  }

  @Test("Detaching settles Character Streaming and stops scheduled work")
  func characterStreamingSettlesWhenDetached() {
    let view = ParagraphNSView(characterStreaming: true)
    view.setParagraphContents(
      NSMutableAttributedString(string: "AB"),
      textAnimation: .characterStreaming,
      isStreamComplete: true
    )
    #expect(view.string == "A")

    let window = NSWindow()
    window.contentView?.addSubview(view)
    view.removeFromSuperview()

    #expect(view.string == "AB")
  }

  @Test("Character Streaming remains settled when Reduce Motion turns off")
  func characterStreamingReduceMotionToggle() {
    let contents = NSMutableAttributedString(string: "Already visible")
    let view = ParagraphNSView(characterStreaming: true)
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

    #expect(view.string == contents.string)
    #expect(view.layoutManager is CharacterStreamingLayoutManager)
    view.finishTextAnimation()
  }

  @Test("Completion-only updates preserve an active Fade")
  func fadeCompletionPreservesAnimation() throws {
    let view = ParagraphNSView()
    let initial = NSMutableAttributedString(
      string: "A",
      attributes: [.foregroundColor: NSColor.black]
    )
    view.setParagraphContents(
      initial,
      textAnimation: .none,
      isStreamComplete: false
    )

    let updated = NSMutableAttributedString(
      string: "AB",
      attributes: [.foregroundColor: NSColor.black]
    )
    view.setParagraphContents(
      updated,
      textAnimation: .fade,
      isStreamComplete: false
    )
    let before = try #require(
      view.textStorage?.attribute(
        .foregroundColor,
        at: 1,
        effectiveRange: nil
      ) as? NSColor
    ).alphaComponent

    view.setParagraphContents(
      updated,
      textAnimation: .fade,
      isStreamComplete: true
    )
    let after = try #require(
      view.textStorage?.attribute(
        .foregroundColor,
        at: 1,
        effectiveRange: nil
      ) as? NSColor
    ).alphaComponent

    #expect(before < 1)
    #expect(after == before)
    view.finishTextAnimation()
  }

  @Test("Character Streaming wrapped size grows with its visible prefix")
  func characterStreamingWrappedMeasurement() {
    let view = ParagraphNSView(characterStreaming: true)
    view.setParagraphContents(
      NSMutableAttributedString(
        string: "This paragraph grows across several narrow wrapped lines."
      ),
      textAnimation: .characterStreaming,
      isStreamComplete: true
    )
    let initial = view.measureSize(fittingWidth: 70)

    view.finishTextAnimation()
    let settled = view.measureSize(fittingWidth: 70)

    #expect(settled.height > initial.height)
  }

  @Test("Streaming size cache evicts prior visible prefixes")
  func characterStreamingSizeCacheIsBounded() {
    let coordinator = ParagraphView.Coordinator()
    let key = ParagraphSizeCacheKey(width: 70, visibleUTF16Length: 1)
    coordinator.sizeCache[key] = CGSize(width: 70, height: 20)

    coordinator.updateVisibleUTF16Length(2)

    #expect(coordinator.sizeCache.isEmpty)
    #expect(coordinator.lastVisibleUTF16Length == 2)
  }

  @Test("AppKit Character Streaming translates positive offsets below baseline")
  func characterStreamingBaselineDirection() {
    #expect(CharacterStreamingLayoutManager.baselineTranslation(5) == 5)
  }

  @Test("AppKit renders blurred glyph pixels before crossfading to sharp")
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

  private func renderedGlyphMetrics(
    for transform: CharacterStreamingTransform
  ) throws -> CharacterStreamingGlyphImageMetrics {
    let textStorage = NSTextStorage(
      attributedString: NSAttributedString(
        string: "A",
        attributes: [
          .font: NSFont.systemFont(ofSize: 40),
          .foregroundColor: NSColor.red
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

    func renderImage() throws -> CGImage {
      let image = NSImage(
        size: CGSize(width: 100, height: 100),
        flipped: true
      ) { _ in
        layoutManager.drawGlyphs(
          forGlyphRange: glyphRange,
          at: CGPoint(x: 20, y: 20)
        )
        return true
      }
      var proposedRect = CGRect(
        origin: .zero,
        size: image.size
      )
      return try #require(
        image.cgImage(
          forProposedRect: &proposedRect,
          context: nil,
          hints: nil
        )
      )
    }

    let image = try renderImage()
    if transform.blurRadius > 0 {
      let sourceCount = layoutManager.cachedGlyphImageCount
      let blurredCount = layoutManager.cachedBlurredImageCount
      _ = try renderImage()
      #expect(sourceCount == 1)
      #expect(blurredCount == 1)
      #expect(layoutManager.cachedGlyphImageCount == sourceCount)
      #expect(layoutManager.cachedBlurredImageCount == blurredCount)
      #expect(layoutManager.renderedGlyphImageCount == 1)
      textStorage.addAttribute(
        .foregroundColor,
        value: NSColor.blue,
        range: NSRange(location: 0, length: textStorage.length)
      )
      _ = try renderImage()
      #expect(layoutManager.renderedGlyphImageCount == 2)
      #expect(layoutManager.cachedGlyphImageCount == 1)
      #expect(layoutManager.cachedBlurredImageCount == 1)
      layoutManager.clearAnimations()
      #expect(layoutManager.cachedGlyphImageCount == 0)
      #expect(layoutManager.cachedBlurredImageCount == 0)
    }
    return characterStreamingGlyphImageMetrics(for: image)
  }
}
#endif
