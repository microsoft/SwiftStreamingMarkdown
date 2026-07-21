//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import SwiftUI
import XCTest

final class CodeBlockConfigTests: XCTestCase {

  func testCustomTextFontsAreStoredAndResolvedForRendering() {
    let codeTextFonts = textFonts(size: 24)
    let chromeTextFonts = textFonts(size: 18)
    let config = CodeBlockConfig(
      codeTextFonts: codeTextFonts,
      chromeTextFonts: chromeTextFonts
    )

    XCTAssertEqual(config.codeTextFonts, codeTextFonts)
    XCTAssertEqual(config.chromeTextFonts, chromeTextFonts)
    XCTAssertEqual(config.resolvedCodeTextFonts, codeTextFonts)
    XCTAssertEqual(config.resolvedChromeTextFonts, chromeTextFonts)
  }

  func testDefaultTextFontsPreserveBundledTypography() {
    let config = CodeBlockConfig.default

    XCTAssertNil(config.codeTextFonts)
    XCTAssertNil(config.chromeTextFonts)
    XCTAssertEqual(config.resolvedCodeTextFonts, Typography.codeTextFonts)
    XCTAssertEqual(config.resolvedChromeTextFonts, Typography.smallTextFonts)
  }

  func testOriginalInitializerFunctionTypeRemainsSourceCompatible() {
    let initializer: (
      CodeBlockConfig.Theme,
      Color?,
      Color?
    ) -> CodeBlockConfig = CodeBlockConfig.init

    let config = initializer(.default, nil, nil)

    XCTAssertNil(config.codeTextFonts)
    XCTAssertNil(config.chromeTextFonts)
  }

  private func textFonts(size: CGFloat) -> TextFonts {
    TextFonts(
      normal: MDFont.systemFont(ofSize: size),
      italic: nil,
      bold: nil,
      boldItalic: nil,
      preferredLetterSpacing: nil,
      preferredLineHeight: nil
    )
  }
}
