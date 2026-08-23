//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
@testable import SwiftStreamingMarkdown
import Testing

@Suite("Character Streaming")
struct ParagraphAnimationTests {
  @Test("Releases exactly one grapheme and never batches at one timestamp")
  func releasesOneAtATime() throws {
    let state = CharacterStreamingState()
    state.update(target: attributed("abcd"), isComplete: false, at: 0)

    let first = try #require(state.releaseNext(at: 0))
    #expect(substring("abcd", in: first.range) == "a")
    #expect(state.visibleAttributedText.string == "a")
    #expect(state.releaseNext(at: 0) == nil)
    #expect(state.visibleAttributedText.string == "a")

    let second = try #require(state.releaseNext(at: 0.018))
    #expect(substring("abcd", in: second.range) == "b")
    #expect(state.visibleAttributedText.string == "ab")
  }

  @Test("Uses 18ms at low backlog and smoothly accelerates up to four times")
  func adaptiveCadence() {
    let low = CharacterStreamingState.releaseInterval(forBacklog: 1)
    let medium = CharacterStreamingState.releaseInterval(forBacklog: 32)
    let high = CharacterStreamingState.releaseInterval(forBacklog: 64)

    #expect(low == 0.018)
    #expect(medium < low)
    #expect(medium > high)
    #expect(abs(high - 0.0045) < 0.000_001)
  }

  @Test("Cadence returns toward 18ms while backlog drains")
  func cadenceSlowsWhileDraining() throws {
    let state = CharacterStreamingState()
    state.update(
      target: attributed(String(repeating: "a", count: 80)),
      isComplete: true,
      at: 0
    )
    let initialInterval = state.nextReleaseInterval

    for index in 0..<77 {
      _ = try #require(state.releaseNext(at: Double(index + 1)))
    }

    #expect(initialInterval < state.nextReleaseInterval)
    #expect(state.nextReleaseInterval == 0.018)
  }

  @Test("Idle queues retain the next release deadline")
  func idleQueueRetainsDeadline() throws {
    let state = CharacterStreamingState()
    state.update(target: attributed("A"), isComplete: true, at: 0)
    _ = try #require(state.releaseNext(at: 0))
    #expect(!state.hasPendingGrapheme)

    state.update(target: attributed("AB"), isComplete: true, at: 0.001)
    #expect(state.releaseNext(at: 0.001) == nil)
    #expect(state.releaseNext(at: 0.004_499) == nil)
    #expect(abs(state.releaseDelay(at: 0.001) - 0.017) < 0.000_001)

    let release = try #require(state.releaseNext(at: 0.018))
    #expect(substring("AB", in: release.range) == "B")
  }

  @Test("Withholds a terminal grapheme across chunks that extend it")
  func crossChunkContinuity() throws {
    let state = CharacterStreamingState()
    state.update(target: attributed("Cafe"), isComplete: false, at: 0)
    for time in [0.0, 0.018, 0.036] {
      _ = try #require(state.releaseNext(at: time))
    }
    #expect(state.visibleAttributedText.string == "Caf")
    #expect(!state.hasPendingGrapheme)

    let continued = "Cafe\u{301} "
    state.update(target: attributed(continued), isComplete: false, at: 0.05)
    let release = try #require(state.releaseNext(at: 0.054))

    #expect(substring(continued, in: release.range) == "e\u{301}")
    #expect(state.visibleAttributedText.string == "Cafe\u{301}")
    #expect(!state.hasPendingGrapheme)
  }

  @Test("Starts with the exact rise, grow, sharpen, and fade transform")
  func exactInitialTransform() {
    let transform = CharacterStreamingTransform.value(at: 0)

    #expect(transform.opacity == 0.08)
    #expect(transform.scale == 0.82)
    #expect(transform.baselineOffset == 5)
    #expect(transform.blurRadius == 2)
  }

  @Test("Settles exactly to the final transform after 260ms")
  func exactFinalTransform() {
    let animation = CharacterStreamingAnimation(
      range: NSRange(location: 0, length: 1),
      startTime: 1
    )
    let transform = animation.transform(
      at: 1 + ParagraphAnimationConstants.characterAnimationDuration
    )

    #expect(transform.opacity == 1)
    #expect(transform.scale == 1)
    #expect(transform.baselineOffset == 0)
    #expect(transform.blurRadius == 0)
    #expect(animation.isFinished(at: 1.26))
  }

  @Test("Overlapping shaped glyph ranges animate once using the newest release")
  func overlappingShapedGlyphClusters() {
    let olderTransform = CharacterStreamingTransform.value(at: 0.75)
    let newerTransform = CharacterStreamingTransform.value(at: 0.25)
    let settledNeighborTransform = CharacterStreamingTransform.value(at: 0.5)
    let clusters = CharacterStreamingLayoutManager.coalescedGlyphFrames([
      CharacterStreamingGlyphAnimationFrame(
        range: NSRange(location: 0, length: 2),
        transform: olderTransform,
        startTime: 1
      ),
      CharacterStreamingGlyphAnimationFrame(
        range: NSRange(location: 1, length: 2),
        transform: newerTransform,
        startTime: 2
      ),
      CharacterStreamingGlyphAnimationFrame(
        range: NSRange(location: 4, length: 1),
        transform: settledNeighborTransform,
        startTime: 1.5
      )
    ])

    #expect(clusters.count == 2)
    #expect(clusters[0].range == NSRange(location: 0, length: 3))
    #expect(clusters[0].transform == newerTransform)
    #expect(clusters[0].startTime == 2)
    #expect(clusters[1].range == NSRange(location: 4, length: 1))
    #expect(
      CharacterStreamingLayoutManager.unionRange(
        clusters.map(\.range)
      ) == NSRange(location: 0, length: 5)
    )
  }

  @Test("Glyph blur crossfades a blurred-only pass to the sharp pass")
  func genuineGlyphBlurBlend() {
    let initial = CharacterStreamingGlyphBlend.value(
      for: .value(at: 0)
    )
    #expect(initial.blurredAlpha == 0.08)
    #expect(initial.sharpAlpha == 0)
    #expect(initial.blurRadius == 2)

    let intermediate = CharacterStreamingGlyphBlend.value(
      for: .value(at: 0.5)
    )
    #expect(intermediate.blurredAlpha > 0)
    #expect(intermediate.sharpAlpha > 0)
    #expect(intermediate.blurRadius > 0)
    #expect(intermediate.blurRadius < 2)

    let settled = CharacterStreamingGlyphBlend.value(
      for: .value(at: 1)
    )
    #expect(settled.blurredAlpha == 0)
    #expect(settled.sharpAlpha == 1)
    #expect(settled.blurRadius == 0)
  }

  @Test("Releases Unicode composed character sequences intact")
  func unicodeComposedGraphemes() throws {
    let text = "👨‍👩‍👧‍👦e\u{301}🇺🇸X"
    let state = CharacterStreamingState()
    state.update(target: attributed(text), isComplete: false, at: 0)

    let family = try #require(state.releaseNext(at: 0))
    let accented = try #require(state.releaseNext(at: 0.018))
    let flag = try #require(state.releaseNext(at: 0.036))

    #expect(substring(text, in: family.range) == "👨‍👩‍👧‍👦")
    #expect(substring(text, in: accented.range) == "e\u{301}")
    #expect(substring(text, in: flag.range) == "🇺🇸")
    #expect(state.visibleAttributedText.string == "👨‍👩‍👧‍👦e\u{301}🇺🇸")
    #expect(!state.hasPendingGrapheme)
  }

  @Test("Reduce Motion settles Character Streaming immediately")
  func reduceMotion() {
    #expect(
      resolvedTextAnimation(.characterStreaming, reduceMotion: false)
        == .characterStreaming
    )
    #expect(
      resolvedTextAnimation(.characterStreaming, reduceMotion: true)
        == .none
    )
    #expect(resolvedTextAnimation(.fade, reduceMotion: true) == .none)
  }

  @Test("Completion drains the withheld terminal grapheme")
  func completionDrain() throws {
    let state = CharacterStreamingState()
    state.update(target: attributed("A"), isComplete: false, at: 0)
    #expect(!state.hasPendingGrapheme)
    #expect(state.releaseNext(at: 0) == nil)

    state.update(target: attributed("A"), isComplete: true, at: 0.1)
    #expect(state.hasPendingGrapheme)
    _ = try #require(state.releaseNext(at: 0.1))
    #expect(state.visibleAttributedText.string == "A")
    #expect(!state.hasPendingGrapheme)
  }

  @Test("Parsed lists select their trailing paragraph structurally")
  @MainActor
  func parsedListTailOwnership() async throws {
    let document = await MarkdownParserImpl().parse(
      text: "1. First item\n2. Second item",
      config: .default
    )
    let renderable = try #require(document.renderables.last)
    guard case .orderedList(_, let items) = renderable else {
      Issue.record("Expected an ordered list")
      return
    }

    #expect(items.count == 2)
    #expect(
      !isTrailingStreamingElement(
        at: 0,
        count: items.count,
        parentIsTrailing: true
      )
    )
    #expect(
      isTrailingStreamingElement(
        at: 1,
        count: items.count,
        parentIsTrailing: true
      )
    )
    #expect(
      !isTrailingStreamingElement(
        at: 1,
        count: items.count,
        parentIsTrailing: false
      )
    )
  }

  @Test("Replacement rewinds to a composed prefix and restyling is retained")
  func replacementAndRestyle() throws {
    let state = CharacterStreamingState()
    state.update(target: attributed("abcX"), isComplete: false, at: 0)
    for time in [0.0, 0.018, 0.036] {
      _ = try #require(state.releaseNext(at: time))
    }

    #expect(state.visibleAttributedText.string == "abc")

    state.update(target: attributed("abZ!"), isComplete: false, at: 0.05)
    #expect(state.visibleAttributedText.string == "ab")
    _ = try #require(state.releaseNext(at: 0.054))
    #expect(state.visibleAttributedText.string == "abZ")

    let styleKey = NSAttributedString.Key("CharacterStreamingTests.style")
    let restyled = NSMutableAttributedString(string: "abZ!")
    restyled.addAttribute(
      styleKey,
      value: "updated",
      range: NSRange(location: 0, length: restyled.length)
    )
    state.update(target: restyled, isComplete: false, at: 0.06)

    #expect(
      state.visibleAttributedText.attribute(
        styleKey,
        at: 0,
        effectiveRange: nil
      ) as? String == "updated"
    )
  }

  @Test("Normalization changes rewind to composed UTF-16 boundaries")
  func normalizationSafeReplacement() throws {
    try assertNormalizationReplacement(
      from: "\u{00E9}X",
      to: "e\u{301}X",
      expected: "e\u{301}"
    )
    try assertNormalizationReplacement(
      from: "e\u{301}X",
      to: "\u{00E9}X",
      expected: "\u{00E9}"
    )

    let extendedPrefix = CharacterStreamingState()
    extendedPrefix.update(
      target: attributed("e"),
      isComplete: true,
      at: 0
    )
    _ = try #require(extendedPrefix.releaseNext(at: 0))
    extendedPrefix.update(
      target: attributed("e\u{301}X"),
      isComplete: false,
      at: 0.01
    )
    #expect(extendedPrefix.visibleAttributedText.string.isEmpty)
    let release = try #require(extendedPrefix.releaseNext(at: 0.018))
    #expect(substring("e\u{301}X", in: release.range) == "e\u{301}")
  }

  @Test("Preserves attributed Markdown runs in released content")
  func attributedContent() throws {
    let styleKey = NSAttributedString.Key("CharacterStreamingTests.typography")
    let target = NSMutableAttributedString(string: "ab")
    target.addAttribute(
      styleKey,
      value: "bold-link",
      range: NSRange(location: 0, length: 1)
    )
    let state = CharacterStreamingState()
    state.update(target: target, isComplete: false, at: 0)
    _ = try #require(state.releaseNext(at: 0))

    #expect(
      state.visibleAttributedText.attribute(
        styleKey,
        at: 0,
        effectiveRange: nil
      ) as? String == "bold-link"
    )
  }

  @Test("Bounds active animation state under sustained backlog")
  func boundedAnimationState() throws {
    let state = CharacterStreamingState()
    state.update(
      target: attributed(String(repeating: "a", count: 100)),
      isComplete: true,
      at: 0
    )

    var time: CFTimeInterval = 0
    for _ in 0..<100 {
      _ = try #require(state.releaseNext(at: time))
      time += state.nextReleaseInterval
    }

    #expect(!state.activeAnimations.isEmpty)
    #expect(
      state.activeAnimations.count
        <= ParagraphAnimationConstants.maximumActiveCharacterAnimations
    )
  }

  @Test("Public style selection is explicit and type safe")
  func styleSelection() {
    let characterStreaming = MarkdownRenderConfig(
      textAnimation: .characterStreaming
    )
    let fade = characterStreaming.withTextAnimation(.fade)

    #expect(MarkdownRenderConfig.default.textAnimation == .none)
    #expect(characterStreaming.textAnimation == .characterStreaming)
    #expect(fade.textAnimation == .fade)
  }

  @Test("Standard fade still targets only appended content")
  func standardFadeAppend() throws {
    let previous = "Stable text"
    let updated = "\(previous) fades in"
    let plan = try #require(
      ParagraphRevealPlan.appendedText(
        previousText: previous,
        newText: updated
      )
    )
    let coveredRange = try #require(plan.coveredRange)

    #expect(coveredRange.location == (previous as NSString).length)
    #expect(substring(updated, in: coveredRange) == " fades in")
    #expect(plan.segments.first?.delay == 0)
    #expect(
      plan.segments.last?.delay
        == ParagraphAnimationConstants.fadeStaggerDuration
    )
  }

  @Test("Visible prefix length participates in paragraph size caching")
  func streamingSizeCacheKey() {
    let initial = ParagraphSizeCacheKey(width: 120, visibleUTF16Length: 1)
    let wrapped = ParagraphSizeCacheKey(width: 120, visibleUTF16Length: 80)

    #expect(initial != wrapped)
  }
}

private func attributed(_ text: String) -> NSAttributedString {
  NSAttributedString(string: text)
}

private func substring(_ text: String, in range: NSRange) -> String {
  (text as NSString).substring(with: range)
}

private func assertNormalizationReplacement(
  from original: String,
  to replacement: String,
  expected: String
) throws {
  let state = CharacterStreamingState()
  state.update(target: attributed(original), isComplete: false, at: 0)
  _ = try #require(state.releaseNext(at: 0))
  #expect(!state.visibleAttributedText.string.isEmpty)

  state.update(target: attributed(replacement), isComplete: false, at: 0.01)
  #expect(state.visibleAttributedText.string.isEmpty)

  let release = try #require(state.releaseNext(at: 0.018))
  #expect(substring(replacement, in: release.range) == expected)
  #expect(state.visibleAttributedText.string == expected)
}

private extension ParagraphRevealPlan {
  var coveredRange: NSRange? {
    guard let first = segments.first, let last = segments.last else {
      return nil
    }
    return NSRange(
      location: first.range.location,
      length: NSMaxRange(last.range) - first.range.location
    )
  }
}
