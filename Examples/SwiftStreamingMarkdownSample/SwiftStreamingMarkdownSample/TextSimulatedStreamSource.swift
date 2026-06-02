//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import AsyncExtensions
import Foundation
import SwiftStreamingMarkdown

/// Simulates a streaming Markdown source from a static `String` by emitting
/// progressively larger prefixes every `chunkInterval` seconds, in `chunkSize`
/// character steps. Used by the sample app to demo `StreamedMarkdownView`
/// without a real network stream.
struct TextSimulatedStreamSource: StreamedMarkdownSource {
  let fullText: String
  let chunkSize: Int
  let chunkInterval: TimeInterval

  init(text: String, chunkSize: Int = 48, chunkInterval: TimeInterval = 0.2) {
    self.fullText = text
    self.chunkSize = max(1, chunkSize)
    self.chunkInterval = max(0, chunkInterval)
  }

  var text: AnyAsyncSequence<String> {
    let fullText = self.fullText
    let step = self.chunkSize
    let intervalNanoseconds = UInt64(self.chunkInterval * 1_000_000_000)

    return AsyncStream<String> { continuation in
      let task = Task {
        guard !fullText.isEmpty else {
          continuation.finish()
          return
        }

        var endIndex = fullText.index(
          fullText.startIndex,
          offsetBy: step,
          limitedBy: fullText.endIndex
        ) ?? fullText.endIndex

        while true {
          if Task.isCancelled { break }
          continuation.yield(String(fullText[fullText.startIndex..<endIndex]))
          if endIndex == fullText.endIndex { break }
          do {
            try await Task.sleep(nanoseconds: intervalNanoseconds)
          } catch {
            break
          }
          endIndex = fullText.index(
            endIndex,
            offsetBy: step,
            limitedBy: fullText.endIndex
          ) ?? fullText.endIndex
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }.eraseToAnyAsyncSequence()
  }
}
