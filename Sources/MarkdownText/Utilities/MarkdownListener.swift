//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import AsyncExtensions
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
  private let eventSubject = AsyncCurrentValueSubject<RenderableDocument?>(nil)
  private var listenerTask: Task<(), Error>!

  init(listener: MarkdownListener?) {
    self.listener = listener
  }

  func onAppear(markdown: RenderableDocument) {
    guard let listener else {
      return
    }
    self.listenerTask = Task {
      for try await md in eventSubject.eraseToAnyAsyncSequence().compactMap({ $0 }) {
        await listener.onRender(markdown: md)
      }
    }
    eventSubject.send(markdown)
  }

  func onChange(markdown: RenderableDocument) {
    eventSubject.send(markdown)
  }

  func onDisappear() {
    listenerTask?.cancel()
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
