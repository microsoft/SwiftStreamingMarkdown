//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

public struct MarkdownRenderConfig: Hashable, Sendable {
  public let shouldAnimateText: Bool
  public let blockQuoteStyle: MarkdownTextStyle
  public let headingStyle: MarkdownHeadingTextStyle
  public let orderedListStyle: MarkdownTextStyle
  public let paragraphStyle: MarkdownTextStyle
  public let tableStyle: MarkdownTableTextStyle
  public let inlineStyle: MarkdownInlineTextStyle
  public let textContextMenu: TextContextMenu?

  public struct MarkdownTextStyle: Hashable, Sendable {
    public let textFont: Typography
    public let boldTextFont: Typography
    public let textColor: UIColor

    public init(textFont: Typography, boldTextFont: Typography, textColor: UIColor) {
      self.textFont = textFont
      self.boldTextFont = boldTextFont
      self.textColor = textColor
    }
  }

  public struct MarkdownTableTextStyle: Hashable, Sendable {
    public let textFont: Typography
    public let boldTextFont: Typography
    public let headerTextColor: UIColor
    public let regularTextColor: UIColor

    public init(textFont: Typography, boldTextFont: Typography, headerTextColor: UIColor, regularTextColor: UIColor) {
      self.textFont = textFont
      self.boldTextFont = boldTextFont
      self.headerTextColor = headerTextColor
      self.regularTextColor = regularTextColor
    }
  }

  public struct MarkdownHeadingTextStyle: Hashable, Sendable {
    public let h1Font: Typography
    public let h2Font: Typography
    public let h3Font: Typography
    public let h4Font: Typography
    public let h5Font: Typography
    public let h6Font: Typography
    public let textColor: UIColor

    public init(h1Font: Typography, h2Font: Typography, h3Font: Typography, h4Font: Typography, h5Font: Typography, h6Font: Typography, textColor: UIColor) {
      self.h1Font = h1Font
      self.h2Font = h2Font
      self.h3Font = h3Font
      self.h4Font = h4Font
      self.h5Font = h5Font
      self.h6Font = h6Font
      self.textColor = textColor
    }
  }

  public struct MarkdownInlineTextStyle: Hashable, Sendable {
    public let emphasisTextFont: Typography
    public let boldTextFont: Typography
    public let boldTextColor: UIColor
    public let linkTextFont: Typography
    public let linkTextColor: UIColor
    public let codeTextFont: Typography
    public let codeTextColor: UIColor
    public let codeBackgroundColor: UIColor
    public let actionLinkUnderlineColor: UIColor
    public let codeUnderlineColor: UIColor

    public init(emphasisTextFont: Typography, boldTextFont: Typography, boldTextColor: UIColor, linkTextFont: Typography, linkTextColor: UIColor, codeTextFont: Typography, codeTextColor: UIColor, codeBackgroundColor: UIColor, actionLinkUnderlineColor: UIColor, codeUnderlineColor: UIColor) {
      self.emphasisTextFont = emphasisTextFont
      self.boldTextFont = boldTextFont
      self.boldTextColor = boldTextColor
      self.linkTextFont = linkTextFont
      self.linkTextColor = linkTextColor
      self.codeTextFont = codeTextFont
      self.codeTextColor = codeTextColor
      self.codeBackgroundColor = codeBackgroundColor
      self.actionLinkUnderlineColor = actionLinkUnderlineColor
      self.codeUnderlineColor = codeUnderlineColor
    }
  }

  public init(
    shouldAnimateText: Bool = false,
    blockQuoteStyle: MarkdownTextStyle = .init(
      textFont: Typography.base,
      boldTextFont: Typography.baseStrong,
      textColor: UIColor(Color.Theme.Foreground.Primary.Primary750)
    ),
    headingStyle: MarkdownHeadingTextStyle = .init(
      h1Font: .extraLarge,
      h2Font: .large,
      h3Font: .medium,
      h4Font: .medium,
      h5Font: .medium,
      h6Font: .medium,
      textColor: UIColor(Color.Theme.Foreground.Primary.Primary750)
    ),
    orderedListStyle: MarkdownTextStyle = .init(
      textFont: .base,
      boldTextFont: .baseStrong,
      textColor: UIColor(Color.Theme.Foreground.Primary.Primary450)
    ),
    paragraphStyle: MarkdownTextStyle = .init(
      textFont: .base,
      boldTextFont: .baseStrong,
      textColor: UIColor(Color.Theme.Foreground.Primary.Primary750)
    ),
    tableStyle: MarkdownTableTextStyle = .init(
      textFont: .small,
      boldTextFont: .smallStrong,
      headerTextColor: UIColor(Color.Theme.Foreground.Primary.Primary750),
      regularTextColor: UIColor(Color.Theme.Foreground.Primary.Primary800)
    ),
    inlineStyle: MarkdownInlineTextStyle = .init(
      emphasisTextFont: .baseItalic,
      boldTextFont: .baseStrong,
      boldTextColor: UIColor(Color.Theme.Foreground.Primary.Primary750),
      linkTextFont: .base,
      linkTextColor: UIColor(Color.Theme.Accent.Accent600),
      codeTextFont: .code,
      codeTextColor: UIColor(Color.Theme.Foreground.Primary.Primary750),
      codeBackgroundColor: UIColor(Color.Theme.Component.Table.Background.Header),
      actionLinkUnderlineColor: UIColor(Color.Theme.Foreground.Primary.Primary650),
      codeUnderlineColor: UIColor(Color.Theme.Component.CodeBlock.Foreground.Header)
    ),
    textContextMenu: TextContextMenu? = nil
  ) {
    self.shouldAnimateText = shouldAnimateText
    self.blockQuoteStyle = blockQuoteStyle
    self.headingStyle = headingStyle
    self.orderedListStyle = orderedListStyle
    self.paragraphStyle = paragraphStyle
    self.tableStyle = tableStyle
    self.inlineStyle = inlineStyle
    self.textContextMenu = textContextMenu
  }

  public static let `default` = MarkdownRenderConfig(shouldAnimateText: false)

  public static let chainOfThought = MarkdownRenderConfig(
    shouldAnimateText: true,
    blockQuoteStyle: .init(textFont: .extraSmall, boldTextFont: .extraSmallStrong, textColor: UIColor(Color.Theme.Foreground.Primary.Primary550)),
    headingStyle: .init(h1Font: .extraSmall, h2Font: .extraSmall, h3Font: .extraSmall, h4Font: .extraSmall, h5Font: .extraSmall, h6Font: .extraSmall, textColor: UIColor(Color.Theme.Foreground.Primary.Primary550)),
    orderedListStyle: .init(textFont: .extraSmall, boldTextFont: .extraSmallStrong, textColor: UIColor(Color.Theme.Foreground.Primary.Primary550)),
    paragraphStyle: .init(textFont: .extraSmall, boldTextFont: .extraSmallStrong, textColor: UIColor(Color.Theme.Foreground.Primary.Primary550)),
    tableStyle: .init(textFont: .extraSmall, boldTextFont: .extraSmallStrong, headerTextColor: UIColor(Color.Theme.Foreground.Primary.Primary550), regularTextColor: UIColor(Color.Theme.Foreground.Primary.Primary550)),
    inlineStyle: .init(emphasisTextFont: .extraSmall,
                       boldTextFont: .extraSmallStrong,
                       boldTextColor: UIColor(Color.Theme.Foreground.Primary.Primary550),
                       linkTextFont: .extraSmall,
                       linkTextColor: UIColor(Color.Theme.Foreground.Primary.Primary550),
                       codeTextFont: .code,
                       codeTextColor: UIColor(Color.Theme.Foreground.Primary.Primary550),
                       codeBackgroundColor: UIColor(Color.Theme.Component.Table.Background.Header),
                       actionLinkUnderlineColor: UIColor(Color.Theme.Foreground.Primary.Primary650),
                       codeUnderlineColor: UIColor(Color.Theme.Component.CodeBlock.Foreground.Header))
  )
}

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
