//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftUI

struct UnorderedListView: View {

  let items: [MarkdownListItem]
  let nestedLevel: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 8, content: {
      ForEach(0..<items.count, id: \.self) { idx in
        HStack(alignment: .centerOfFirstLine, spacing: 1) {
          bulletView(forListItem: items[idx])
          if let firstChild = items[idx].children.first {
            if case .paragraph(_, let contents) = firstChild {
              // Wrap the SingleBlockView to provide proper baseline alignment
              ListItemContentWrapper(paragraphContents: contents) {
                SingleBlockView(renderable: firstChild)
              }
              .accessibilityLabel(Text(listItemAccessibilityLabel(for: contents.string, at: idx, checkbox: items[idx].checkbox)))
            } else {
              SingleBlockView(renderable: firstChild)
            }
          }
          Spacer()
        }
        if items[idx].children.count > 1 {
          BlockView(renderables: Array(items[idx].children.dropFirst()))
            .padding([.leading], 0)
        }
      }
    })
    .padding([.leading], CGFloat(nestedLevel) * 8)
  }

  func bulletView(forListItem listItem: MarkdownListItem) -> some View {
    ZStack(alignment: .trailing) {
      if let checkbox = listItem.checkbox {
        Image(systemName: checkbox == .checked ? "checkmark.square.fill" : "square")
          .resizable()
          .frame(width: 12, height: 12)
          .foregroundStyle( Color.Theme.Foreground.Primary.Primary450)
          .transition(.opacity)
      } else if nestedLevel % 2 == 0 {
        Image(systemName: "circle.fill")
          .resizable()
          .frame(width: 4, height: 4)
          .foregroundStyle( Color.Theme.Foreground.Primary.Primary450)
          .transition(.opacity)
      } else {
        Image(systemName: "circle")
          .resizable()
          .frame(width: 4, height: 4)
          .foregroundStyle( Color.Theme.Foreground.Primary.Primary450)
          .transition(.opacity)
      }
    }.frame(width: 22.0)
  }

  private func listItemAccessibilityLabel(for content: String, at index: Int, checkbox: MarkdownListItem.Checkbox?) -> String {
    let label = markdownListAccessibilityLabel(for: content, at: index, length: items.count)
    switch checkbox {
    case .checked: return "\(label), \(String.taskListItemChecked)"
    case .unchecked: return "\(label), \(String.taskListItemUnchecked)"
    case .none: return label
    }
  }
}

extension VerticalAlignment {
  private enum CenterOfFirstLine: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
      let heightAfterFirstLine = context[.lastTextBaseline] - context[.firstTextBaseline]
      let heightOfFirstLine = context.height - heightAfterFirstLine
      return heightOfFirstLine / 2
    }
  }
  static let centerOfFirstLine = Self(CenterOfFirstLine.self)
}

#Preview(body: {
  return UnorderedListView(items: [
    MarkdownListItem(children: [.paragraph(id: "1-1",
                                           content: NSMutableAttributedString(string: "item 1"))],
                     startsWithBold: false),
    MarkdownListItem(children: [.paragraph(id: "1-2",
                                           content: NSMutableAttributedString(string: "item 2"))],
                     startsWithBold: false),
    MarkdownListItem(children: [.paragraph(id: "1-3",
                                           content: NSMutableAttributedString(string: "item 3, this is a very long item with a lot of texts. it may create a multi-line paragraph."))],
                     startsWithBold: false),
    MarkdownListItem(children: [.paragraph(id: "1-4",
                                           content: NSMutableAttributedString(string: "a completed task"))],
                     startsWithBold: false,
                     checkbox: .checked),
    MarkdownListItem(children: [.paragraph(id: "1-5",
                                           content: NSMutableAttributedString(string: "an open task"))],
                     startsWithBold: false,
                     checkbox: .unchecked)
  ],
  nestedLevel: 0).padding()
})
