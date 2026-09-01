//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import Markdown
import SwiftUI

extension BlockQuote: BlockConvertible {
  var quoteTypes: BlockQuoteType {
    var finalQuoteTypes = [BlockQuoteType]()
    var alertKind: BlockQuoteAlertKind?

    for child in children {
      if let inlineContainer = child as? InlineContainer {
        let text = inlineContainer.extractPlainText(removeHeading: false)
        if alertKind == nil, let (kind, rest) = Self.parseAlertTag(text) {
          alertKind = kind
          if !rest.isEmpty {
            finalQuoteTypes.append(.text(rest, alertKind))
          }
        } else {
          finalQuoteTypes.append(.text(text, alertKind))
        }
      } else if let blockQuoteContainer = child as? BlockQuote {
        finalQuoteTypes.append(blockQuoteContainer.quoteTypes)
      }
    }

    return .nested(finalQuoteTypes, alertKind)
  }

  /// Recognizes a leading GitHub-style `[!KIND]` alert marker, returning the
  /// parsed kind and the remaining text with the marker stripped.
  static func parseAlertTag(_ text: String) -> (kind: BlockQuoteAlertKind, rest: String)? {
    guard text.hasPrefix("[!"),
      let close = text.firstIndex(of: "]"),
      close > text.index(text.startIndex, offsetBy: 2),
      let kind = BlockQuoteAlertKind(rawValue: String(text[text.index(text.startIndex, offsetBy: 2)..<close]).lowercased())
    else {
      return nil
    }

    var rest = String(text[text.index(after: close)...])
    if rest.hasPrefix(" ") {
      rest.removeFirst()
    }
    return (kind, rest)
  }

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> MarkdownRenderable {
    .blockQuote(id: id, item: .init(quoteType: quoteTypes))
  }
}

struct BlockQuoteRenderable: Equatable {
  let quoteType: BlockQuoteType
}
