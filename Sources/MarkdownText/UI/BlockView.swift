//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftUI

struct BlockView: View {

  @Environment(\.markdownConfig) var config: MarkdownRenderConfig

  let renderables: [MarkdownRenderable]

  init(renderables: [MarkdownRenderable]) {
    self.renderables = renderables
  }

  var body: some View {
    VStack(alignment: .leading, spacing: config.blockSpacing) {
      ForEach(renderables) { renderable in
        SingleBlockView(renderable: renderable)
      }
    }
  }
}

struct SingleBlockView: View {

  @Environment(\.markdownConfig) var config: MarkdownRenderConfig

  let renderable: MarkdownRenderable

  init(renderable: MarkdownRenderable) {
    self.renderable = renderable
  }

  var body: some View {
    Group {
      switch renderable {
      case .heading(_, _, let contents), .paragraph(_, let contents), .textGroup(_, _, let contents):
        // One branch for all text blocks, so a block that becomes a group while streaming keeps its text view.
        ParagraphView(contents: contents)
          .fixedSize(horizontal: false, vertical: true)
          .transition(.opacity)
          .accessibilityAddTraits(renderable.isHeading ? .isHeader : [])
      case .latex(_, let latexString):
        ScrollView(.horizontal) {
          HStack(spacing: 0) {
            BlockMathView(latex: latexString, color: config.paragraphStyle.textColor)
            Spacer()
          }
        }.scrollIndicators(.hidden)
      case .orderedList(_, let items):
        OrderedListView(items: items)
      case .unorderedList(_, let items, let nestedLevel):
        UnorderedListView(items: items, nestedLevel: nestedLevel)
      case .codeBlock(_, let language, let code):
        CodeBlockView(language: language ?? "",
                      code: code)
      case .thematicBreak:
        ThematicBreakView()
      case .table(_, let headers, let rows, let rawMarkdown):
        TableView(headings: headers,
                  rows: rows,
                  rawMarkdown: rawMarkdown)
      case .blockQuote(_, let item):
        BlockQuoteView(item: item)
      case .image(let id, let data):
        BlockImageView(data: data)
          .id(id)
      }
    }
  }
}
