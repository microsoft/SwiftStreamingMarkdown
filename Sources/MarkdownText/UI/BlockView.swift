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
      case .heading(_, _, let contents):
        // No `HStack { ParagraphView(); Spacer() }` wrapper (see the .paragraph case below
        // for why) - headings have the same hugging requirement as paragraphs.
        ParagraphView(contents: contents)
          .transition(.opacity)
          .accessibilityAddTraits(.isHeader)
      case .paragraph(_, let contents):
        // Deliberately NOT `HStack { ParagraphView(...); Spacer() }` (the previous
        // implementation). An unqualified `Spacer()` always consumes whatever width its
        // parent HStack is offered - which is correct for *filling* a full-bleed layout, but
        // it means the HStack's own reported width upward is always "whatever was proposed,"
        // never "what the text actually needs." An ancestor that hugs its content to the
        // text's natural width (e.g. a chat bubble capping itself at N% of the screen via its
        // own trailing Spacer(minLength:)) receives that inflated report and can never shrink
        // below its cap, even for a one-word reply. `ParagraphView` itself already renders
        // left-aligned (`UITextView.textAlignment = .left` on iOS, `NSTextView`'s paragraph
        // style alignment on macOS) and BlockView's outer VStack is `alignment: .leading`, so
        // left alignment doesn't depend on the Spacer at all -
        // dropping it fixes hugging with no visible change to left-aligned rendering. A
        // consumer that *wants* full-width fill (e.g. embedding `MarkdownView` in a layout
        // that should always stretch) can still get it by applying
        // `.frame(maxWidth: .infinity, alignment: .leading)` to the whole `MarkdownView` from
        // the outside - that's the caller's decision to make, not this library's default.
        ParagraphView(contents: contents, lineSpacing: 5)
          .fixedSize(horizontal: false, vertical: true)
          .transition(.opacity)
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
