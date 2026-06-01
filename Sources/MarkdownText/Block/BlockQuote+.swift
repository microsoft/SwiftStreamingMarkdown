//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown
import SwiftUI

extension BlockQuote: BlockConvertible {
  var quoteTypes: BlockQuoteType {
    var finalQuoteTypes = [BlockQuoteType]()

    for child in children {
      if let inlineContainer = child as? InlineContainer {
        // Use our custom extractPlainText method instead of the built-in plainText property
        // to properly handle attachment citations
        finalQuoteTypes.append(.text(inlineContainer.extractPlainText(removeHeading: false)))
      } else if let blockQuoteContainer = child as? BlockQuote {
        finalQuoteTypes.append(blockQuoteContainer.quoteTypes)
      }
    }

    return .nested(finalQuoteTypes)
  }

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> MarkdownRenderable {
    .blockQuote(id: id, item: .init(quoteType: quoteTypes))
  }
}

struct BlockQuoteRenderable: Equatable {
  let quoteType: BlockQuoteType
}
