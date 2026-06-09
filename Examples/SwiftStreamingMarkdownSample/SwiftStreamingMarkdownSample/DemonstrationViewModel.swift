//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Combine
import Foundation
import SwiftStreamingMarkdown

/// Backing model for `DemonstrationView`. Combines streaming playback controls
/// (play/pause, replay, fast-forward, speed), runtime performance metrics
/// (chunks, renders, latency), and the simulated streamed Markdown source
/// (`StreamedMarkdownSource` conformance) into a single observable state
/// container so the view, control panel, and listener can read/write against
/// one source of truth.
@MainActor
final class DemonstrationViewModel: ObservableObject, StreamedMarkdownSource {
  enum RenderMode {
    case streaming
    case staticMarkdown
  }

  // Source configuration. Set at init and immutable thereafter; safe to read
  // from any isolation as `let` Sendable values on a @MainActor class.
  let fullText: String
  let chunkSize: Int
  let chunkInterval: TimeInterval

  // Playback state.
  @Published var speed: StreamingSpeed = .normal
  @Published private(set) var isPlaying = true
  @Published private(set) var isFastForwarding = false
  @Published private(set) var streamID = UUID()
  @Published var isAtScrollBottom = true
  @Published var isControlDrawerPresented = true

  // Performance metrics.

  @Published private(set) var mode: RenderMode = .streaming
  @Published private(set) var totalCharacters = 0
  @Published private(set) var streamedCharacters = 0
  @Published private(set) var chunkCount = 0
  @Published private(set) var renderCount = 0
  @Published private(set) var isComplete = false
  @Published private(set) var startedAt: Date?
  @Published private(set) var completedAt: Date?
  @Published private(set) var lastChunkAt: Date?
  @Published private(set) var lastRenderAt: Date?
  @Published private(set) var lastRenderLatency: TimeInterval?

  init(
    text: String,
    chunkSize: Int = 48,
    chunkInterval: TimeInterval = 0.2
  ) {
    self.fullText = text
    self.chunkSize = max(1, chunkSize)
    self.chunkInterval = max(0, chunkInterval)
  }

  var progress: Double {
    guard totalCharacters > 0 else { return 0 }
    return min(1, Double(streamedCharacters) / Double(totalCharacters))
  }

  var elapsedTime: TimeInterval {
    guard let startedAt else { return 0 }
    return (completedAt ?? Date()).timeIntervalSince(startedAt)
  }

  var charactersPerSecond: Double {
    guard elapsedTime > 0 else { return 0 }
    return Double(streamedCharacters) / elapsedTime
  }

  var chunksPerSecond: Double {
    guard elapsedTime > 0 else { return 0 }
    return Double(chunkCount) / elapsedTime
  }

  // MARK: - Playback

  func togglePlayback() {
    isPlaying.toggle()
  }

  func play() {
    isPlaying = true
  }

  func replay() {
    isPlaying = true
    streamID = UUID()
  }

  func fastForward() {
    isPlaying = true
    isFastForwarding = true
  }

  func interval(baseInterval: TimeInterval) -> TimeInterval {
    speed.interval(baseInterval: baseInterval)
  }

  func waitUntilPlaying() async {
    for await playing in $isPlaying.values where playing {
      return
    }
  }

  // MARK: - Performance metrics

  func reset(totalCharacters: Int, mode: RenderMode) {
    self.mode = mode
    self.totalCharacters = totalCharacters
    streamedCharacters = 0
    chunkCount = 0
    renderCount = 0
    isComplete = false
    isFastForwarding = false
    startedAt = Date()
    completedAt = nil
    lastChunkAt = nil
    lastRenderAt = nil
    lastRenderLatency = nil
  }

  func recordChunk(snapshotLength: Int, isFinal: Bool) {
    if startedAt == nil {
      reset(totalCharacters: max(totalCharacters, snapshotLength), mode: mode)
    }

    streamedCharacters = snapshotLength
    chunkCount += 1
    lastChunkAt = Date()

    if isFinal {
      isComplete = true
      completedAt = completedAt ?? lastChunkAt
    }
  }

  func recordRender() {
    let now = Date()
    renderCount += 1
    lastRenderAt = now

    if let lastChunkAt {
      lastRenderLatency = max(0, now.timeIntervalSince(lastChunkAt))
    }
  }

  // MARK: - StreamedMarkdownSource
  nonisolated var text: AsyncStream<String> {
    let fullText = self.fullText
    let step = self.chunkSize
    let interval = self.chunkInterval

    return AsyncStream<String> { [weak self] continuation in
      let task = Task { [weak self] in
        await self?.reset(totalCharacters: fullText.count, mode: .streaming)

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

          await self?.waitUntilPlaying()
          if Task.isCancelled { break }

          if await self?.isFastForwarding == true {
            endIndex = fullText.endIndex
          }

          let snapshot = String(fullText[fullText.startIndex..<endIndex])
          continuation.yield(snapshot)
          await self?.recordChunk(
            snapshotLength: snapshot.count,
            isFinal: endIndex == fullText.endIndex
          )

          if endIndex == fullText.endIndex { break }

          let adjustedInterval = await self?.interval(baseInterval: interval) ?? interval

          do {
            try await self?.sleep(interval: adjustedInterval)
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

  private nonisolated func sleep(interval: TimeInterval) async throws {
    guard interval > 0 else { return }

    var remaining = interval
    while remaining > 0 {
      if await isFastForwarding { return }
      await waitUntilPlaying()
      let delay = min(remaining, 0.05)
      let start = Date()
      try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
      remaining -= Date().timeIntervalSince(start)
    }
  }
}
