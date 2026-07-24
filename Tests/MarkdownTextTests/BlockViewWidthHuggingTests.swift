//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftUI
@testable import SwiftStreamingMarkdown
import XCTest

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Regression coverage for width-hugging: a paragraph/heading block should report a
/// resolved width close to what its text actually needs when proposed more room than
/// that, not the full proposed width. This is what lets an ancestor (e.g. a chat bubble
/// capping itself at some percentage of the screen) shrink to fit short content instead
/// of always stretching to its cap. `SingleBlockView` previously wrapped `ParagraphView`
/// in `HStack(spacing: 0) { ParagraphView(...); Spacer() }`; the unqualified `Spacer()`
/// (no `minLength`) always absorbed the HStack's full proposed width, so the block
/// reported that full width upward regardless of the text's actual size.
@MainActor
final class BlockViewWidthHuggingTests: XCTestCase {

  private let parser = MarkdownParserImpl()
  private let proposedWidth: CGFloat = 300

  func test_shortParagraph_hugsNarrowerThanProposedWidth() async {
    let width = await resolvedWidth(forMarkdown: "hi")
    XCTAssertLessThan(width, 150, "a short paragraph should hug its actual text width, not the full proposed width")
  }

  func test_longParagraph_stillFillsProposedWidth() async {
    let longText = Array(repeating: "word", count: 60).joined(separator: " ")
    let width = await resolvedWidth(forMarkdown: longText)
    XCTAssertGreaterThan(width, 290, "a paragraph that needs to wrap should still use the full proposed width")
  }

  func test_shortHeading_hugsNarrowerThanProposedWidth() async {
    let width = await resolvedWidth(forMarkdown: "# hi")
    XCTAssertLessThan(width, 150, "a short heading should hug its actual text width, not the full proposed width")
  }

  private func resolvedWidth(forMarkdown text: String) async -> CGFloat {
    let document = await parser.parse(text: text)
    let renderables = document.convert(with: .default)
    let view = BlockView(renderables: renderables)
      .environment(\.markdownConfig, .default)

    #if canImport(UIKit)
    let hostingController = UIHostingController(rootView: view)
    #elseif canImport(AppKit)
    let hostingController = NSHostingController(rootView: view)
    #endif

    let size = hostingController.sizeThatFits(in: CGSize(width: proposedWidth, height: .greatestFiniteMagnitude))
    return size.width
  }
}
