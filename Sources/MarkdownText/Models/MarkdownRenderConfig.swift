//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftUI

/// Aggregate styling and behavior configuration applied to a `MarkdownView`.
///
/// `MarkdownRenderConfig` bundles fonts, colors, citation behavior, and the
/// optional context-menu definition into a single value passed to the view.
/// Use `MarkdownRenderConfig.default` or the `with…` builders on the type for
/// incremental overrides.
public struct MarkdownRenderConfig: Hashable, Sendable {
  /// When `true`, newly appended text fades in instead of appearing instantly.
  public let shouldAnimateText: Bool
  /// Styling applied to block-quote content.
  public let blockQuoteStyle: MarkdownTextStyle
  /// Per-level heading styling.
  public let headingStyle: MarkdownHeadingTextStyle
  /// Styling applied to ordered list items.
  public let orderedListStyle: MarkdownTextStyle
  /// Styling applied to paragraph text.
  public let paragraphStyle: MarkdownTextStyle
  /// Styling applied to tables.
  public let tableStyle: MarkdownTableTextStyle
  /// Styling applied to inline runs such as bold, links, and inline code.
  public let inlineStyle: MarkdownInlineTextStyle
  /// Optional context-menu provider invoked on text selection. `nil` disables
  /// the custom menu and falls back to the system menu.
  public let textContextMenu: TextContextMenu?
  /// Configuration that controls inline citation parsing and rendering.
  public let citationConfig: CitationConfig
  /// Configuration that controls code-block syntax-highlighting styling.
  public let codeBlockConfig: CodeBlockConfig
  /// Vertical spacing between adjacent blocks (paragraphs, headings,
  /// code blocks, lists, etc.). Defaults to 30.
  public let blockSpacing: CGFloat
  /// Configuration for the built-in "Select more text" edit-menu action and the
  /// modal it presents. Enabled by default.
  public let textSelectionConfig: TextSelectionConfig
  /// Color of the horizontal rule rendered for a thematic break (`---`).
  public let thematicBreakColor: Color

  /// Configuration controlling whether and how Markdown images are rendered as
  /// block-level content.
  ///
  /// When enabled, image-only paragraphs are rendered as block images (loaded
  /// asynchronously). Pair with `MarkdownParseOption.imageSupport` so that
  /// images embedded alongside text are split out into their own blocks.
  ///
  /// - Important: Image support is **experimental**. The behavior, API, and
  ///   rendering output may change in future releases. Defaults to `.disabled`.
  public let imageConfig: ImageConfig

  /// Font and color style for a uniformly-styled run of markdown text.
  public struct MarkdownTextStyle: Hashable, Sendable {
    /// Font set used for normal, bold, and italic variants.
    public let textFonts: TextFonts
    /// Foreground color applied to the text.
    public let textColor: Color

    /// Create a text style with the given fonts and foreground color.
    public init(textFonts: TextFonts, textColor: Color) {
      self.textFonts = textFonts
      self.textColor = textColor
    }
  }

  /// Styling applied to markdown tables, covering both header and body cells
  /// plus chrome such as borders and the "view full table" action button.
  public struct MarkdownTableTextStyle: Hashable, Sendable {
    /// Font set used in both header and body cells.
    public let textFonts: TextFonts
    /// Foreground color applied to header cell text.
    public let headerTextColor: Color
    /// Foreground color applied to body cell text.
    public let regularTextColor: Color
    /// Background color of the header row.
    public let headerBackgroundColor: Color
    /// Color used for table borders and dividers.
    public let borderColor: Color
    /// Tint color of the action button shown in the table footer.
    public let actionButtonColor: Color

    /// Create a table style with the supplied fonts and color palette.
    public init(textFonts: TextFonts, headerTextColor: Color, regularTextColor: Color, headerBackgroundColor: Color, borderColor: Color, actionButtonColor: Color) {
      self.textFonts = textFonts
      self.headerTextColor = headerTextColor
      self.regularTextColor = regularTextColor
      self.headerBackgroundColor = headerBackgroundColor
      self.borderColor = borderColor
      self.actionButtonColor = actionButtonColor
    }
  }

  /// Per-level fonts and shared foreground color for markdown headings.
  public struct MarkdownHeadingTextStyle: Hashable, Sendable {
    /// Font set for level-1 headings.
    public let h1Font: TextFonts
    /// Font set for level-2 headings.
    public let h2Font: TextFonts
    /// Font set for level-3 headings.
    public let h3Font: TextFonts
    /// Font set for level-4 headings.
    public let h4Font: TextFonts
    /// Font set for level-5 headings.
    public let h5Font: TextFonts
    /// Font set for level-6 headings.
    public let h6Font: TextFonts
    /// Foreground color shared by every heading level.
    public let textColor: Color

    /// Create a heading style with explicit fonts per level and a shared color.
    public init(h1Font: TextFonts, h2Font: TextFonts, h3Font: TextFonts, h4Font: TextFonts, h5Font: TextFonts, h6Font: TextFonts, textColor: Color) {
      self.h1Font = h1Font
      self.h2Font = h2Font
      self.h3Font = h3Font
      self.h4Font = h4Font
      self.h5Font = h5Font
      self.h6Font = h6Font
      self.textColor = textColor
    }
  }

  /// Styling for inline runs: bold emphasis, links, and inline code spans.
  public struct MarkdownInlineTextStyle: Hashable, Sendable {
    /// Foreground color applied to bold-emphasis runs.
    public let boldTextColor: Color
    /// Font used for link runs.
    public let linkTextFont: MDFont
    /// Foreground color applied to link runs.
    public let linkTextColor: Color
    /// Font used for inline code spans.
    public let codeTextFont: MDFont
    /// Foreground color applied to inline code spans.
    public let codeTextColor: Color
    /// Background fill behind inline code spans.
    public let codeBackgroundColor: Color
    /// Underline color drawn beneath inline code spans.
    public let codeUnderlineColor: Color

    /// Create an inline text style with the supplied fonts and color palette.
    public init(boldTextColor: Color, linkTextFont: MDFont, linkTextColor: Color, codeTextFont: MDFont, codeTextColor: Color, codeBackgroundColor: Color, codeUnderlineColor: Color) {
      self.boldTextColor = boldTextColor
      self.linkTextFont = linkTextFont
      self.linkTextColor = linkTextColor
      self.codeTextFont = codeTextFont
      self.codeTextColor = codeTextColor
      self.codeBackgroundColor = codeBackgroundColor
      self.codeUnderlineColor = codeUnderlineColor
    }
  }

  /// Controls whether inline citations are parsed and how they are rendered.
  public struct CitationConfig: Hashable, Sendable {
    /// When `false`, citation markers are left as plain text.
    public let isEnabled: Bool
    /// Encoder/decoder used to embed citation payloads into the markdown.
    public let coder: CitationCoder
    /// Font applied to the rendered citation chip.
    public let font: MDFont
    /// Foreground color of the citation chip text.
    public let textColor: Color
    /// Background fill of the citation chip.
    public let backgroundColor: Color

    /// Create a citation configuration.
    /// - Parameters:
    ///   - isEnabled: See `isEnabled`. Defaults to `true`.
    ///   - coder: See `coder`. Defaults to `CitationCoder.default`.
    ///   - font: See `font`.
    ///   - textColor: See `textColor`.
    ///   - backgroundColor: See `backgroundColor`.
    public init(
      isEnabled: Bool = true,
      coder: CitationCoder = .default,
      font: MDFont,
      textColor: Color,
      backgroundColor: Color
    ) {
      self.isEnabled = isEnabled
      self.coder = coder
      self.font = font
      self.textColor = textColor
      self.backgroundColor = backgroundColor
    }

    /// Default citation styling derived from the bundled `Typography` and `Color.Theme` palette.
    public static let `default` = CitationConfig(
      font: Typography.tripleExtraSmallCustom450.mdFont,
      textColor: Color.Theme.Foreground.Primary.Primary750,
      backgroundColor: Color.Theme.Overlay.Black.Black5
    )
  }

  /// Default inter-block spacing.
  public static let defaultBlockSpacing: CGFloat = 30
  /// Default color for `thematicBreakColor`.
  public static let defaultThematicBreakColor: Color = Color.Theme.Stroke.Default.Default300
  /// Default styling for `blockQuoteStyle`.
  public static let defaultBlockQuoteStyle = MarkdownTextStyle(
    textFonts: Typography.baseTextFonts,
    textColor: Color.Theme.Foreground.Primary.Primary750
  )

  /// Default styling for `headingStyle`.
  public static let defaultHeadingStyle = MarkdownHeadingTextStyle(
    h1Font: Typography.extraLargeTextFonts,
    h2Font: Typography.largeTextFonts,
    h3Font: Typography.mediumTextFonts,
    h4Font: Typography.mediumTextFonts,
    h5Font: Typography.mediumTextFonts,
    h6Font: Typography.mediumTextFonts,
    textColor: Color.Theme.Foreground.Primary.Primary750
  )

  /// Default styling for `orderedListStyle`.
  public static let defaultOrderedListStyle = MarkdownTextStyle(
    textFonts: Typography.baseTextFonts,
    textColor: Color.Theme.Foreground.Primary.Primary450
  )

  /// Default styling for `paragraphStyle`.
  public static let defaultParagraphStyle = MarkdownTextStyle(
    textFonts: Typography.baseTextFonts,
    textColor: Color.Theme.Foreground.Primary.Primary750
  )

  /// Default styling for `tableStyle`.
  public static let defaultTableStyle = MarkdownTableTextStyle(
    textFonts: Typography.smallTextFonts,
    headerTextColor: Color.Theme.Foreground.Primary.Primary750,
    regularTextColor: Color.Theme.Foreground.Primary.Primary800,
    headerBackgroundColor: Color.Theme.Component.Table.Background.Header,
    borderColor: Color.Theme.Stroke.Default.Default250,
    actionButtonColor: Color.Theme.Component.Button.Foreground.Rest
  )

  /// Default styling for `inlineStyle`.
  public static let defaultInlineStyle = MarkdownInlineTextStyle(
    boldTextColor: Color.Theme.Foreground.Primary.Primary750,
    linkTextFont: Typography.baseTextFonts.normal,
    linkTextColor: Color.Theme.Accent.Accent600,
    codeTextFont: Typography.codeTextFonts.normal,
    codeTextColor: Color.Theme.Foreground.Primary.Primary750,
    codeBackgroundColor: Color.Theme.Component.Table.Background.Header,
    codeUnderlineColor: Color.Theme.Component.CodeBlock.Foreground.Header
  )

  /// Create a render config. Every parameter has a sensible default that
  /// matches the bundled `Typography`/`Color.Theme` palette, so callers can
  /// override only the fields they care about.
  public init(
    shouldAnimateText: Bool = false,
    blockQuoteStyle: MarkdownTextStyle = MarkdownRenderConfig.defaultBlockQuoteStyle,
    headingStyle: MarkdownHeadingTextStyle = MarkdownRenderConfig.defaultHeadingStyle,
    orderedListStyle: MarkdownTextStyle = MarkdownRenderConfig.defaultOrderedListStyle,
    paragraphStyle: MarkdownTextStyle = MarkdownRenderConfig.defaultParagraphStyle,
    tableStyle: MarkdownTableTextStyle = MarkdownRenderConfig.defaultTableStyle,
    inlineStyle: MarkdownInlineTextStyle = MarkdownRenderConfig.defaultInlineStyle,
    textContextMenu: TextContextMenu? = nil,
    citationConfig: CitationConfig = .default,
    codeBlockConfig: CodeBlockConfig = .default,
    blockSpacing: CGFloat = MarkdownRenderConfig.defaultBlockSpacing,
    textSelectionConfig: TextSelectionConfig = .default,
    thematicBreakColor: Color = MarkdownRenderConfig.defaultThematicBreakColor,
    imageConfig: ImageConfig = .disabled
  ) {
    self.shouldAnimateText = shouldAnimateText
    self.blockQuoteStyle = blockQuoteStyle
    self.headingStyle = headingStyle
    self.orderedListStyle = orderedListStyle
    self.paragraphStyle = paragraphStyle
    self.tableStyle = tableStyle
    self.inlineStyle = inlineStyle
    self.textContextMenu = textContextMenu
    self.citationConfig = citationConfig
    self.codeBlockConfig = codeBlockConfig
    self.blockSpacing = blockSpacing
    self.textSelectionConfig = textSelectionConfig
    self.thematicBreakColor = thematicBreakColor
    self.imageConfig = imageConfig
  }

  /// The default render config, equivalent to calling `init()` with no
  /// arguments.
  public static let `default` = MarkdownRenderConfig(shouldAnimateText: false)

  /// The context menu actually rendered on text selection: the consumer-supplied
  /// `textContextMenu` with the built-in "Select more text" group prepended (so
  /// it sits right after the system Copy group) when
  /// `textSelectionConfig.isEnabled` is `true`. Returns the raw `textContextMenu`
  /// unchanged when text selection is disabled.
  var resolvedTextContextMenu: TextContextMenu? {
    guard textSelectionConfig.isEnabled else { return textContextMenu }
    let selectMoreGroup = TextContextMenuGroup(
      title: nil,
      image: nil,
      displayInline: true,
      items: [
        TextContextMenuItem(
          id: TextSelectionConfig.selectMoreItemID,
          title: String.selectMoreTextLabel
        )
      ]
    )
    return TextContextMenu(menuGroups: [selectMoreGroup] + (textContextMenu?.menuGroups ?? []))
  }
}
