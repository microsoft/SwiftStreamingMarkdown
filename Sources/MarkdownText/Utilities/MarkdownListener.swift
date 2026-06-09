//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

public protocol MarkdownListener {
  func onRender(markdown: RenderableDocument) async
  func onTableCopyTap(content: String) async
  func onTableDownloadTap(content: String) async
  func onContextMenuAppear(id: String, selectedContent: String) async
  func onContextMenuTap(id: String, selectedContent: String) async
}

public final class MarkdownController: ObservableObject {

  private let listener: MarkdownListener?
  private var continuation: AsyncStream<RenderableDocument>.Continuation?
  private var listenerTask: Task<Void, Never>?

  init(listener: MarkdownListener?) {
    self.listener = listener
  }

  func onAppear(markdown: RenderableDocument) {
    // Defensively tear down any prior run so a duplicate `onAppear` can't
    // strand a previous stream/task.
    onDisappear()

    guard let listener else {
      return
    }

    // `.bufferingNewest(1)` coalesces rapid `onChange` deliveries while the
    // listener is still awaiting `onRender`, so a slow listener doesn't
    // replay every intermediate parse — only the most recent state.
    let stream = AsyncStream<RenderableDocument>(bufferingPolicy: .bufferingNewest(1)) { continuation in
      self.continuation = continuation
    }
    listenerTask = Task {
      // Deliver the initial markdown directly to avoid losing it to a rapid
      // `onChange` that could overwrite the single-slot buffer before the
      // for-await loop starts iterating.
      await listener.onRender(markdown: markdown)
      for await md in stream {
        await listener.onRender(markdown: md)
      }
    }
  }

  func onChange(markdown: RenderableDocument) {
    continuation?.yield(markdown)
  }

  func onDisappear() {
    continuation?.finish()
    continuation = nil
    listenerTask?.cancel()
    listenerTask = nil
  }

  func onTableCopyTap(content: String) {
    Task {
      await listener?.onTableCopyTap(content: content)
    }
  }

  func onTableDownloadTap(content: String) {
    Task {
      await listener?.onTableDownloadTap(content: content)
    }
  }

  func onContextMenuAppear(id: String, selectedContent: String) {
    Task {
      await listener?.onContextMenuAppear(id: id, selectedContent: selectedContent)
    }
  }

  func onContextMenuTap(id: String, selectedContent: String) {
    Task {
      await listener?.onContextMenuTap(id: id, selectedContent: selectedContent)
    }
  }
}
