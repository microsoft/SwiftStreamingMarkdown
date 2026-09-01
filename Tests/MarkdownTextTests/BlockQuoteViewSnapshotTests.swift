//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Markdown
@testable import SwiftStreamingMarkdown
import XCTest

enum TestStrings {
  static let l0 = "Level 0"
  static let l1 = "Level 1"
  static let l2 = "Level 2"
  static let l3 = "Level 3"
}

final class BlockQuoteViewSnapshotTests: SnapshotTestCase {

  func test_l0_quote() throws {
    let renderable = BlockQuoteRenderable(quoteType: .nested([
      .text(TestStrings.l0, nil)
    ], nil))

    let view = CanvasView {
      BlockQuoteView(item: renderable)
    }

    assert(view)
  }

  func test_l0_l1_quote() throws {
    let renderable = BlockQuoteRenderable(quoteType: .nested([
      .text(TestStrings.l0, nil),
      .nested([
        .text(TestStrings.l1, nil)
      ], nil)
    ], nil))

    let view = CanvasView {
      BlockQuoteView(item: renderable)
    }

    assert(view)
  }

  func test_l0_l1_l0_l1_quote() throws {
    let renderable = BlockQuoteRenderable(quoteType: .nested([
      .text(TestStrings.l0, nil),
      .nested([
        .text(TestStrings.l1, nil)
      ], nil),
      .text(TestStrings.l0, nil),
      .nested([
        .text(TestStrings.l1, nil)
      ], nil)
    ], nil))

    let view = CanvasView {
      BlockQuoteView(item: renderable)
    }

    assert(view)
  }

  func test_l0_l1_l0_quote() throws {
    let renderable = BlockQuoteRenderable(quoteType: .nested([
      .text(TestStrings.l0, nil),
      .nested([
        .text(TestStrings.l1, nil)
      ], nil),
      .text(TestStrings.l0, nil)
    ], nil))

    let view = CanvasView {
      BlockQuoteView(item: renderable)
    }

    assert(view)
  }

  func test_l0_l1_l2_l1_l0_quote() throws {
    let renderable = BlockQuoteRenderable(quoteType: .nested([
      .text(TestStrings.l0, nil),
      .nested([
        .text(TestStrings.l1, nil),
        .nested([
          .text(TestStrings.l2, nil)
        ], nil),
        .text(TestStrings.l1, nil)
      ], nil),
      .text(TestStrings.l0, nil)
    ], nil))

    let view = CanvasView {
      BlockQuoteView(item: renderable)
    }

    assert(view)
  }

  func test_l0_l1_l2_l3_quote() throws {
    let renderable = BlockQuoteRenderable(quoteType: .nested([
      .text(TestStrings.l0, nil),
      .nested([
        .text(TestStrings.l1, nil),
        .nested([
          .text(TestStrings.l2, nil),
          .nested([
            .text(TestStrings.l3, nil)
          ], nil)
        ], nil)
      ], nil)
    ], nil))

    let view = CanvasView {
      BlockQuoteView(item: renderable)
    }

    assert(view)
  }

  func test_l0_l1_l0_l1_l2_l1_l2_l3_l2_l1_l0_quote() throws {
    let renderable = BlockQuoteRenderable(quoteType: .nested([
      .text(TestStrings.l0, nil),
      .nested([
        .text(TestStrings.l1, nil)
      ], nil),
      .text(TestStrings.l0, nil),
      .nested([
        .text(TestStrings.l1, nil),
        .nested([
          .text(TestStrings.l2, nil)
        ], nil),
        .text(TestStrings.l1, nil),
        .nested([
          .text(TestStrings.l2, nil),
          .nested([
            .text(TestStrings.l3, nil)
          ], nil),
          .text(TestStrings.l2, nil)
        ], nil),
        .text(TestStrings.l1, nil)
      ], nil),
      .text(TestStrings.l0, nil)
    ], nil))

    let view = CanvasView {
      BlockQuoteView(item: renderable)
    }

    assert(view)
  }
}
