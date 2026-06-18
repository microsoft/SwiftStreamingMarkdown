//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Markdown
@testable import SwiftStreamingMarkdown
import UIKit
import XCTest

final class ImageAndCustomViewTests: XCTestCase {

  private let parser: MarkdownParser = MarkdownParserImpl()

  func testStandaloneImageConvertsToImageRenderable() async {
    let document = await parser.parse(text: "![Streaming Markdown](StreamingMarkdownSample)")
    let renderable = await RenderableDocument(document: document, config: .default)

    XCTAssertEqual(renderable.renderables.count, 1)
    guard case .image(_, let image) = renderable.renderables.first else {
      XCTFail("Expected image renderable")
      return
    }

    XCTAssertEqual(image.source, "StreamingMarkdownSample")
    XCTAssertEqual(image.alternativeText, "Streaming Markdown")
  }

  func testMixedImageParagraphSplitsIntoRenderableBlocks() async {
    let document = await parser.parse(text: "Before ![Diagram](diagram) after")
    let renderable = await RenderableDocument(document: document, config: .default)

    XCTAssertEqual(renderable.renderables.count, 3)

    guard case .paragraph(_, let leadingText) = renderable.renderables[0],
          case .image(_, let image) = renderable.renderables[1],
          case .paragraph(_, let trailingText) = renderable.renderables[2] else {
      XCTFail("Expected paragraph, image, paragraph renderables")
      return
    }

    XCTAssertEqual(leadingText.string, "Before ")
    XCTAssertEqual(image.source, "diagram")
    XCTAssertEqual(image.alternativeText, "Diagram")
    XCTAssertEqual(trailingText.string, " after")
  }

  func testBlockDirectiveConvertsToCustomBlockRenderable() async {
    let text = """
    @Callout(title: "Heads up", icon: lightbulb) {
    This is **custom** content.
    }
    """

    let result = await parser.parse(
      text: text,
      option: .init(speculativeRewrite: false, parseBlockDirectives: true)
    )
    let renderable = await RenderableDocument(document: result.document, config: .default)

    XCTAssertEqual(renderable.renderables.count, 1)
    guard case .customView(_, let block) = renderable.renderables.first else {
      XCTFail("Expected custom view renderable")
      return
    }

    XCTAssertEqual(block.name, "Callout")
    XCTAssertEqual(block.arguments["title"], "Heads up")
    XCTAssertEqual(block.arguments["icon"], "lightbulb")
    XCTAssertEqual(block.content.attributedStrings.map(\.string).joined(), "This is custom content.")
  }

  func testConfigBuildersPreserveCitationAndCustomViewBuilder() {
    let citationConfig = MarkdownRenderConfig.CitationConfig(
      isEnabled: false,
      font: .systemFont(ofSize: 12),
      textColor: .red,
      backgroundColor: .blue
    )
    let customViewBuilder = MarkdownCustomViewBuilder(id: "test-builder") { _ in nil }
    let config = MarkdownRenderConfig(
      citationConfig: citationConfig,
      customViewBuilder: customViewBuilder
    )
    .withShouldAnimateText(value: true)
    .withParagraphStyle(value: .init(textFonts: Typography.baseTextFonts, textColor: .green))

    XCTAssertFalse(config.citationConfig.isEnabled)
    XCTAssertEqual(config.customViewBuilder, customViewBuilder)
  }
}
