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
  case robotoTheme = "Roboto Themed"
  case `default` = "Default"

  var id: String { rawValue }

  var subtitle: String {
    switch self {
    case .kitchenSink:
      "A comprehensive markdown content includes dialects and corner cases to showcase everything that's supported and unsupported."
    case .multiParagraph:
      "Multilingual content with custom iOS context menu"
    case .tables:
      "Top 10 populous cities and basic info"
    case .math:
      "Top 10 most popular math equations"
    case .robotoTheme:
      "Fully custom MarkdownRenderConfig: Roboto fonts + teal-on-purple palette"
    case .default:
      "Same content as Roboto Themed, rendered with the default MarkdownRenderConfig"
    }
  }

  var fixtureFileName: String {
    switch self {
    case .kitchenSink: "kitchen-sink"
    case .multiParagraph: "multi-paragraph"
    case .tables: "tables"
    case .math: "math"
    case .robotoTheme: "roboto"
    case .default: "roboto"
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

  var streamedRenderConfig: MarkdownRenderConfig {
    let base: MarkdownRenderConfig
    switch self {
    case .robotoTheme:
      base = RobotoTheme.renderConfig
    default:
      base = .default
    }
    return base
      .withTextContextMenu(value: customContextMenu)
      .withShouldAnimateText(value: true)
  }

  var nonStreamedRenderConfig: MarkdownRenderConfig {
    switch self {
    case .robotoTheme: RobotoTheme.renderConfig
    default: .default
    }
  }

  var backgroundColor: Color {
    switch self {
    case .robotoTheme: RobotoTheme.pageBackground
    default: Color(.systemBackground)
    }
  }
}
