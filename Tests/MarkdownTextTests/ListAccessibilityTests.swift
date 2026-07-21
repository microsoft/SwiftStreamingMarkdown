//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import XCTest

final class ListAccessibilityTests: XCTestCase {

  func testMarkdownListItemAccessibilityLabelIsFullyLocalized() throws {
    let testCases = [
      ("en", "List with 12 items, item 3: ITEM_BODY"),
      ("de", "Liste mit 12 Elementen, Element 3: ITEM_BODY"),
      ("zh-Hans", "列表共 12 项，第 3 项：ITEM_BODY"),
      ("ar", "العنصر 3 من قائمة تضم 12 عنصرًا: ITEM_BODY")
    ]

    for (localization, expectedLabel) in testCases {
      let bundle = try localizedBundle(for: localization)
      let label = markdownListAccessibilityLabel(
        for: "ITEM_BODY",
        at: 2,
        length: 12,
        bundle: bundle
      )

      XCTAssertEqual(label, expectedLabel, "Unexpected \(localization) argument ordering")
      if localization != "en" {
        XCTAssertFalse(label.contains("item 3"), "\(localization) contains the English item fragment")
      }
    }
  }

  private func localizedBundle(for localization: String) throws -> Bundle {
    if String.markdownTextResources.url(forResource: "Localizable", withExtension: "xcstrings") != nil {
      throw XCTSkip("String Catalog localization tests require xcodebuild")
    }
    let path = try XCTUnwrap(
      String.markdownTextResources.path(forResource: localization, ofType: "lproj"),
      "Missing compiled localization for \(localization)"
    )
    return try XCTUnwrap(Bundle(path: path))
  }
}
