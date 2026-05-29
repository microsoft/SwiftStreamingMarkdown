//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown
import SwiftUI

public struct RenderableDocument: Equatable, Sendable {
  let renderables: [MarkdownRenderable]

  public var containsCodeBlock: Bool {
    return renderables.contains(where: { $0.isCodeBlock })
  }

  public var containsBlockQuote: Bool {
    return renderables.contains(where: { $0.isBlockQuote })
  }

  public var isEmpty: Bool {
    return renderables.isEmpty
  }

  public init(document: Document, config: MarkdownRenderConfig, colorScheme: ColorScheme) async {
    self.renderables = document.convert(with: config, colorScheme: colorScheme)
  }

  public init(plainText: String, config: MarkdownRenderConfig) {
    let content = NSMutableAttributedString(
      string: plainText,
      attributes: [
        .font: config.paragraphStyle.textFonts.normal,
        .foregroundColor: config.paragraphStyle.textColor,
        .kern: config.paragraphStyle.textFonts.preferredLetterSpacing
      ]
    )
    self.init(renderables: [.paragraph(id: UUID().uuidString, content: content)])
  }

  init(renderables: [MarkdownRenderable]) {
    self.renderables = renderables
  }

  public static let empty = RenderableDocument(renderables: [])
}

public extension RenderableDocument {

  var attributedStrings: [NSAttributedString] {
    return renderables.flatMap { $0.extractAttributedStrings() }
  }
}

extension MarkdownRenderable {

  public func extractAttributedStrings() -> [NSAttributedString] {
    switch self {
    case .paragraph(_, let str):
      return [str]
    case .orderedList(_, let items):
      return items.flatMap { $0.attributedStrings() }
    case .unorderedList(_, let items, _):
      return items.flatMap { $0.attributedStrings() }
    case .table(_, let headers, let rows, _):
      return headers + rows.flatMap { $0 }
    default:
      return []
    }
  }
}

extension MarkdownListItem {

  public func attributedStrings() -> [NSAttributedString] {
    return self.children.flatMap { $0.extractAttributedStrings() }
  }
}
