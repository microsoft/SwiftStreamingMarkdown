//
//  Copyright © 2025 Microsoft. All rights reserved.
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
