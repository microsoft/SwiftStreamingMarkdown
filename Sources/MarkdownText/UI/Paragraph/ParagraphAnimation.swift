//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

enum ParagraphAnimationConstants {
  static let fadeInDuration: CFTimeInterval = 0.5
  static let delayBetweenWordsRatio: Double = 0.1
  /// Vertical distance, in points, that a word travels while rising into place
  /// for the `.rise` / `.fadeAndRise` styles. The word starts this far below
  /// its final baseline and settles up to `0`.
  static let riseDistance: CGFloat = 8
  /// Fixed delay between consecutive characters in a rise wave. A small,
  /// constant per-character delay (rather than a per-chunk-normalized delay)
  /// makes characters ripple in continuously instead of moving as rigid blocks.
  static let delayBetweenCharacters: CFTimeInterval = 0.02
  /// Maximum time the rise wave is allowed to run ahead of real time. Caps the
  /// backlog so a large streamed chunk doesn't leave trailing characters
  /// lagging far behind; beyond this lead, characters start catching up.
  static let maxWaveLead: CFTimeInterval = 0.3
}

/// How newly appended words animate in when `shouldAnimateText` is enabled.
public enum ParagraphAnimationStyle: Sendable, Hashable {
  /// Words fade from transparent to opaque (the default, original behavior).
  case fade
  /// Words rise from slightly below their baseline into place.
  case rise
  /// Words simultaneously fade in and rise into place.
  case fadeAndRise

  /// Whether this style animates opacity.
  var fades: Bool {
    switch self {
    case .fade, .fadeAndRise: return true
    case .rise: return false
    }
  }

  /// Whether this style animates vertical offset.
  var rises: Bool {
    switch self {
    case .rise, .fadeAndRise: return true
    case .fade: return false
    }
  }
}

struct FadeAnimationData {
  let id: UUID = UUID()
  let startTime: CFTimeInterval
  let duration: CFTimeInterval
  let range: NSRange
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
