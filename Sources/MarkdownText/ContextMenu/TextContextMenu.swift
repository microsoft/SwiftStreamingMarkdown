//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import UIKit

/// Configuration for the edit menu that appears on text selection.
public struct TextContextMenu: Hashable, Sendable {
  public let menuGroups: [TextContextMenuGroup]

  public init(menuGroups: [TextContextMenuGroup]) {
    self.menuGroups = menuGroups
  }

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

