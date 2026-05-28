//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation

extension MarkdownRenderConfig {
  public func withShouldAnimateText(value: Bool) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: value,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu
    )
  }

  public func withBlockQuoteStyle(value: MarkdownTextStyle) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: value,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu
    )
  }

  public func withHeadingStyle(value: MarkdownHeadingTextStyle) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: value,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu
    )
  }

  public func withOrderedListStyle(value: MarkdownTextStyle) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: value,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu
    )
  }

  public func withParagraphStyle(value: MarkdownTextStyle) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: value,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu
    )
  }

  public func withTableStyle(value: MarkdownTableTextStyle) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: value,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu
    )
  }

  public func withInlineStyle(value: MarkdownInlineTextStyle) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: value,
      textContextMenu: textContextMenu
    )
  }

  public func withTextContextMenu(value: TextContextMenu?) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: value
    )
  }
}
