//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftStreamingMarkdown

struct LoggingMarkdownListener: MarkdownListener {
  func onRender(markdown: RenderableDocument, metadata: MarkdownMetadata?) async {
    print("[MarkdownListener] onRender(metadata: \(metadata.map { String(describing: $0) } ?? "nil"))")
  }

  func onTableCopyTap(content: String) async {
    print("[MarkdownListener] onTableCopyTap(content: \(content.debugDescription))")
  }

  func onTableDownloadTap(content: String) async {
    print("[MarkdownListener] onTableDownloadTap(content: \(content.debugDescription))")
  }
}
