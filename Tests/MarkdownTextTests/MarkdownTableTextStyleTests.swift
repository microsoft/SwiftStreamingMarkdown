//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import SwiftUI
import XCTest

final class MarkdownTableTextStyleTests: XCTestCase {
  func testTableActionsRemainEnabledByDefault() {
    XCTAssertTrue(tableStyle().showTableActions)
  }

  func testTableActionsCanBeDisabled() {
    XCTAssertFalse(tableStyle(showTableActions: false).showTableActions)
  }

  private func tableStyle(showTableActions: Bool = true) -> MarkdownRenderConfig.MarkdownTableTextStyle {
    .init(
      textFonts: MarkdownRenderConfig.defaultTableStyle.textFonts,
      headerTextColor: .primary,
      regularTextColor: .primary,
      headerBackgroundColor: .clear,
      borderColor: .secondary,
      actionButtonColor: .accentColor,
      showTableActions: showTableActions
    )
  }
}
