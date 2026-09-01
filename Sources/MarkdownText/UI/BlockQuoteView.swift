//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftUI

struct BlockQuoteView: View {
  let item: BlockQuoteType

  init(item: BlockQuoteRenderable) {
    self.item = item.quoteType
  }

  var body: some View {
    if let kind = item.alertKind {
      AlertBlockQuoteView(kind: kind) {
        InternalBlockQuoteView(item: item, isForAlertQuote: true)
      }
    } else {
      InternalBlockQuoteView(item: item)
    }
  }
}

private struct InternalBlockQuoteView: View {
  let item: BlockQuoteType
	let isForAlertQuote: Bool = false

  var body: some View {
    HStack(spacing: 8.0) {

      if item.isNested && !isForAlertQuote {
        QuoteDivider()
          .frame(width: 3.0)
      }

      VStack(spacing: 12.0) {
        switch item {
        case .text(let text, _):
          HStack {
            QuoteTextView(text: text)

            Spacer()
          }
          .fixedSize(horizontal: false, vertical: true)
        case .nested(let subItems, _):
          ForEach(subItems.indices, id: \.self) { index in
            InternalBlockQuoteView(item: subItems[index])
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
      .foregroundStyle(config.blockQuoteStyle.textColor)
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

private struct AlertBlockQuoteView<Content: View>: View {
  @Environment(\.markdownConfig) var config: MarkdownRenderConfig

  let kind: BlockQuoteAlertKind
  let content: Content

  init(kind: BlockQuoteAlertKind, @ViewBuilder content: () -> Content) {
    self.kind = kind
    self.content = content()
  }

  var body: some View {
    let style = config.blockQuoteAlertStyle[kind] ?? .default

    HStack(spacing: 0) {
      RoundedRectangle(cornerRadius: 4.0, style: .continuous)
        .foregroundStyle(style.accentColor)
        .frame(width: 4.0)
			Image(systemName: style.imageName)
				.foregroundStyle(style.accentColor)
				.padding(.leading, 8.0)

      content
        .padding(.leading, 12.0)
    }
    .padding(8.0)
    .background(style.backgroundColor, in: RoundedRectangle(cornerRadius: 8.0, style: .continuous))
  }
}

indirect enum BlockQuoteType: Equatable, Hashable {
  case text(String, BlockQuoteAlertKind?)
  case nested([BlockQuoteType], BlockQuoteAlertKind?)

  var isNested: Bool {
    switch self {
    case .text:
      false
    case .nested:
      true
    }
  }

  var alertKind: BlockQuoteAlertKind? {
    switch self {
    case .text(_, let kind):
      return kind
    case .nested(_, let kind):
      return kind
    }
  }
}

public enum BlockQuoteAlertKind: String, Equatable, Hashable, Sendable, CaseIterable {
  case note
  case tip
  case important
  case warning
  case caution
}
