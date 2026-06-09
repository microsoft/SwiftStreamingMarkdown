//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import UIKit

/// Markdown element representation that is ready to be rendered by a SwiftUI View
/// The representation already have all the parsing and processing completed to minimize rendering overhead on UI thread.
/// This data structure is not thread safe due to the usage of `NSMutableAttributedString`, this needs to be addressed as a future improvement
indirect enum MarkdownRenderable: Identifiable, Equatable, @unchecked Sendable {

  /// To be rendered as a paragraph
  case paragraph(id: String, content: NSMutableAttributedString)

  /// To be rendered as LaTeX (Math formatting)
  case latex(id: String, content: String)

  /// To be rendered as a heading
  case heading(id: String, level: Int, content: NSMutableAttributedString)

  /// To be rendered as a ordered list view
  case orderedList(id: String, items: [MarkdownListItem])

  /// To be rendered as an unordered list
  case unorderedList(id: String, items: [MarkdownListItem], nestedLevel: Int)

  /// To be rendered as a code block
  case codeBlock(id: String, language: String?, code: String)

  /// To be rendered as a table
  case table(id: String, headers: [NSMutableAttributedString], rows: [[NSMutableAttributedString]], rawMarkdown: String)

  /// To be rendered as thematic break
  case thematicBreak(id: String)

  /// To be rendered as a block quote
  case blockQuote(id: String, item: BlockQuoteRenderable)

  var id: String {
    switch self {
    case .paragraph(let id, _): return id
    case .latex(let id, _): return id
    case .heading(let id, _, _): return id
    case .orderedList(let id, _): return id
    case .unorderedList(let id, _, _): return id
    case .codeBlock(let id, _, _): return id
    case .table(let id, _, _, _): return id
    case .thematicBreak(let id): return id
    case .blockQuote(let id, _): return id
    }
  }

  var isCodeBlock: Bool {
    switch self {
    case .codeBlock: return true
    default: return false
    }
  }

  var isBlockQuote: Bool {
    switch self {
    case .blockQuote: return true
    default: return false
    }
  }
}

struct MarkdownListItem: Equatable {
  let children: [MarkdownRenderable]
  let startsWithBold: Bool
}
