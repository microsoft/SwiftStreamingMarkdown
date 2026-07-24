//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(AppKit)
import AppKit
@testable import SwiftStreamingMarkdown
import Testing

@Suite("ParagraphNSView Measurement Tests")
@MainActor
struct ParagraphNSViewTests {

  /// Regression: a paragraph is often measured before SwiftUI has given the view a frame
  /// (e.g. during a navigation transition). Measuring through the view's own text container
  /// used to return a zero height in that state because `widthTracksTextView` forces the
  /// container width to follow the frame width (0), collapsing the paragraph. Measurement
  /// must instead honor the requested width regardless of the view's frame.
  @Test("Measures a non-zero, width-dependent height without a frame")
  func measuresHeightWithoutFrame() {
    let view = ParagraphNSView()
    let longText = String(repeating: "word ", count: 200)
    view.setParagraphContents(NSMutableAttributedString(string: longText), animatedByWord: false)

    let narrow = view.measureSize(fittingWidth: 200)
    let wide = view.measureSize(fittingWidth: 1000)

    #expect(narrow.height > 0, "Wrapping content must have a non-zero height even without a frame")
    #expect(wide.height > 0, "Wrapping content must have a non-zero height even without a frame")
    #expect(
      narrow.height > wide.height,
      "A narrower width must wrap to more lines and therefore be taller, proving the requested width is honored"
    )
  }

  @Test("Empty content measures as zero")
  func measuresEmptyContentAsZero() {
    let view = ParagraphNSView()
    view.setParagraphContents(NSMutableAttributedString(string: ""), animatedByWord: false)

    #expect(view.measureSize(fittingWidth: 400) == .zero)
  }
}
#endif
