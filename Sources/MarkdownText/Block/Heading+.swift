//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown
import SwiftUI

extension Heading: BlockConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> MarkdownRenderable {
    var newContainer = attributeContainer
    let headingFont: TextFonts
    switch level {
    case 1:
      headingFont = config.headingStyle.h1Font
    case 2:
      headingFont = config.headingStyle.h2Font
    case 3:
      headingFont = config.headingStyle.h3Font
    case 4:
      headingFont = config.headingStyle.h4Font
    case 5:
      headingFont = config.headingStyle.h5Font
    case 6:
      headingFont = config.headingStyle.h6Font
    default:
      headingFont = config.headingStyle.h6Font
    }
    newContainer[.font] = headingFont.normal
    newContainer[.typography] = headingFont
    if let kern = headingFont.preferredLetterSpacing {
      newContainer[.kern] = kern
    }
    newContainer[.foregroundColor] = config.headingStyle.textColor
    let paragraphContent = buildParagraphContent(container: newContainer, config: config)
    return .heading(id: self.id, level: self.level, content: paragraphContent)
  }
}
