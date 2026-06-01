//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown

/// A rewriter that speculatively complete partial emphasis.
public final class PartialEmphasisRewriter: MarkupRewriter {

  /// The text node we are trying to rewrite
  private let targetNode: Text

  static let partialStrong: Regex? = {
    return try? Regex("(?:\\*\\*|__).*$")
  }()

  static let partialItalic: Regex? = {
    return try? Regex("(?:\\*|_).*$")
  }()

  public init(targetNode: Text) {
    self.targetNode = targetNode
  }

  public func visitTableCell(_ tableCell: Table.Cell) -> Markup? {
    return rewriteIfNeeded(inlineContainer: tableCell) ?? tableCell
  }

  public func visitParagraph(_ paragraph: Paragraph) -> Markup? {
    return rewriteIfNeeded(inlineContainer: paragraph) ?? paragraph
  }

  public func visitHeading(_ heading: Heading) -> Markup? {
    return rewriteIfNeeded(inlineContainer: heading) ?? heading
  }

  private func rewriteIfNeeded(inlineContainer: InlineContainer) -> Markup? {
    guard inlineContainer.hasChildren else {
      return nil
    }

    if let lastChild = inlineContainer.lastChild, lastChild.isIdentical(to: targetNode), let text = inlineContainer.lastChild as? Text {
      if let range = text.matchesPartialStrong() {
        let nonMatchingPart = String(text.string[text.string.startIndex..<range.lowerBound])
        let matchingPart = String(text.string[range.lowerBound..<range.upperBound].dropFirst(2))

        let textNode = Text(nonMatchingPart)
        let strongNode = Strong([Text(matchingPart)])

        let targetRange = inlineContainer.lastChildRange
        let replacementNodes: [InlineMarkup] = nonMatchingPart.isEmpty ? [strongNode] :  [textNode, strongNode]
        var mutableContainer = inlineContainer
        mutableContainer.replaceChildrenInRange(targetRange, with: replacementNodes)
        return mutableContainer
      } else if let range = text.matchesPartialItalic() {
        let nonMatchingPart = String(text.string[text.string.startIndex..<range.lowerBound])
        let matchingPart = String(text.string[range.lowerBound..<range.upperBound].dropFirst(1))

        let textNode = Text(nonMatchingPart)
        let emphasisNode = Emphasis([Text(matchingPart)])
        let targetRange = inlineContainer.lastChildRange
        let replacementNodes: [InlineMarkup] = nonMatchingPart.isEmpty ? [emphasisNode] :  [textNode, emphasisNode]
        var mutableContainer = inlineContainer
        mutableContainer.replaceChildrenInRange(targetRange, with: replacementNodes)
        return mutableContainer
      } else {
        return nil
      }
    } else if let container = rewriteEmphasisToStrongIfNeeded(inlineContainer: inlineContainer) {
      return container
    } else {
      return nil
    }
  }

  /// Handles the corner case as below to speculatively rewrite emphasis to strong
  ///
  /// └─ Paragraph
  ///    ├─ Text "Yeah, this is *"
  ///    └─ Emphasis
  ///       └─ Text "cool"
  private func rewriteEmphasisToStrongIfNeeded(inlineContainer: InlineContainer) -> InlineContainer? {
    guard inlineContainer.childCount >= 2 else {
      return nil
    }
    guard let emphasis = inlineContainer.lastChild as? Emphasis else {
      return nil
    }
    guard let emphasizedText = emphasis.firstChild as? Text else {
      return nil
    }

    guard emphasizedText.isIdentical(to: targetNode) else {
      return nil
    }

    guard let precedingText = inlineContainer.child(at: inlineContainer.childCount - 2) as? Text else {
      return nil
    }

    if (precedingText.plainText.hasSuffix("*") && !precedingText.plainText.hasSuffix("**")) || (precedingText.plainText.hasSuffix("_") && !precedingText.plainText.hasSuffix("__")) {
      var mutableContainer = inlineContainer
      let newPrecedingText = Markdown.Text(String(precedingText.plainText.dropLast()))
      let newTrailingStrongText = Markdown.Strong([emphasizedText])
      let startIndex = inlineContainer.childCount - 2
      let endIndex = inlineContainer.childCount
      let newChildren: [InlineMarkup] = newPrecedingText.string.isEmpty ? [ newTrailingStrongText] : [newPrecedingText, newTrailingStrongText]
      mutableContainer.replaceChildrenInRange(startIndex..<endIndex, with: newChildren)
      return mutableContainer
    } else {
      return nil
    }
  }
}

extension Text {

  func matchesPartialStrong() -> Range<String.Index>? {
    guard let regex = PartialEmphasisRewriter.partialStrong else {
      return nil
    }
    let ranges = self.string.ranges(of: regex)
    guard ranges.count == 1, let range = ranges.first, range.upperBound == self.string.endIndex else {
      return nil
    }
    return range
  }

  func matchesPartialItalic() -> Range<String.Index>? {
    guard let regex = PartialEmphasisRewriter.partialItalic else {
      return nil
    }
    let ranges = self.string.ranges(of: regex)
    guard ranges.count == 1, let range = ranges.first, range.upperBound == self.string.endIndex else {
      return nil
    }
    return range
  }
}

extension InlineContainer {

  var hasChildren: Bool {
    self.childCount > 0
  }

  var firstChild: Markup? {
    child(at: 0)
  }

  var lastChild: Markup? {
    child(at: childCount - 1)
  }

  var lastChildRange: Range<Int> {
    (self.childCount - 1)..<self.childCount
  }
}
