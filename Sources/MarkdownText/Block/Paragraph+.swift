//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import Markdown
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Paragraph: BlockConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> MarkdownRenderable {
    if config.imageConfig.enabled, let image = self.imageOnlyChild {
      return .image(id: self.id, data: ImageData(image: image, imageConfig: config.imageConfig))
    }
    var container = attributeContainer
    container[.font] = config.paragraphStyle.textFonts.normal
    container[.typography] = config.paragraphStyle.textFonts
    if let kern = config.paragraphStyle.textFonts.preferredLetterSpacing {
      container[.kern] = kern
    }
    container[.foregroundColor] = MDColor(config.paragraphStyle.textColor)
    let paragraphContent: NSMutableAttributedString = self.buildParagraphContent(container: container, config: config)
    return MarkdownRenderable.paragraph(id: self.id, content: paragraphContent)
  }

  private var imageOnlyChild: Markdown.Image? {
    guard self.childCount == 1 else {
      return nil
    }
    return self.child(at: 0) as? Markdown.Image
  }
}

extension BlockMarkup {

  func buildParagraphContent(container: NSAttributeContainer, config: MarkdownRenderConfig) -> NSMutableAttributedString {
    let result = NSMutableAttributedString()

    for child in self.children {
      guard let convertible = child as? InlineConvertible else {
        continue
      }

      let coder = config.citationConfig.coder
      if config.citationConfig.isEnabled,
         let link = child as? Markdown.Link,
         let destination = link.destination,
         link.isInlineCitation(coder: coder) {

        // Create citation attachment directly during parsing (as suggested by @hanzhouli_microsoft)
        let attachmentData = coder.decode(linkDestination: destination)
        if let attachmentData = attachmentData,
           let attachment = InlineCitationAttachment(citationData: attachmentData, citationConfig: config.citationConfig) {
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
        let stringPart = convertible.convert(attributeContainer: container, config: config)
        result.append(stringPart)
      }
    }

    return result
  }
}
