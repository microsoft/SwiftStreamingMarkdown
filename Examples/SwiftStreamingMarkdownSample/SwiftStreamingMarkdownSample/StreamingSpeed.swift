//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

enum StreamingSpeed: String, CaseIterable, Identifiable {
  case crawl
  case slow
  case normal
  case fast
  case instant

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .crawl: "Crawl"
    case .slow: "Slow"
    case .normal: "Normal"
    case .fast: "Fast"
    case .instant: "Instant"
    }
  }

  func interval(baseInterval: TimeInterval) -> TimeInterval {
    switch self {
    case .crawl: baseInterval * 2.5
    case .slow: baseInterval * 1.5
    case .normal: baseInterval
    case .fast: baseInterval * 0.35
    case .instant: 0
    }
  }
}
