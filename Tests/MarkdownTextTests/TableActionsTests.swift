//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import XCTest

final class TableActionsTests: XCTestCase {

  func test_controller_without_listener_does_not_handle_table_actions() {
    let controller = MarkdownController(listener: nil)
    XCTAssertFalse(controller.handlesTableActions)
  }

  func test_controller_with_listener_handles_table_actions() {
    let controller = MarkdownController(listener: NoOpMarkdownListener())
    XCTAssertTrue(controller.handlesTableActions)
  }
}

/// `MarkdownListener` that ignores every event.
private struct NoOpMarkdownListener: MarkdownListener {
  func onRender(markdown: RenderableDocument) async {}
  func onTableCopyTap(content: String) async {}
  func onTableDownloadTap(content: String) async {}
  func onContextMenuAppear(id: String, selectedContent: String) async {}
  func onContextMenuTap(id: String, selectedContent: String) async {}
  func onImageTap(image: MarkdownImage) async {}
}
