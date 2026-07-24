//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
@testable import SwiftStreamingMarkdown
import XCTest

final class LinkRenderingTests: XCTestCase {

  private let parser = MarkdownParserImpl()

  /// Regression test for a macOS crash: `Link.convert` stored an empty Swift array
  /// as the `.underlineStyle` attribute value, but TextKit expects an `NSNumber`
  /// and AppKit calls `-integerValue` on it, crashing `NSTextView` with
  /// `-[Swift.__EmptyArrayStorage integerValue]` on any rendered link.
  func test_linkUnderlineStyle_bridgesToNSNumber() async {
    let document = await parser.parse(text: "check the [docs](https://example.com) here")
    let renderables = document.convert(with: .default)

    guard case .paragraph(_, let content) = renderables.first else {
      return XCTFail("Expected a single paragraph")
    }

    var foundUnderlineAttribute = false
    var underlineNumber: NSNumber?
    content.enumerateAttribute(.underlineStyle, in: NSRange(location: 0, length: content.length)) { value, _, _ in
      if value != nil {
        foundUnderlineAttribute = true
        underlineNumber = value as? NSNumber
      }
    }
    XCTAssertTrue(foundUnderlineAttribute, "Expected the link run to carry an underlineStyle attribute")
    XCTAssertNotNil(
      underlineNumber,
      "underlineStyle must bridge to NSNumber — AppKit's TextKit calls -integerValue on it and crashes on any other type"
    )
  }
}
