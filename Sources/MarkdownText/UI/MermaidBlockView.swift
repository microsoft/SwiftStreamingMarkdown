//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

//
//  MermaidBlockView.swift
//  SwiftStreamingMarkdown
//
//  Created by Sam Clark on 8/11/26.
//

import BeautifulMermaid
import SwiftUI

/// Renders a fenced ` ```mermaid ` code block as a diagram.
///
/// While the source is still streaming in, the block shows the raw code so the
/// diagram renderer never receives partial source. Once the source has been
/// stable for `MermaidStreamDebouncer`'s settle window the diagram is rendered,
/// and if the diagram fails to parse the raw code is shown again.
struct MermaidBlockView: View {
  @Environment(\.markdownConfig) var config: MarkdownRenderConfig
  @Environment(\.colorScheme) var colorScheme

  /// The latest streamed diagram source.
  let code: String

  /// The source committed to the diagram renderer after streaming settled.
  @State private var settledSource = ""
  /// The last parse error reported by the diagram renderer, if any.
  @State private var parseError: Error?
  @State private var debouncer = MermaidStreamDebouncer()

  init(code: String) {
    self.code = code

    let settledSource = State(initialValue: "")
    let parseError = State<Error?>(initialValue: nil)
    let debouncer = MermaidStreamDebouncer()
    debouncer.onCommit = { source in
      settledSource.wrappedValue = source
      parseError.wrappedValue = nil
    }
    _settledSource = settledSource
    _parseError = parseError
    _debouncer = State(initialValue: debouncer)
  }

  var body: some View {
    content
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      .onAppear {
        debouncer.schedule(code)
      }
      .onChange(of: code) { newValue in
        debouncer.schedule(newValue)
      }
      .onDisappear {
        debouncer.cancel()
      }
  }

  @ViewBuilder
  private var content: some View {
    if !code.isEmpty, settledSource == code, parseError == nil {
      MermaidDiagramView(
        source: settledSource,
        theme: config.mermaidConfig.theme.diagramTheme(for: colorScheme),
        parseError: $parseError
      )
    } else {
      MermaidCodeFallbackView(code: code)
    }
  }
}

/// Shows the raw Mermaid source while it is streaming in or when the diagram
/// failed to parse, matching the readable-fallback behavior used for code.
private struct MermaidCodeFallbackView: View {
  @Environment(\.markdownConfig) var config: MarkdownRenderConfig

  let code: String

  var body: some View {
    ScrollView(.horizontal) {
      Text(code)
        .font(config.codeBlockConfig.codeTextFonts)
        .foregroundStyle(config.codeBlockConfig.foregroundColor ?? Color.Static.Stone.Stone350)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
    .scrollIndicators(.hidden)
    .background(config.codeBlockConfig.backgroundColor ?? Color.clear)
  }
}
