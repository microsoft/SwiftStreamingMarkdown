//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Markdown
@testable import SwiftStreamingMarkdown
import SwiftUI
import XCTest

/// Snapshot coverage for block-level images parsed from Markdown. Uses the
/// failure case — a remote image whose host is not in the allowed domains —
/// because it resolves to a placeholder synchronously, unlike the remote and
/// bundled loading paths whose async `.task` cannot be captured deterministically.
@MainActor
final class ImageBlockSnapshotTests: SnapshotTestCase {

  let parser: MarkdownParser = MarkdownParserImpl()

  func test_disallowed_remote_image_renders_failure_placeholder() async throws {
    let text = """
    Here is a landscape photo from an untrusted source:

    ![Landscape](https://blocked.example/photo.png)

    The image above cannot be shown because its host is not allowed.
    """
    let config = MarkdownRenderConfig(
      imageConfig: ImageConfig(
        enabled: true,
        allowedImageTypes: [.remote(allowedDomains: ["allowed.example"])]
      )
    )
    let document = await parser.parse(
      text: text,
      option: .init(speculativeRewrite: false, imageSupport: true)
    ).document
    let renderables = await RenderableDocument(document: document, config: config)
    let view = CanvasView {
      DocumentView(renderableDocument: renderables, config: config).padding(.horizontal, 24)
    }
    assert(view)
  }
}
