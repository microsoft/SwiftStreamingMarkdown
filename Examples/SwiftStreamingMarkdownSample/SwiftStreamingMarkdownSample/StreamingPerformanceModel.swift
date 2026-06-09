//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

@MainActor
final class StreamingPerformanceModel: ObservableObject {
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

  enum RenderMode {
    case streaming
    case staticMarkdown
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

  func reset(totalCharacters: Int, mode: RenderMode) {
    self.mode = mode
    self.totalCharacters = totalCharacters
    streamedCharacters = 0
    chunkCount = 0
    renderCount = 0
    isComplete = false
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
}
