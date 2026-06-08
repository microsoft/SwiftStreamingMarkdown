//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

extension URL {
  static func fromMixedEncodingString(_ rawValue: String) -> URL? {
    if let url = URL(string: rawValue) {
      return url
    }

    var candidate = rawValue
    for _ in 0..<3 {
      guard let decoded = candidate.removingPercentEncoding, decoded != candidate else {
        break
      }
      if let url = URL(string: decoded) {
        return url
      }
      candidate = decoded
    }

    let cleaned = candidate
      .replacingOccurrences(of: " ", with: "%20")
      .replacingOccurrences(of: "\n", with: "")
      .replacingOccurrences(of: "\t", with: "")

    return URL(string: cleaned)
  }
}
