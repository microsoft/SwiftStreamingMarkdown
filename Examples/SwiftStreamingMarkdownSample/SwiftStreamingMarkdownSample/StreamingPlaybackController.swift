//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

@MainActor
final class StreamingPlaybackController: ObservableObject {
  @Published var speed: StreamingSpeed = .normal
  @Published private(set) var isPlaying = true
  @Published private(set) var streamID = UUID()

  private var fastForwardRequest = 0

  var fastForwardVersion: Int { fastForwardRequest }

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
    fastForwardRequest += 1
  }

  func shouldFastForward(since baseline: Int) -> Bool {
    fastForwardRequest != baseline
  }

  func interval(baseInterval: TimeInterval) -> TimeInterval {
    speed.interval(baseInterval: baseInterval)
  }

  func waitUntilPlaying() async throws {
    while !isPlaying {
      try await Task.sleep(nanoseconds: 75_000_000)
    }
  }
}
