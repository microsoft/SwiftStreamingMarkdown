//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import SwiftUI
import XCTest

final class CodeBlockConfigTests: XCTestCase {

  func testCustomTextFontsAreStoredForRendering() {
    let codeTextFonts = textFonts(size: 24)
    let chromeTextFonts = textFonts(size: 18)
    let config = CodeBlockConfig(
      codeTextFonts: codeTextFonts,
      chromeTextFonts: chromeTextFonts
    )

    XCTAssertEqual(config.codeTextFonts, codeTextFonts)
    XCTAssertEqual(config.chromeTextFonts, chromeTextFonts)
  }

  func testDefaultTextFontsPreserveBundledTypography() {
    let config = CodeBlockConfig.default

    XCTAssertEqual(config.codeTextFonts, Typography.codeTextFonts)
    XCTAssertEqual(config.chromeTextFonts, Typography.smallTextFonts)
  }

  func testOriginalInitializerFunctionTypeRemainsSourceCompatible() {
    let initializer: (
      CodeBlockConfig.Theme,
      Color?,
      Color?
    ) -> CodeBlockConfig = CodeBlockConfig.init

    let config = initializer(.default, nil, nil)

    XCTAssertEqual(config.codeTextFonts, Typography.codeTextFonts)
    XCTAssertEqual(config.chromeTextFonts, Typography.smallTextFonts)
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
