//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown
import SwiftUI

extension Markdown.Table: BlockConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> MarkdownRenderable {
    var bodyContainer = attributeContainer
    var headerContainer = attributeContainer
    bodyContainer[.font] = config.tableStyle.textFonts.normal
    bodyContainer[.typography] = config.tableStyle.textFonts
    headerContainer[.font] = config.tableStyle.textFonts.bold ?? config.tableStyle.textFonts.normal
    headerContainer[.typography] = config.tableStyle.textFonts
    let headerCells = self
      .head
      .children
      .compactMap { $0 as? Cell }
      .map { $0.convert(attributeContainer: headerContainer, config: config) }
    let rows = self
      .body
      .children
      .compactMap { $0 as? Row }
      // It may never happen but we filter out rows with wrong # of columns
      .filter { $0.childCount == headerCells.count }
      .map { row in
        let cells = row.children.compactMap { $0 as? Cell }
        return cells.map { $0.convert(attributeContainer: bodyContainer, config: config) }
      }
    // swift-markdown's MarkupFormatter.visitTable crashes with an array index
    // out of bounds when any body row has fewer columns than the header
    // (https://github.com/swiftlang/swift-markdown/issues/238).
    // Guard against this by only calling format() when the table is well-formed.
    let headerColumnCount = self.head.childCount
    let isWellFormed = self.body.children.allSatisfy { $0.childCount == headerColumnCount }
    let rawMarkdown = isWellFormed ? self.format() : ""
    return .table(id: self.id, headers: headerCells, rows: rows, rawMarkdown: rawMarkdown)
  }
}
