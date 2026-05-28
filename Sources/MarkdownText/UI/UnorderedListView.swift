//
//  Copyright © 2025 Microsoft. All rights reserved.
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
              .accessibilityLabel(Text(markdownListAccessibilityLabel(for: contents.string, at: idx, length: items.count)))
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
  }

  func bulletView(forListItem listItem: MarkdownListItem) -> some View {
    ZStack(alignment: .trailing) {
      if nestedLevel % 2 == 0 {
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
                     startsWithBold: false)
  ],
  nestedLevel: 0).padding()
})
