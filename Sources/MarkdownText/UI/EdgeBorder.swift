//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftUI

extension View {
  func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
    overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
  }
}

struct EdgeBorder: Shape {
  var width: CGFloat
  var edges: [Edge]

  func path(in rect: CGRect) -> Path {
    edges.map { edge -> Path in
      switch edge {
      case .top: return Path(.init(x: rect.minX, y: rect.minY, width: rect.width, height: width))
      case .bottom: return Path(.init(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
      case .leading: return Path(.init(x: rect.minX, y: rect.minY, width: width, height: rect.height))
      case .trailing: return Path(.init(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
      }
    }.reduce(into: Path()) { $0.addPath($1) }
  }
}
