//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown
import SwiftUI

extension Paragraph: BlockConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig, colorScheme: ColorScheme) -> MarkdownRenderable {
    var container = attributeContainer
    container[.font] = config.paragraphStyle.textFonts.normal
    container[.typography] = config.paragraphStyle.textFonts
    if let kern = config.paragraphStyle.textFonts.preferredLetterSpacing {
      container[.kern] = kern
    }
    container[.foregroundColor] = config.paragraphStyle.textColor
    let paragraphContent: NSMutableAttributedString = self.buildParagraphContent(container: container, config: config, colorScheme: colorScheme)
    return MarkdownRenderable.paragraph(id: self.id, content: paragraphContent)
  }
}

extension BlockMarkup {

  func buildParagraphContent(container: NSAttributeContainer, config: MarkdownRenderConfig, colorScheme: ColorScheme) -> NSMutableAttributedString {
    let result = NSMutableAttributedString()

    for child in self.children {
      guard let convertible = child as? InlineConvertible else {
        continue
      }

      let stringPart = convertible.convert(attributeContainer: container, config: config, colorScheme: colorScheme)
      if let link = child as? Markdown.Link,
         let destination = link.destination,
         link.isAttachmentCitation {

        // Create citation attachment directly during parsing (as suggested by @hanzhouli_microsoft)
        let attachmentData = InlineAttachmentData(linkDestination: destination)
        if let attachmentData = attachmentData,
           let attachment = InlineCitationAttachment(citationData: attachmentData) {
          let attachmentString = NSMutableAttributedString(attachment: attachment)

          // Add link attribute for accessibility activation (space key)
          let url = attachmentData.url
          attachmentString.addAttribute(
            .link,
            value: url,
            range: NSRange(location: 0, length: attachmentString.length)
          )

          // Apply baseline offset to the attachment using the font from config
          attachmentString.addAttribute(
            .baselineOffset,
            value: config.paragraphStyle.textFonts.normal.descender,
            range: NSRange(location: 0, length: attachmentString.length)
          )

          // Add the citation directly to result
          result.append(attachmentString)
        }
      } else {
        result.append(stringPart)
      }
    }

    return result
  }
}
