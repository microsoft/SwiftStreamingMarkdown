//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import Markdown
import SwiftUI

extension BlockDirective {

  func convertRenderables(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> [MarkdownRenderable] {
    let content = children.flatMap {
      $0.blockRenderables(attributeContainer: attributeContainer, config: config)
    }
    let block = MarkdownCustomBlock(
      id: id,
      name: name,
      arguments: parsedArguments,
      rawArguments: rawArgumentText,
      content: RenderableDocument(renderables: content)
    )
    return [.customView(id: id, block: block)]
  }

  private var parsedArguments: [String: String] {
    argumentText
      .parseNameValueArguments()
      .reduce(into: [:]) { result, argument in
        result[argument.name] = argument.value
      }
  }

  private var rawArgumentText: String {
    argumentText.segments.map(\.trimmedText).joined(separator: "\n")
  }
}
