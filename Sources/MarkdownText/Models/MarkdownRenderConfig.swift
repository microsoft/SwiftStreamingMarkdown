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
    public let headerBackgroundColor: UIColor
    public let borderColor: UIColor
    public let actionButtonColor: UIColor

    public init(textFont: Typography, boldTextFont: Typography, headerTextColor: UIColor, regularTextColor: UIColor, headerBackgroundColor: UIColor, borderColor: UIColor, actionButtonColor: UIColor) {
      self.textFont = textFont
      self.boldTextFont = boldTextFont
      self.headerTextColor = headerTextColor
      self.regularTextColor = regularTextColor
      self.headerBackgroundColor = headerBackgroundColor
      self.borderColor = borderColor
      self.actionButtonColor = actionButtonColor
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
      regularTextColor: UIColor(Color.Theme.Foreground.Primary.Primary800),
      headerBackgroundColor: UIColor(Color.Theme.Component.Table.Background.Header),
      borderColor: UIColor(Color.Theme.Stroke.Default.Default250),
      actionButtonColor: UIColor(Color.Theme.Component.Button.Foreground.Rest)
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
}
