//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation

/// Key-value context for the document listener, parsed from JSON.
public struct MarkdownMetadata: Equatable, Sendable {
  public let values: [String: String]

  public init(_ values: [String: String] = [:]) {
    self.values = values
  }

  public init?(json: String) {
    guard let data = json.data(using: .utf8),
          let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
      return nil
    }
    self.values = dict
  }

  public subscript(_ key: String) -> String? {
    values[key]
  }
}
