//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
@testable import SwiftStreamingMarkdown
import XCTest

/// Audits every attribute the conversion pipeline emits and asserts the value types
/// TextKit expects. TextKit reads numeric attributes via `-integerValue`/`-doubleValue`
/// and crashes on any other type — on AppKit this surfaced as
/// `-[Swift.__EmptyArrayStorage integerValue]` when a link stored an empty Swift array
/// as its `underlineStyle`. This test fails on any platform when an attribute of the
/// wrong type enters the pipeline, so that class of crash can't silently return.
final class AttributeTypeSafetyTests: XCTestCase {

  private let parser = MarkdownParserImpl()

  /// Keys TextKit reads as numbers.
  private static let numericKeys: Set<NSAttributedString.Key> = [
    .underlineStyle, .strikethroughStyle, .baselineOffset, .kern, .ligature, .expansion, .obliqueness
  ]

  /// Keys TextKit reads as colors.
  private static let colorKeys: Set<NSAttributedString.Key> = [
    .foregroundColor, .backgroundColor, .underlineColor, .strikethroughColor
  ]

  /// Library-internal keys that TextKit never reads; exempt from the audit.
  private static let internalKeys: Set<NSAttributedString.Key> = [
    .typography
  ]

  func test_renderedAttributes_haveTextKitSafeTypes() async {
    let text = """
    Text with **bold**, *italic*, ~~strikethrough~~, `inline code`,
    a [link](https://example.com), inline math \\(x^2\\), and a citation
    [9F742443](https://example.com?citationMarker=9F742443&citationTitle=Doc&citationA11yValue=Doc).

    - list item with a [link](https://example.com/2) and `code`
    - [x] task item with ~~strike~~

    1. ordered item with **bold** and a [link](https://example.com/3)

    | header | other |
    | --- | --- |
    | **bold** | [link](https://example.com/4) |
    """
    let document = await parser.parse(text: text)
    let renderable = await RenderableDocument(document: document, config: .default)
    let strings = renderable.attributedStrings
    XCTAssertFalse(strings.isEmpty, "Expected the fixture to produce attributed strings to audit")

    for attributed in strings {
      attributed.enumerateAttributes(in: NSRange(location: 0, length: attributed.length)) { attributes, range, _ in
        let runText = attributed.attributedSubstring(from: range).string
        for (key, value) in attributes where !Self.internalKeys.contains(key) {
          let failure = "\(key.rawValue) carries \(type(of: value)) in run '\(runText)'"
          if Self.numericKeys.contains(key) {
            XCTAssertTrue(value is NSNumber, "\(failure) — TextKit expects NSNumber")
          } else if Self.colorKeys.contains(key) {
            XCTAssertTrue(value is MDColor, "\(failure) — TextKit expects a platform color")
          } else {
            switch key {
            case .font:
              XCTAssertTrue(value is MDFont, "\(failure) — TextKit expects a platform font")
            case .link:
              XCTAssertTrue(value is URL || value is String, "\(failure) — TextKit expects URL or String")
            case .attachment:
              XCTAssertTrue(value is NSTextAttachment, "\(failure) — TextKit expects NSTextAttachment")
            case .paragraphStyle:
              XCTAssertTrue(value is NSParagraphStyle, "\(failure) — TextKit expects NSParagraphStyle")
            default:
              break
            }
          }
        }
      }
    }
  }
}
