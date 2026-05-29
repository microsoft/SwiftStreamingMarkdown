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
    public let textFonts: TextFonts
    public let textColor: UIColor

    public init(textFonts: TextFonts, textColor: UIColor) {
      self.textFonts = textFonts
      self.textColor = textColor
    }
  }

  public struct MarkdownTableTextStyle: Hashable, Sendable {
    public let textFonts: TextFonts
    public let headerTextColor: UIColor
    public let regularTextColor: UIColor
    public let headerBackgroundColor: UIColor
    public let borderColor: UIColor
    public let actionButtonColor: UIColor

    public init(textFonts: TextFonts, headerTextColor: UIColor, regularTextColor: UIColor, headerBackgroundColor: UIColor, borderColor: UIColor, actionButtonColor: UIColor) {
      self.textFonts = textFonts
      self.headerTextColor = headerTextColor
      self.regularTextColor = regularTextColor
      self.headerBackgroundColor = headerBackgroundColor
      self.borderColor = borderColor
      self.actionButtonColor = actionButtonColor
    }
  }

  public struct MarkdownHeadingTextStyle: Hashable, Sendable {
    public let h1Font: TextFonts
    public let h2Font: TextFonts
    public let h3Font: TextFonts
    public let h4Font: TextFonts
    public let h5Font: TextFonts
    public let h6Font: TextFonts
    public let textColor: UIColor

    public init(h1Font: TextFonts, h2Font: TextFonts, h3Font: TextFonts, h4Font: TextFonts, h5Font: TextFonts, h6Font: TextFonts, textColor: UIColor) {
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
    public let boldTextColor: UIColor
    public let linkTextFont: Typography
    public let linkTextColor: UIColor
    public let codeTextFont: Typography
    public let codeTextColor: UIColor
    public let codeBackgroundColor: UIColor
    public let codeUnderlineColor: UIColor

    public init(boldTextColor: UIColor, linkTextFont: Typography, linkTextColor: UIColor, codeTextFont: Typography, codeTextColor: UIColor, codeBackgroundColor: UIColor, codeUnderlineColor: UIColor) {
      self.boldTextColor = boldTextColor
      self.linkTextFont = linkTextFont
      self.linkTextColor = linkTextColor
      self.codeTextFont = codeTextFont
      self.codeTextColor = codeTextColor
      self.codeBackgroundColor = codeBackgroundColor
      self.codeUnderlineColor = codeUnderlineColor
    }
  }

  public init(
    shouldAnimateText: Bool = false,
    blockQuoteStyle: MarkdownTextStyle = .init(
      textFonts: Typography.baseTextFonts,
      textColor: UIColor(Color.Theme.Foreground.Primary.Primary750)
    ),
    headingStyle: MarkdownHeadingTextStyle = .init(
      h1Font: Typography.extraLargeTextFonts,
      h2Font: Typography.largeTextFonts,
      h3Font: Typography.mediumTextFonts,
      h4Font: Typography.mediumTextFonts,
      h5Font: Typography.mediumTextFonts,
      h6Font: Typography.mediumTextFonts,
      textColor: UIColor(Color.Theme.Foreground.Primary.Primary750)
    ),
    orderedListStyle: MarkdownTextStyle = .init(
      textFonts: Typography.baseTextFonts,
      textColor: UIColor(Color.Theme.Foreground.Primary.Primary450)
    ),
    paragraphStyle: MarkdownTextStyle = .init(
      textFonts: Typography.baseTextFonts,
      textColor: UIColor(Color.Theme.Foreground.Primary.Primary750)
    ),
    tableStyle: MarkdownTableTextStyle = .init(
      textFonts: Typography.smallTextFonts,
      headerTextColor: UIColor(Color.Theme.Foreground.Primary.Primary750),
      regularTextColor: UIColor(Color.Theme.Foreground.Primary.Primary800),
      headerBackgroundColor: UIColor(Color.Theme.Component.Table.Background.Header),
      borderColor: UIColor(Color.Theme.Stroke.Default.Default250),
      actionButtonColor: UIColor(Color.Theme.Component.Button.Foreground.Rest)
    ),
    inlineStyle: MarkdownInlineTextStyle = .init(
      boldTextColor: UIColor(Color.Theme.Foreground.Primary.Primary750),
      linkTextFont: .base,
      linkTextColor: UIColor(Color.Theme.Accent.Accent600),
      codeTextFont: .code,
      codeTextColor: UIColor(Color.Theme.Foreground.Primary.Primary750),
      codeBackgroundColor: UIColor(Color.Theme.Component.Table.Background.Header),
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
