//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import UIKit

class ParagraphUIViewCache {
  @WithLock
  private var cachedViews: [ParagraphUIView] = []
  private let maxCacheSize = 50 // Limit cache size
  private init() {}

  static let shared: ParagraphUIViewCache = .init()

  func createOrReuseParagraphUIView(contents: NSMutableAttributedString, lineSpacing: CGFloat?) -> ParagraphUIView {
    // First, try to find a cached view that's not being used
    if let availableView = findAvailableCachedView(contents: contents, lineSpacing: lineSpacing) {
      return availableView
    }

    // If no cached view is available, create a new one
    let newView = ParagraphUIView()
    if $cachedViews.read(closure: { $0.count }) < maxCacheSize {
      $cachedViews.mutate { $0.append(newView) }
    }
    return newView
  }

  private func findAvailableCachedView(contents: NSMutableAttributedString, lineSpacing: CGFloat?) -> ParagraphUIView? {
    // Get the first available view that is not currently in use
    let availableView = $cachedViews.read(closure: { cachedView in
      return cachedView.first { view in
        return view.superview == nil && view.window == nil
      }
    })

    return availableView
  }
}
