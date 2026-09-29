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

extension NSAttributedString.Key {
  /// Library-internal: marks each block of a `.textGroup`, so its text view can
  /// expose one accessibility element per block.
  static let textBlock = NSAttributedString.Key("markdown.textBlock")
}

/// The value of `.textBlock`: the block's ID, and its level if it's a heading.
struct TextBlock: Hashable {
  let id: String
  let headingLevel: Int?
}

extension MarkdownRenderable {
  /// Line spacing paragraphs render with; headings have none.
  static let paragraphLineSpacing: CGFloat = 5

  /// The text of headings and paragraphs: the blocks that can share a text view.
  fileprivate var textBlockContent: NSMutableAttributedString? {
    switch self {
    case .paragraph(_, let content), .heading(_, _, let content): return content
    default: return nil
    }
  }

  fileprivate var headingLevel: Int? {
    guard case .heading(_, let level, _) = self else { return nil }
    return level
  }

  /// The line spacing a text block renders with.
  fileprivate var lineSpacing: CGFloat {
    isHeading ? 0 : Self.paragraphLineSpacing
  }
}

extension NSMutableAttributedString {
  /// Applies the line spacing and alignment paragraphs render with.
  func applyParagraphLayout() {
    updateParagraphStyle {
      $0.lineSpacing = MarkdownRenderable.paragraphLineSpacing
      $0.alignment = .left
    }
  }
}

extension Array where Element == MarkdownRenderable {

  /// Merges each run of adjacent non-empty headings and paragraphs into a
  /// single `.textGroup`, so the run renders in one text view and a text
  /// selection can span it.
  ///
  /// A group keeps its first block's ID, so as streaming appends blocks
  /// SwiftUI keeps updating the same text view.
  func groupingAdjacentTextBlocks(config: MarkdownRenderConfig) -> [MarkdownRenderable] {
    var result: [MarkdownRenderable] = []
    var run: [MarkdownRenderable] = []

    func flushRun() {
      if run.count > 1 {
        result.append(.textGroup(id: run[0].id, blocks: run, content: run.joinedAsTextBlocks(config: config)))
      } else {
        result += run
      }
      run.removeAll()
    }

    for renderable in self {
      // An empty block has no line to space from its neighbors, so it keeps its own view.
      if let content = renderable.textBlockContent, content.length > 0 {
        run.append(renderable)
      } else {
        flushRun()
        result.append(renderable)
      }
    }
    flushRun()
    return result
  }

  /// Joins text blocks with paragraph breaks, spaced to match the
  /// `blockSpacing` gap that `BlockView` puts between separate blocks, but
  /// never closer than the line spacing TextKit puts at a break.
  private func joinedAsTextBlocks(config: MarkdownRenderConfig) -> NSMutableAttributedString {
    let separator = NSAttributedString(string: "\n", attributes: [.font: config.paragraphStyle.textFonts.normal])
    let result = NSMutableAttributedString()
    var previousLineSpacing: CGFloat = 0
    for block in self {
      guard let content = block.textBlockContent else { continue }
      if result.length > 0 {
        result.append(separator)
      }
      let start = result.length
      result.append(content)
      result.addAttribute(.textBlock, value: TextBlock(id: block.id, headingLevel: block.headingLevel), range: NSRange(location: start, length: content.length))
      if start > 0 {
        // Only the block's first line: later lines come from soft/hard breaks.
        let firstLine = (content.string as NSString).paragraphRange(for: NSRange(location: 0, length: 0))
        let spacing = Swift.max(0, config.blockSpacing - lineSpacingAtBreak(after: previousLineSpacing, before: block.lineSpacing))
        result.updateParagraphStyle(in: NSRange(location: start + firstLine.location, length: firstLine.length)) { $0.paragraphSpacingBefore = spacing }
      }
      previousLineSpacing = block.lineSpacing
    }
    return result
  }

  /// The line spacing TextKit already puts at a break between two blocks: the
  /// next block's in TextKit 2 (UITextView), the previous block's in TextKit 1 (NSTextView).
  private func lineSpacingAtBreak(after previous: CGFloat, before next: CGFloat) -> CGFloat {
    #if canImport(UIKit)
    return next
    #else
    return previous
    #endif
  }
}
