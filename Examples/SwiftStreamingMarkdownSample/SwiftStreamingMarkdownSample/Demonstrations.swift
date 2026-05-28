//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftStreamingMarkdown

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
      "Excerpts from famous novels and custom context menu"
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
  
  var customContextMenu: TextContextMenu? {
    switch self {
    case .multiParagraph:
      return TextContextMenu(menuGroups: [
        .init(title: "Group 1", image: UIImage(systemName: "square.and.arrow.up"), displayInline: false, items: [
          .init(id: "1", title: "Item 1"),
          .init(id: "2", title: "Item 2")
        ])
      ])
    default: return nil
    }
  }
}
