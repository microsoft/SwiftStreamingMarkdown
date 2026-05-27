//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI

enum Demonstration: String, CaseIterable, Identifiable, Hashable {
  case kitchenSink = "Kitchen Sink"
  case multiParagraph = "Multi-paragraph"
  case tables = "Tables"
  case math = "Math"

  var id: String { rawValue }

  var subtitle: String {
    switch self {
    case .kitchenSink:
      "Every supported feature, plus unsupported markdown fallbacks"
    case .multiParagraph:
      "Excerpts from famous novels"
    case .tables:
      "Top 10 populous cities and basic info"
    case .math:
      "Top 10 most popular math equations"
    }
  }

  var fixtureFileName: String {
    switch self {
    case .kitchenSink: "kitchen-sink"
    case .multiParagraph: "multi-paragraph"
    case .tables: "tables"
    case .math: "math"
    }
  }
}
