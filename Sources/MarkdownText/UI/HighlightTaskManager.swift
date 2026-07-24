//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import HighlightSwift

actor HighlightTaskManager: ObservableObject {
  /// Shared Highlight instance to avoid creating multiple JSContext/HLJS instances.
  /// Each Highlight() creates its own JSContext and evaluates highlight.min.js (~600KB).
  /// When multiple CodeBlockViews render concurrently, N separate JSContexts cause
  /// JavaScriptCore OOM crashes (COPILOT-IOS-3F9C, 3F7Z, 3FSQ).
  private static let sharedHighlight = Highlight()

  private var latestCode: String?
  private var latestColors: HighlightColors?
  private var isProcessing = false

  func enqueueCode(_ code: String, colors: HighlightColors, completion: @escaping (AttributedString) -> Void) {
    latestCode = code
    latestColors = colors

    if !isProcessing {
      Task {
        await processQueue(completion: completion)
      }
    }
  }

  private func processQueue(completion: @escaping (AttributedString) -> Void) async {
    guard !isProcessing else { return }

    isProcessing = true

    while let codeToProcess = latestCode, let colors = latestColors {
      latestCode = nil

      if let result = try? await Self.sharedHighlight.attributedText(codeToProcess, colors: colors) {
        await MainActor.run {
          completion(result)
        }
      }
    }

    isProcessing = false
  }
}
