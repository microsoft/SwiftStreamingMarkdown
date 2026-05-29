//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI

struct BlockQuoteView: View {
  let item: BlockQuoteType

  init(item: BlockQuoteRenderable) {
    self.item = item.quoteType
  }

  var body: some View {
    InternalBlockQuoteView(item: item)
  }
}

private struct InternalBlockQuoteView: View {
  let item: BlockQuoteType

  var body: some View {
    HStack(spacing: 8.0) {

      if item.isNested {
        QuoteDivider()
          .frame(width: 3.0)
      }

      VStack(spacing: 12.0) {
        switch item {
        case .text(let text):
          HStack {
            QuoteTextView(text: text)

            Spacer()
          }
          .fixedSize(horizontal: false, vertical: true)
        case .nested(let subItems):
          ForEach(subItems, id: \.self) { subItem in
            InternalBlockQuoteView(item: subItem)
              .fixedSize(horizontal: false, vertical: true)
          }
          .fixedSize(horizontal: false, vertical: true)
        }
      }
      .padding(.vertical, 4.0)
      .fixedSize(horizontal: false, vertical: true)
    }
    .fixedSize(horizontal: false, vertical: true)
  }
}

struct QuoteTextView: View {
  @Environment(\.markdownConfig) var config: MarkdownRenderConfig

  let text: String

  var body: some View {
    Text(text)
      .font(config.blockQuoteStyle.textFonts)
      .foregroundStyle(Color(config.blockQuoteStyle.textColor))
      .padding(.vertical, 4.0)
      .fixedSize(horizontal: false, vertical: true)
  }
}

struct QuoteDivider: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 8.0, style: .continuous)
      .foregroundStyle(Color.Theme.Stroke.Muted.Muted300)
  }
}

indirect enum BlockQuoteType: Equatable, Hashable {
  case text(String)
  case nested([BlockQuoteType])

  var isNested: Bool {
    switch self {
    case .text:
      false
    case .nested:
      true
    }
  }
}
