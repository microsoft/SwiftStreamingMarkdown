//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftUI

extension MarkdownRenderConfig {
  /// Returns a copy with `shouldAnimateText` replaced.
  public func withShouldAnimateText(value: Bool) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: value,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu,
      citationConfig: citationConfig,
      codeBlockConfig: codeBlockConfig,
      blockSpacing: blockSpacing,
      textSelectionConfig: textSelectionConfig,
      thematicBreakColor: thematicBreakColor
    )
  }

  /// Returns a copy with `blockQuoteStyle` replaced.
  public func withBlockQuoteStyle(value: MarkdownTextStyle) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: value,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu,
      citationConfig: citationConfig,
      codeBlockConfig: codeBlockConfig,
      blockSpacing: blockSpacing,
      textSelectionConfig: textSelectionConfig,
      thematicBreakColor: thematicBreakColor
    )
  }

  /// Returns a copy with `headingStyle` replaced.
  public func withHeadingStyle(value: MarkdownHeadingTextStyle) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: value,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu,
      citationConfig: citationConfig,
      codeBlockConfig: codeBlockConfig,
      blockSpacing: blockSpacing,
      textSelectionConfig: textSelectionConfig,
      thematicBreakColor: thematicBreakColor
    )
  }

  /// Returns a copy with `orderedListStyle` replaced.
  public func withOrderedListStyle(value: MarkdownTextStyle) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: value,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu,
      citationConfig: citationConfig,
      codeBlockConfig: codeBlockConfig,
      blockSpacing: blockSpacing,
      textSelectionConfig: textSelectionConfig,
      thematicBreakColor: thematicBreakColor
    )
  }

  /// Returns a copy with `paragraphStyle` replaced.
  public func withParagraphStyle(value: MarkdownTextStyle) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: value,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu,
      citationConfig: citationConfig,
      codeBlockConfig: codeBlockConfig,
      blockSpacing: blockSpacing,
      textSelectionConfig: textSelectionConfig,
      thematicBreakColor: thematicBreakColor
    )
  }

  /// Returns a copy with `tableStyle` replaced.
  public func withTableStyle(value: MarkdownTableTextStyle) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: value,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu,
      citationConfig: citationConfig,
      codeBlockConfig: codeBlockConfig,
      blockSpacing: blockSpacing,
      textSelectionConfig: textSelectionConfig,
      thematicBreakColor: thematicBreakColor
    )
  }

  /// Returns a copy with `inlineStyle` replaced.
  public func withInlineStyle(value: MarkdownInlineTextStyle) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: value,
      textContextMenu: textContextMenu,
      citationConfig: citationConfig,
      codeBlockConfig: codeBlockConfig,
      blockSpacing: blockSpacing,
      textSelectionConfig: textSelectionConfig,
      thematicBreakColor: thematicBreakColor
    )
  }

  /// Returns a copy with `textContextMenu` replaced. Pass `nil` to remove the
  /// custom context menu and fall back to the system menu.
  public func withTextContextMenu(value: TextContextMenu?) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: value,
      citationConfig: citationConfig,
      codeBlockConfig: codeBlockConfig,
      blockSpacing: blockSpacing,
      textSelectionConfig: textSelectionConfig,
      thematicBreakColor: thematicBreakColor
    )
  }

  /// Returns a copy with `blockSpacing` replaced.
  public func withBlockSpacing(value: CGFloat) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu,
      citationConfig: citationConfig,
      codeBlockConfig: codeBlockConfig,
      blockSpacing: value,
      textSelectionConfig: textSelectionConfig,
      thematicBreakColor: thematicBreakColor
    )
  }

  /// Returns a copy with `codeBlockConfig` replaced.
  public func withCodeBlockConfig(value: CodeBlockConfig) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu,
      citationConfig: citationConfig,
      codeBlockConfig: value,
      blockSpacing: blockSpacing,
      textSelectionConfig: textSelectionConfig,
      thematicBreakColor: thematicBreakColor
    )
  }

  /// Returns a copy with `textSelectionConfig` replaced. Pass a config with
  /// `isEnabled: false` to hide the built-in "Select more text" edit-menu action.
  public func withTextSelectionConfig(value: TextSelectionConfig) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu,
      citationConfig: citationConfig,
      codeBlockConfig: codeBlockConfig,
      blockSpacing: blockSpacing,
      textSelectionConfig: value,
      thematicBreakColor: thematicBreakColor
    )
  }

  /// Returns a copy with `thematicBreakColor` replaced.
  public func withThematicBreakColor(value: Color) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu,
      citationConfig: citationConfig,
      codeBlockConfig: codeBlockConfig,
      blockSpacing: blockSpacing,
      textSelectionConfig: textSelectionConfig,
      thematicBreakColor: value
    )
  }

  /// Returns a copy with `imageConfig` replaced. Image support is experimental.
  public func withImageConfig(_ value: ImageConfig) -> MarkdownRenderConfig {
    MarkdownRenderConfig(
      shouldAnimateText: shouldAnimateText,
      blockQuoteStyle: blockQuoteStyle,
      headingStyle: headingStyle,
      orderedListStyle: orderedListStyle,
      paragraphStyle: paragraphStyle,
      tableStyle: tableStyle,
      inlineStyle: inlineStyle,
      textContextMenu: textContextMenu,
      citationConfig: citationConfig,
      codeBlockConfig: codeBlockConfig,
      blockSpacing: blockSpacing,
      textSelectionConfig: textSelectionConfig,
      thematicBreakColor: thematicBreakColor,
      imageConfig: value
    )
  }
}
