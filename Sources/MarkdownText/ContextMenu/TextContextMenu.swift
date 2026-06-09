//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import UIKit

/// Configuration for the edit menu that appears on text selection.
public struct TextContextMenu: Hashable, Sendable {
  /// Ordered groups that compose the custom portion of the menu.
  public let menuGroups: [TextContextMenuGroup]

  /// Create a menu definition from the supplied groups.
  public init(menuGroups: [TextContextMenuGroup]) {
    self.menuGroups = menuGroups
  }

  /// Build the `UIMenu` to present on text selection by merging the standard
  /// system edit actions with the configured custom groups. Used by
  /// `MarkdownViewController` and is rarely called directly by consumers.
  /// - Parameters:
  ///   - textView: The `UITextView` requesting the menu.
  ///   - selectedRange: Current selection range, clamped to the text length.
  ///   - suggestedActions: System-suggested actions from UIKit.
  ///   - markdownController: Optional controller used to forward item taps.
  /// - Returns: The composed `UIMenu` to display.
  public func buildUIMenu(textView: UITextView, selectedRange: NSRange, suggestedActions: [UIMenuElement], markdownController: MarkdownController?) -> UIMenu {
    var customMenu: [UIMenu] = []

    let clampedRange = NSIntersectionRange(selectedRange, NSRange(location: 0, length: textView.attributedText.length))
    let selectedText = textView.attributedText.attributedSubstring(from: clampedRange).string
    for group in menuGroups {
      var groupActions: [UIAction] = []
      for item in group.items {
        let uiAction = UIAction(
          title: item.title,
          subtitle: item.subtitle,
          image: item.image?.withRenderingMode(.alwaysTemplate),
        ) { _ in
          markdownController?.onContextMenuTap(id: item.id, selectedContent: selectedText)
        }
        groupActions.append(uiAction)
      }
      let submenu = UIMenu(
        title: group.title ?? "",
        image: group.image?.withRenderingMode(.alwaysTemplate),
        options: group.displayInline ? .displayInline : [],
        children: groupActions
      )
      customMenu.append(submenu)
    }

    // Combine: system suggested actions first, then custom actions
    let filteredSuggestedActions = suggestedActions.filter { menuItem in
      if let menuItem = menuItem as? UIMenu {
        return menuItem.identifier == .standardEdit
      }
      return false
    }
    return UIMenu(children: filteredSuggestedActions + customMenu)
  }
}
