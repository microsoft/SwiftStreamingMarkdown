//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import XCTest

final class MarkdownRenderConfigBuilderTests: XCTestCase {

  private var nonDefaultImageConfig: ImageConfig {
    ImageConfig(enabled: true, allowedImageTypes: [.remote(allowedDomains: [])])
  }

  func test_builders_preserve_image_config() {
    let defaults = MarkdownRenderConfig.default
    let base = defaults.withImageConfig(nonDefaultImageConfig)
    let builders: [(MarkdownRenderConfig) -> MarkdownRenderConfig] = [
      { $0.withShouldAnimateText(value: true) },
      { $0.withBlockQuoteStyle(value: defaults.blockQuoteStyle) },
      { $0.withHeadingStyle(value: defaults.headingStyle) },
      { $0.withOrderedListStyle(value: defaults.orderedListStyle) },
      { $0.withParagraphStyle(value: defaults.paragraphStyle) },
      { $0.withTableStyle(value: defaults.tableStyle) },
      { $0.withInlineStyle(value: defaults.inlineStyle) },
      { $0.withTextContextMenu(value: nil) },
      { $0.withBlockSpacing(value: defaults.blockSpacing + 1) },
      { $0.withCodeBlockConfig(value: defaults.codeBlockConfig) },
      { $0.withTextSelectionConfig(value: TextSelectionConfig(isEnabled: false)) },
      { $0.withThematicBreakColor(value: defaults.thematicBreakColor) },
      { $0.withImageConfig(.disabled) }
    ]

    for (index, apply) in builders.enumerated() {
      let updated = apply(base)
      if index == builders.count - 1 {
        XCTAssertEqual(updated.imageConfig, .disabled, "withImageConfig should replace imageConfig")
      } else {
        XCTAssertEqual(updated.imageConfig, nonDefaultImageConfig, "builder at index \(index) dropped imageConfig")
      }
    }
  }
}
