//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import Markdown
import SwiftUI

extension Markdown.Document {

  func convert(with config: MarkdownRenderConfig) -> [MarkdownRenderable] {
    return self
      .blockConvertibleChildren
      .map { $0.convert(attributeContainer: NSAttributeContainer(), config: config) }
  }
}
