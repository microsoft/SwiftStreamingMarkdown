//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

enum ParagraphAnimationConstants {
  static let fadeInDuration: CFTimeInterval = 0.45
  static let fadeStaggerDuration: CFTimeInterval = 0.12
  static let fadeTargetSegmentLength = 8
  static let maximumFadeSegmentCount = 24

  static let characterAnimationDuration: CFTimeInterval = 0.26
  static let characterReleaseInterval: CFTimeInterval = 0.018
  static let maximumCharacterReleaseSpeed = 4.0
  static let lowBacklogGraphemeCount = 3
  static let maximumAccelerationBacklog = 64
  static let maximumActiveCharacterAnimations = 64

  static let initialCharacterOpacity: CGFloat = 0.08
  static let initialCharacterScale: CGFloat = 0.82
  static let initialCharacterBaselineOffset: CGFloat = 5
  static let initialCharacterBlurRadius: CGFloat = 2
}

struct ParagraphSizeCacheKey: Hashable {
  let width: CGFloat
  let visibleUTF16Length: Int
}

struct ParagraphRevealSegment: Equatable {
  let range: NSRange
  let delay: CFTimeInterval
}

struct ParagraphRevealPlan: Equatable {
  let segments: [ParagraphRevealSegment]
  let duration: CFTimeInterval

  static func appendedText(previousText: String, newText: String) -> ParagraphRevealPlan? {
    let previous = previousText as NSString
    let updated = newText as NSString

    guard updated.length > previous.length,
          updated.substring(with: NSRange(location: 0, length: previous.length)) == previousText else {
      return nil
    }
    let firstAppendedCharacter = updated.rangeOfComposedCharacterSequence(
      at: previous.length
    )
    guard firstAppendedCharacter.location == previous.length else {
      return nil
    }

    let appendedRange = NSRange(
      location: previous.length,
      length: updated.length - previous.length
    )
    let preferredSegmentCount = max(
      1,
      Int(ceil(Double(appendedRange.length) / Double(ParagraphAnimationConstants.fadeTargetSegmentLength)))
    )
    let segmentCount = min(
      ParagraphAnimationConstants.maximumFadeSegmentCount,
      preferredSegmentCount
    )
    let ranges = segmentRanges(
      in: updated,
      appendedRange: appendedRange,
      segmentCount: segmentCount
    )
    let delayStep = ranges.count > 1
      ? ParagraphAnimationConstants.fadeStaggerDuration / Double(ranges.count - 1)
      : 0
    let segments = ranges.enumerated().map { index, range in
      ParagraphRevealSegment(range: range, delay: Double(index) * delayStep)
    }
    let duration = (segments.last?.delay ?? 0) + ParagraphAnimationConstants.fadeInDuration
    return ParagraphRevealPlan(segments: segments, duration: duration)
  }

  private static func segmentRanges(
    in string: NSString,
    appendedRange: NSRange,
    segmentCount: Int
  ) -> [NSRange] {
    guard segmentCount > 1 else {
      return [appendedRange]
    }

    let end = NSMaxRange(appendedRange)
    var segmentStart = appendedRange.location
    var ranges: [NSRange] = []
    ranges.reserveCapacity(segmentCount)

    for index in 1..<segmentCount {
      let target = appendedRange.location + appendedRange.length * index / segmentCount
      let composedCharacterRange = string.rangeOfComposedCharacterSequence(
        at: min(target, end - 1)
      )
      let boundary = min(end, max(segmentStart, NSMaxRange(composedCharacterRange)))
      guard boundary > segmentStart, boundary < end else {
        continue
      }
      ranges.append(NSRange(location: segmentStart, length: boundary - segmentStart))
      segmentStart = boundary
    }

    ranges.append(NSRange(location: segmentStart, length: end - segmentStart))
    return ranges
  }
}

struct FadeAnimationSegment {
  let range: NSRange
  let startTime: CFTimeInterval
}

struct FadeAnimationData {
  let segments: [FadeAnimationSegment]

  init(
    plan: ParagraphRevealPlan,
    startTime: CFTimeInterval,
    previousAnimation: FadeAnimationData? = nil,
    contentLength: Int
  ) {
    let unfinishedSegments = previousAnimation?.segments.filter {
      startTime < $0.startTime + ParagraphAnimationConstants.fadeInDuration
        && NSMaxRange($0.range) <= contentLength
    } ?? []
    let appendedSegments = plan.segments.map {
      FadeAnimationSegment(range: $0.range, startTime: startTime + $0.delay)
    }
    segments = Array(
      (unfinishedSegments + appendedSegments)
        .suffix(ParagraphAnimationConstants.maximumFadeSegmentCount)
    )
  }

  var endTime: CFTimeInterval {
    (segments.map(\.startTime).max() ?? 0) + ParagraphAnimationConstants.fadeInDuration
  }
}

struct CharacterStreamingTransform: Equatable {
  let opacity: CGFloat
  let scale: CGFloat
  let baselineOffset: CGFloat
  let blurRadius: CGFloat

  static func value(at progress: CGFloat) -> CharacterStreamingTransform {
    let easedProgress = paragraphEaseOut(min(max(progress, 0), 1))
    let remaining = 1 - easedProgress
    return CharacterStreamingTransform(
      opacity: ParagraphAnimationConstants.initialCharacterOpacity
        + (1 - ParagraphAnimationConstants.initialCharacterOpacity) * easedProgress,
      scale: ParagraphAnimationConstants.initialCharacterScale
        + (1 - ParagraphAnimationConstants.initialCharacterScale) * easedProgress,
      baselineOffset: ParagraphAnimationConstants.initialCharacterBaselineOffset * remaining,
      blurRadius: ParagraphAnimationConstants.initialCharacterBlurRadius * remaining
    )
  }
}

struct CharacterStreamingAnimation: Equatable {
  let range: NSRange
  let startTime: CFTimeInterval

  func transform(at time: CFTimeInterval) -> CharacterStreamingTransform {
    let progress = CGFloat(
      min(max((time - startTime) / ParagraphAnimationConstants.characterAnimationDuration, 0), 1)
    )
    return .value(at: progress)
  }

  func isFinished(at time: CFTimeInterval) -> Bool {
    time >= startTime + ParagraphAnimationConstants.characterAnimationDuration
  }
}

struct CharacterStreamingRelease: Equatable {
  let range: NSRange
  let time: CFTimeInterval
}

final class CharacterStreamingState {
  private(set) var target = NSAttributedString()
  private(set) var releasedUTF16Length = 0
  private(set) var pendingGraphemeCount = 0
  private(set) var activeAnimations: [CharacterStreamingAnimation] = []
  private(set) var isComplete = false

  private var nextReleaseDeadline: CFTimeInterval?

  var visibleAttributedText: NSAttributedString {
    target.attributedSubstring(
      from: NSRange(location: 0, length: releasedUTF16Length)
    )
  }

  var hasPendingGrapheme: Bool {
    pendingGraphemeCount > 0
  }

  var nextReleaseInterval: CFTimeInterval {
    Self.releaseInterval(forBacklog: pendingGraphemeCount)
  }

  func releaseDelay(at time: CFTimeInterval) -> CFTimeInterval {
    guard let nextReleaseDeadline else { return 0 }
    return max(0, nextReleaseDeadline - time)
  }

  func update(
    target newTarget: NSAttributedString,
    isComplete: Bool,
    at time: CFTimeInterval
  ) {
    let oldString = target.string
    let newString = newTarget.string

    let exactPrefixLength = Self.commonPrefixUTF16Length(
      oldString,
      newString
    )
    var retainedPrefixLength = releasedUTF16Length
    if exactPrefixLength != oldString.utf16.count {
      retainedPrefixLength = min(retainedPrefixLength, exactPrefixLength)
    }
    releasedUTF16Length = Self.composedSequenceBoundary(
      atOrBefore: retainedPrefixLength,
      in: newString
    )
    activeAnimations.removeAll {
      NSMaxRange($0.range) > releasedUTF16Length
    }

    target = NSAttributedString(attributedString: newTarget)
    self.isComplete = isComplete
    releasedUTF16Length = min(releasedUTF16Length, target.length)
    pruneAnimations(at: time)
    recalculatePendingGraphemeCount()
  }

  func releaseNext(at time: CFTimeInterval) -> CharacterStreamingRelease? {
    guard pendingGraphemeCount > 0,
          nextReleaseDeadline.map({ time >= $0 }) ?? true,
          releasedUTF16Length < releasableUTF16Length else {
      return nil
    }

    let range = (target.string as NSString).rangeOfComposedCharacterSequence(
      at: releasedUTF16Length
    )
    guard range.location == releasedUTF16Length,
          NSMaxRange(range) <= releasableUTF16Length else {
      return nil
    }

    releasedUTF16Length = NSMaxRange(range)
    pendingGraphemeCount -= 1
    nextReleaseDeadline = time + nextReleaseInterval
    pruneAnimations(at: time)
    activeAnimations.append(CharacterStreamingAnimation(range: range, startTime: time))
    if activeAnimations.count > ParagraphAnimationConstants.maximumActiveCharacterAnimations {
      activeAnimations.removeFirst(
        activeAnimations.count - ParagraphAnimationConstants.maximumActiveCharacterAnimations
      )
    }
    return CharacterStreamingRelease(range: range, time: time)
  }

  func pruneAnimations(at time: CFTimeInterval) {
    activeAnimations.removeAll { $0.isFinished(at: time) }
  }

  func settle() {
    releasedUTF16Length = target.length
    pendingGraphemeCount = 0
    activeAnimations.removeAll()
    nextReleaseDeadline = nil
  }

  func reset() {
    target = NSAttributedString()
    releasedUTF16Length = 0
    pendingGraphemeCount = 0
    activeAnimations.removeAll()
    isComplete = false
    nextReleaseDeadline = nil
  }

  static func releaseInterval(forBacklog backlog: Int) -> CFTimeInterval {
    guard backlog > ParagraphAnimationConstants.lowBacklogGraphemeCount else {
      return ParagraphAnimationConstants.characterReleaseInterval
    }

    let accelerationRange = ParagraphAnimationConstants.maximumAccelerationBacklog
      - ParagraphAnimationConstants.lowBacklogGraphemeCount
    let normalizedBacklog = min(
      1,
      Double(backlog - ParagraphAnimationConstants.lowBacklogGraphemeCount)
        / Double(accelerationRange)
    )
    let smoothedBacklog = normalizedBacklog * normalizedBacklog
      * (3 - 2 * normalizedBacklog)
    let speed = 1 + (ParagraphAnimationConstants.maximumCharacterReleaseSpeed - 1)
      * smoothedBacklog
    return ParagraphAnimationConstants.characterReleaseInterval / speed
  }

  private var releasableUTF16Length: Int {
    guard !isComplete, target.length > 0 else {
      return target.length
    }
    return (target.string as NSString).rangeOfComposedCharacterSequence(
      at: target.length - 1
    ).location
  }

  private func recalculatePendingGraphemeCount() {
    let string = target.string as NSString
    let end = releasableUTF16Length
    var location = releasedUTF16Length
    var count = 0
    while location < end {
      let range = string.rangeOfComposedCharacterSequence(at: location)
      guard range.location == location, NSMaxRange(range) <= end else {
        break
      }
      count += 1
      location = NSMaxRange(range)
    }
    pendingGraphemeCount = count
  }

  private static func commonPrefixUTF16Length(
    _ first: String,
    _ second: String
  ) -> Int {
    let firstUTF16 = first as NSString
    let secondUTF16 = second as NSString
    let maximumLength = min(firstUTF16.length, secondUTF16.length)
    var length = 0
    while length < maximumLength,
          firstUTF16.character(at: length) == secondUTF16.character(at: length) {
      length += 1
    }
    return length
  }

  private static func composedSequenceBoundary(
    atOrBefore offset: Int,
    in string: String
  ) -> Int {
    let utf16 = string as NSString
    guard offset > 0, offset < utf16.length else {
      return min(offset, utf16.length)
    }
    let sequence = utf16.rangeOfComposedCharacterSequence(at: offset)
    return sequence.location < offset ? sequence.location : offset
  }
}

func resolvedTextAnimation(
  _ animation: MarkdownRenderConfig.TextAnimation,
  reduceMotion: Bool
) -> MarkdownRenderConfig.TextAnimation {
  reduceMotion ? .none : animation
}

/// Cubic Bezier ease-out curve shared between iOS and macOS paragraph views.
func paragraphEaseOut(_ t: CGFloat) -> CGFloat {
  let c2: CGFloat = 0.1
  let c4: CGFloat = 1.0

  let t2 = t * t
  let t3 = t2 * t
  let mt = 1 - t
  let mt2 = mt * mt

  return 3 * mt2 * t * c2 + 3 * mt * t2 * c4 + t3
}
