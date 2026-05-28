//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import AsyncExtensions
import Foundation

public protocol MarkdownListener {
  func onRender(markdown: RenderableDocument, metadata: MarkdownMetadata?) async
  func onTableCopyTap(content: String) async
  func onTableDownloadTap(content: String) async
}

public final class MarkdownController: ObservableObject {

  private let listener: MarkdownListener?
  private let metadata: MarkdownMetadata?
  private let eventSubject = AsyncCurrentValueSubject<RenderableDocument?>(nil)
  private var listenerTask: Task<(), Error>!

  public init(listener: MarkdownListener?, metadata: MarkdownMetadata?) {
    self.listener = listener
    self.metadata = metadata
  }

  public func onAppear(markdown: RenderableDocument) {
    guard let listener else {
      return
    }
    self.listenerTask = Task {
      for try await md in eventSubject.eraseToAnyAsyncSequence().compactMap({ $0 }) {
        await listener.onRender(markdown: md, metadata: metadata)
      }
    }
    eventSubject.send(markdown)
  }

  public func onChange(markdown: RenderableDocument) {
    eventSubject.send(markdown)
  }

  public func onDisappear() {
    listenerTask?.cancel()
  }
  
  public func onTableCopyTap(content: String) {
    Task {
      await listener?.onTableCopyTap(content: content)
    }
  }
  
  public func onTableDownloadTap(content: String) {
    Task {
      await listener?.onTableDownloadTap(content: content)
    }
  }
}
