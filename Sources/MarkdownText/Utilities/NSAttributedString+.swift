//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension NSAttributedString {
  func hasPrefix(_ prefix: NSAttributedString) -> Bool {
    length >= prefix.length && attributedSubstring(from: NSRange(location: 0, length: prefix.length)).isEqual(to: prefix)
  }

  /// Whether `other` has the same text as this string from the start through
  /// the end of `range`, so a selection of `range` survives changing this text to `other`.
  func hasSameText(through range: NSRange, as other: NSAttributedString) -> Bool {
    let end = NSMaxRange(range)
    guard end <= length, end <= other.length else { return false }
    let prefix = NSRange(location: 0, length: end)
    return (string as NSString).substring(with: prefix) == (other.string as NSString).substring(with: prefix)
  }

  func splitIntoWords(withIn range: NSRange) -> [NSRange] {
    var words: [NSRange] = []
    let string = self.string as NSString

    guard range.location != NSNotFound,
          range.location >= 0,
          NSMaxRange(range) <= string.length else {
      return words
    }

    string.enumerateSubstrings(
      in: range,
      options: [.byWords, .localized, .substringNotRequired]
    ) { (_, substringRange, _, _) in

      // Add any separator/whitespace before this word
      if let lastWord = words.last {
        let gapStart = NSMaxRange(lastWord)
        let gapLength = substringRange.location - gapStart

        if gapLength > 0 {
          let gapRange = NSRange(location: gapStart, length: gapLength)
          words.append(gapRange)
        }
      } else {
        // Handle any leading separators/whitespace
        let leadingGapLength = substringRange.location - range.location
        if leadingGapLength > 0 {
          let leadingGapRange = NSRange(location: range.location, length: leadingGapLength)
          words.append(leadingGapRange)
        }
      }

      // Add the word range
      words.append(substringRange)
    }

    // Handle any trailing separators/whitespace
    if let lastWord = words.last {
      let trailingStart = NSMaxRange(lastWord)
      let trailingLength = NSMaxRange(range) - trailingStart

      if trailingLength > 0 {
        let trailingRange = NSRange(location: trailingStart, length: trailingLength)
        words.append(trailingRange)
      }
    } else {
      // If no words were found, return entire range
      if range.length > 0 {
        words.append(range)
      }
    }

    return words
  }
}

extension NSMutableAttributedString {
  /// Updates the paragraph style of every run in `range` (the whole string by
  /// default), keeping properties set by earlier passes.
  func updateParagraphStyle(in range: NSRange? = nil, _ update: (NSMutableParagraphStyle) -> Void) {
    enumerateAttribute(.paragraphStyle, in: range ?? NSRange(location: 0, length: length)) { value, runRange, _ in
      let paragraphStyle = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
      update(paragraphStyle)
      addAttribute(.paragraphStyle, value: paragraphStyle, range: runRange)
    }
  }
}
