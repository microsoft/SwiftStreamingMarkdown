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
      .text(TestStrings.l0)
    ]))

    let view = CanvasView {
      BlockQuoteView(item: renderable)
    }

    assert(view)
  }

  func test_l0_l1_quote() throws {
    let renderable = BlockQuoteRenderable(quoteType: .nested([
      .text(TestStrings.l0),
      .nested([
        .text(TestStrings.l1)
      ])
    ]))

    let view = CanvasView {
      BlockQuoteView(item: renderable)
    }

    assert(view)
  }

  func test_l0_l1_l0_l1_quote() throws {
    let renderable = BlockQuoteRenderable(quoteType: .nested([
      .text(TestStrings.l0),
      .nested([
        .text(TestStrings.l1)
      ]),
      .text(TestStrings.l0),
      .nested([
        .text(TestStrings.l1)
      ])
    ]))

    let view = CanvasView {
      BlockQuoteView(item: renderable)
    }

    assert(view)
  }

  func test_l0_l1_l0_quote() throws {
    let renderable = BlockQuoteRenderable(quoteType: .nested([
      .text(TestStrings.l0),
      .nested([
        .text(TestStrings.l1)
      ]),
      .text(TestStrings.l0)
    ]))

    let view = CanvasView {
      BlockQuoteView(item: renderable)
    }

    assert(view)
  }

  func test_l0_l1_l2_l1_l0_quote() throws {
    let renderable = BlockQuoteRenderable(quoteType: .nested([
      .text(TestStrings.l0),
      .nested([
        .text(TestStrings.l1),
        .nested([
          .text(TestStrings.l2)
        ]),
        .text(TestStrings.l1)
      ]),
      .text(TestStrings.l0)
    ]))

    let view = CanvasView {
      BlockQuoteView(item: renderable)
    }

    assert(view)
  }

  func test_l0_l1_l2_l3_quote() throws {
    let renderable = BlockQuoteRenderable(quoteType: .nested([
      .text(TestStrings.l0),
      .nested([
        .text(TestStrings.l1),
        .nested([
          .text(TestStrings.l2),
          .nested([
            .text(TestStrings.l3)
          ])
        ])
      ])
    ]))

    let view = CanvasView {
      BlockQuoteView(item: renderable)
    }

    assert(view)
  }

  func test_l0_l1_l0_l1_l2_l1_l2_l3_l2_l1_l0_quote() throws {
    let renderable = BlockQuoteRenderable(quoteType: .nested([
      .text(TestStrings.l0),
      .nested([
        .text(TestStrings.l1)
      ]),
      .text(TestStrings.l0),
      .nested([
        .text(TestStrings.l1),
        .nested([
          .text(TestStrings.l2)
        ]),
        .text(TestStrings.l1),
        .nested([
          .text(TestStrings.l2),
          .nested([
            .text(TestStrings.l3)
          ]),
          .text(TestStrings.l2)
        ]),
        .text(TestStrings.l1)
      ]),
      .text(TestStrings.l0)
    ]))

    let view = CanvasView {
      BlockQuoteView(item: renderable)
    }

    assert(view)
  }
}
