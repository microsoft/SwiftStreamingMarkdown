//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI

struct OrderedListView: View {

  let items: [MarkdownListItem]
  @Environment(\.markdownConfig) var config: MarkdownRenderConfig

  var body: some View {
    VStack(alignment: .leading, spacing: 8, content: {
      ForEach(0..<items.count, id: \.self) { idx in
        HStack(alignment: .centerOfFirstLine, spacing: 11) {
          Text(verbatim: "\(idx+1).")
            .font(config.orderedListStyle.textFonts, bold: true)
            .foregroundStyle(Color(config.orderedListStyle.textColor))
            .transition(.opacity)
          if let firstChild = items[idx].children.first {
            if case .paragraph(_, let contents) = firstChild {
              // Wrap the SingleBlockView to provide proper baseline alignment. This is to fix the mis-alignment when the view is rendered off-screen, e.g. snapshot.
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
}

// Wrapper to provide proper baseline alignment for UIViewRepresentable content
struct ListItemContentWrapper<Content: View>: View {
  let paragraphContents: NSMutableAttributedString
  let content: () -> Content

  init(paragraphContents: NSMutableAttributedString, @ViewBuilder content: @escaping () -> Content) {
    self.paragraphContents = paragraphContents
    self.content = content
  }

  var body: some View {
    content()
      .alignmentGuide(.centerOfFirstLine) { _ in
        let font = extractFirstFont()
        return font.lineHeight / 2.0
      }
  }

  private func extractFirstFont() -> UIFont {
    // First check if the first character is a citation attachment
    if hasFirstCharacterCitationAttachment(in: paragraphContents) {
      return InlineCitationConstants.attachmentCitationUIFont
    }
    // Otherwise, look for regular font attributes
    if let font = firstUIFont(in: paragraphContents) {
      return font
    }
    return Typography.base.uiFont
  }

  private func hasFirstCharacterCitationAttachment(in attributedString: NSAttributedString) -> Bool {
    guard attributedString.length > 0 else { return false }

    // Check if the first character is a citation attachment
    return attributedString.attribute(.attachment, at: 0, effectiveRange: nil) is InlineCitationAttachment
  }

  private func firstUIFont(in attributedString: NSAttributedString) -> UIFont? {
    guard attributedString.length > 0 else { return nil }

    // Fast path: attribute at location 0
    if let font = attributedString.attribute(.font, at: 0, effectiveRange: nil) as? UIFont {
      return font
    }

    var found: UIFont?
    attributedString.enumerateAttribute(.font, in: NSRange(location: 0, length: attributedString.length)) { value, _, stop in
      if let font = value as? UIFont {
        found = font
        stop.pointee = true
      }
    }
    return found
  }
}

func markdownListAccessibilityLabel(for item: String, at index: Int, length: Int) -> String {
  "\(String.markdownList(length: String(length))), item \(index + 1): \(item)"
}

#Preview(body: {
  let items: [MarkdownListItem] = (0..<40).map { i in
    MarkdownListItem(children: [.paragraph(id: "\(i)", content: NSMutableAttributedString(string: "item \(i + 1)"))], startsWithBold: false)
  }
  return ScrollView {
    OrderedListView(items: items)
  }
})
