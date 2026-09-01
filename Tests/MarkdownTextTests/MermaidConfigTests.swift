//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import SwiftUI
import XCTest

final class MermaidConfigTests: XCTestCase {

  func test_default_config_is_enabled_with_auto_theme() {
    XCTAssertTrue(MermaidConfig.default.isEnabled)
    XCTAssertEqual(MermaidConfig.default.theme, .auto)
  }

  func test_disabled_config_opts_out_of_rendering() {
    XCTAssertFalse(MermaidConfig.disabled.isEnabled)
    XCTAssertEqual(MermaidConfig.disabled.theme, .auto)
  }

  func test_custom_theme_is_stored() {
    let config = MermaidConfig(theme: .dracula)
    XCTAssertEqual(config.theme, .dracula)
    XCTAssertTrue(config.isEnabled)
  }

  func test_auto_theme_follows_color_scheme() {
    let theme = MermaidConfig.Theme.auto
    XCTAssertNotEqual(theme.diagramTheme(for: .light), theme.diagramTheme(for: .dark))
  }

  func test_explicit_theme_ignores_color_scheme() {
    let theme = MermaidConfig.Theme.dracula
    XCTAssertEqual(theme.diagramTheme(for: .light), theme.diagramTheme(for: .dark))
  }

  func test_with_mermaid_config_preserves_other_fields() {
    let imageConfig = ImageConfig(enabled: true, allowedImageTypes: [.remote(allowedDomains: [])])
    let alertStyle = MarkdownRenderConfig.defaultBlockQuoteAlertStyle

    let base = MarkdownRenderConfig(imageConfig: imageConfig, blockQuoteAlertStyle: alertStyle)
    let updated = base.withMermaidConfig(.disabled)

    XCTAssertEqual(updated.mermaidConfig, .disabled)
    XCTAssertEqual(updated.imageConfig, imageConfig)
    XCTAssertEqual(updated.blockQuoteAlertStyle, alertStyle)
    XCTAssertEqual(updated.blockQuoteStyle, base.blockQuoteStyle)
    XCTAssertEqual(updated.shouldAnimateText, base.shouldAnimateText)
  }

  func test_with_block_quote_alert_style_preserves_mermaid_config() {
    let base = MarkdownRenderConfig.default.withMermaidConfig(.disabled)
    let updated = base.withBlockQuoteAlertStyle([:])

    XCTAssertEqual(updated.mermaidConfig, .disabled)
    XCTAssertEqual(updated.blockQuoteAlertStyle, [:])
    XCTAssertEqual(updated.imageConfig, base.imageConfig)
  }
}
