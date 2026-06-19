//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI

struct MarkdownCustomBlockView: View {
  @Environment(\.markdownConfig) private var config: MarkdownRenderConfig

  let block: MarkdownCustomBlock

  var body: some View {
    if let customView = config.customViewBuilder?.view(for: .block(block)) {
      customView
    } else {
      BlockView(renderables: block.content.renderables)
    }
  }
}
