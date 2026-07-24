//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI

/// Configuration for the built-in "Select more text" edit-menu action and the
/// modal it presents. The modal shows the full document as selectable text so
/// users can select and copy content across Markdown block boundaries.
public struct TextSelectionConfig: Hashable, Sendable {
  /// When `true`, the edit menu includes the "Select more text" action.
  /// Defaults to `true`.
  public let isEnabled: Bool

  /// Background color of the text selection modal. `nil` falls back to the
  /// bundled chat page background.
  public let backgroundColor: Color?

  /// Create a text selection configuration.
  /// - Parameters:
  ///   - isEnabled: See `isEnabled`. Defaults to `true`.
  ///   - backgroundColor: See `backgroundColor`. Defaults to `nil` (bundled
  ///     chat page background).
  public init(
    isEnabled: Bool = true,
    backgroundColor: Color? = nil
  ) {
    self.isEnabled = isEnabled
    self.backgroundColor = backgroundColor
  }

  /// The default text selection configuration, which uses the bundled chat
  /// page background.
  public static let `default` = TextSelectionConfig(
    backgroundColor: Color.Theme.Background.Page.Chat.Flat
  )

  /// Reserved identifier for the built-in "Select more text" menu item that is
  /// injected into `MarkdownRenderConfig.resolvedTextContextMenu`. The paragraph
  /// menu builders recognize this id and route its tap to
  /// `MarkdownController.requestTextSelection()` instead of the consumer's
  /// `onContextMenuTap`.
  static let selectMoreItemID = "com.microsoft.SwiftStreamingMarkdown.textSelection.selectMore"
}
