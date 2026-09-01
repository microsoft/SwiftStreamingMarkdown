//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import Markdown
import XCTest

@MainActor
final class MermaidBlockRenderingTests: XCTestCase {

  private func renderables(for text: String) async -> [MarkdownRenderable] {
    await renderables(for: text, config: MarkdownRenderConfig.default)
  }

  private func renderables(
    for text: String,
    config: MarkdownRenderConfig
  ) async -> [MarkdownRenderable] {
    let parser = MarkdownParserImpl()
    let document = await parser.parse(
      text: text,
      option: .init(speculativeRewrite: false)
    ).document
    return await RenderableDocument(document: document, config: config).renderables
  }

  func test_mermaid_fenced_block_renders_as_mermaid_view() async {
    let renderables = await renderables(for: """
    ```mermaid
    graph TD
      A --> B
    ```
    """)

    XCTAssertEqual(renderables.count, 1)
    guard case .mermaidView(_, let code) = renderables[0] else {
      return XCTFail("Expected a mermaid view, got \(renderables[0])")
    }
    XCTAssertEqual(code, "graph TD\n  A --> B\n")
  }

  func test_mermaid_language_tag_is_case_insensitive() async {
    let renderables = await renderables(for: """
    ```MERMAID
    graph LR
      A --> B
    ```
    """)

    XCTAssertEqual(renderables.count, 1)
    guard case .mermaidView = renderables[0] else {
      return XCTFail("Expected a mermaid view for an uppercase language tag")
    }
  }

  func test_non_mermaid_fenced_block_stays_a_code_block() async {
    let renderables = await renderables(for: """
    ```swift
    let x = 1
    ```
    """)

    XCTAssertEqual(renderables.count, 1)
    guard case .codeBlock(_, let language, let code) = renderables[0] else {
      return XCTFail("Expected a code block, got \(renderables[0])")
    }
    XCTAssertEqual(language, "swift")
    XCTAssertEqual(code, "let x = 1\n")
  }

  func test_disabled_mermaid_config_falls_back_to_code_block() async {
    let config = MarkdownRenderConfig.default.withMermaidConfig(.disabled)
    let renderables = await renderables(
      for: """
      ```mermaid
      graph TD
        A --> B
      ```
      """,
      config: config
    )

    XCTAssertEqual(renderables.count, 1)
    guard case .codeBlock(_, let language, _) = renderables[0] else {
      return XCTFail("Expected a code block when mermaid rendering is disabled")
    }
    XCTAssertEqual(language, "mermaid")
  }

  func test_latex_block_is_not_intercepted_as_mermaid() async {
    let renderables = await renderables(for: """
    $$
    E = mc^2
    $$
    """)

    XCTAssertEqual(renderables.count, 1)
    guard case .latex = renderables[0] else {
      return XCTFail("Expected a latex block, got \(renderables[0])")
    }
  }
}
