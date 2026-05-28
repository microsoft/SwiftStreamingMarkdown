//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import SwiftStreamingMarkdown
import SwiftUI

struct StreamedMarkdownView: View {
  let text: String
  let config: MarkdownRenderConfig
  let chunkSize: Int
  let chunkInterval: TimeInterval

  @EnvironmentObject var listener: LoggingMarkdownListener
  @StateObject private var controller: StreamedMarkdownViewController

  init(
    text: String,
    config: MarkdownRenderConfig = .default,
    chunkSize: Int = 48,
    chunkInterval: TimeInterval = 0.2
  ) {
    self.text = text
    self.config = config
    self.chunkSize = chunkSize
    self.chunkInterval = chunkInterval
    _controller = StateObject(
      wrappedValue: StreamedMarkdownViewController(
        chunkSize: chunkSize,
        chunkInterval: chunkInterval,
        config: config
      )
    )
  }

  var body: some View {
    DocumentView(
      renderableDocument: controller.streamedText,
      config: config,
      listener: listener
    )
    .task {
      await controller.startStreaming(text: text)
    }
  }
}

final class StreamedMarkdownViewController: ObservableObject {
  @Published private(set) var streamedText: RenderableDocument = .empty

  private let chunkSize: Int
  private let chunkIntervalNanoseconds: UInt64
  private let parser = MarkdownParserImpl()
  private let config: MarkdownRenderConfig

  init(chunkSize: Int, chunkInterval: TimeInterval, config: MarkdownRenderConfig) {
    self.chunkSize = max(1, chunkSize)
    self.chunkIntervalNanoseconds = UInt64(max(0, chunkInterval) * 1_000_000_000)
    self.config = config
  }

  func startStreaming(text: String) async {
    guard !text.isEmpty else { return }

    var startIndex = text.startIndex

    while startIndex < text.endIndex {
      if Task.isCancelled {
        return
      }
      let endIndex = text.index(startIndex, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
      let textToParse = text[text.startIndex..<endIndex]
      let document = await parser.parse(text: String(textToParse))
      let renderableDocument = await RenderableDocument(document: document, config: config, colorScheme: .light)
      await MainActor.run {
        self.streamedText = renderableDocument
      }
      startIndex = endIndex
      do {
        try await Task.sleep(nanoseconds: chunkIntervalNanoseconds)
      } catch {
        return
      }
    }
  }
}
