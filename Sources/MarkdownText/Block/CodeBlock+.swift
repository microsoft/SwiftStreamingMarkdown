//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown
import SwiftUI

extension CodeBlock: BlockConvertible {
  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> MarkdownRenderable {
    if self.language == LaTexPreProcessorImpl.customCodeType {
      return .latex(id: self.id, content: self.code)
    } else {
      return .codeBlock(id: self.id, language: self.language, code: self.code)
    }
  }
}
