//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
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
