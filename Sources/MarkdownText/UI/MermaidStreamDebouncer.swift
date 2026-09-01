//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

/// Coalesces rapidly-repeated source updates from a streaming Mermaid code
/// fence so the diagram renderer only re-runs after the source has stopped
/// changing, avoiding per-token layout jitter.
@MainActor final class MermaidStreamDebouncer {

  /// Invoked on the main actor with the latest source once it has been stable
  /// for `delayMs`. Called at most once per `schedule(_:)` burst.
  var onCommit: ((String) -> Void)?

  /// How long a source must stop changing before it is committed.
  private let delayMs: Int

  private var task: Task<Void, Never>?

  /// - Parameter delayMs: See `delayMs`. Defaults to `300`.
  init(delayMs: Int = 300) {
    self.delayMs = max(0, delayMs)
  }

  /// Schedule `source` for commit, cancelling any pending commit.
  func schedule(_ source: String) {
    task?.cancel()
    task = Task { @MainActor [weak self] in
      try? await Task.sleep(ms: self?.delayMs ?? 0)
      guard !Task.isCancelled else { return }
      guard let self else { return }
      self.task = nil
      self.onCommit?(source)
    }
  }

  /// Cancel any pending commit.
  func cancel() {
    task?.cancel()
    task = nil
  }
}
