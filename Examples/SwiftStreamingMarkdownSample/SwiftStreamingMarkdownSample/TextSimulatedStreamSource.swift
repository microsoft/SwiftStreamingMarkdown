//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

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
  let playback: StreamingPlaybackController?
  let performanceMetrics: StreamingPerformanceModel?

  init(
    text: String,
    chunkSize: Int = 48,
    chunkInterval: TimeInterval = 0.2,
    playback: StreamingPlaybackController? = nil,
    performanceMetrics: StreamingPerformanceModel? = nil
  ) {
    self.fullText = text
    self.chunkSize = max(1, chunkSize)
    self.chunkInterval = max(0, chunkInterval)
    self.playback = playback
    self.performanceMetrics = performanceMetrics
  }

  var text: AsyncStream<String> {
    let fullText = self.fullText
    let step = self.chunkSize
    let interval = self.chunkInterval
    let playback = self.playback
    let performanceMetrics = self.performanceMetrics

    return AsyncStream<String> { continuation in
      let task = Task {
        let fastForwardBaseline: Int
        if let playback {
          fastForwardBaseline = await playback.fastForwardVersion
        } else {
          fastForwardBaseline = 0
        }

        await performanceMetrics?.reset(totalCharacters: fullText.count, mode: .streaming)

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

          do {
            try await playback?.waitUntilPlaying()
          } catch {
            break
          }

          if await playback?.shouldFastForward(since: fastForwardBaseline) == true {
            endIndex = fullText.endIndex
          }

          let snapshot = String(fullText[fullText.startIndex..<endIndex])
          continuation.yield(snapshot)
          await performanceMetrics?.recordChunk(
            snapshotLength: snapshot.count,
            isFinal: endIndex == fullText.endIndex
          )

          if endIndex == fullText.endIndex { break }

          let adjustedInterval: TimeInterval
          if let playback {
            adjustedInterval = await playback.interval(baseInterval: interval)
          } else {
            adjustedInterval = interval
          }

          do {
            try await sleep(
              interval: adjustedInterval,
              playback: playback,
              fastForwardBaseline: fastForwardBaseline
            )
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
    }
  }

  private func sleep(
    interval: TimeInterval,
    playback: StreamingPlaybackController?,
    fastForwardBaseline: Int
  ) async throws {
    guard interval > 0 else { return }

    var remaining = interval
    while remaining > 0 {
      if await playback?.shouldFastForward(since: fastForwardBaseline) == true {
        return
      }

      try await playback?.waitUntilPlaying()
      let delay = min(remaining, 0.05)
      let start = Date()
      try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
      remaining -= Date().timeIntervalSince(start)
    }
  }
}
