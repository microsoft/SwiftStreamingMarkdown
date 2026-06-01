//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation

extension Task where Success == Never, Failure == Never {
  static func sleep(seconds: Double) async throws {
    let duration = UInt64(seconds * 1_000_000_000)
    try await Task.sleep(nanoseconds: duration)
  }

  static func sleep(ms: Int) async throws {
    try await Task.sleep(nanoseconds: UInt64(ms) * 1000 * 1000)
  }
}
