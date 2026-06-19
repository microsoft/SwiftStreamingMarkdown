//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import Markdown
import SwiftUI

extension Paragraph: BlockConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> MarkdownRenderable {
    let container = paragraphAttributeContainer(inheriting: attributeContainer, config: config)
    let paragraphContent: NSMutableAttributedString = self.buildParagraphContent(container: container, config: config)
    return MarkdownRenderable.paragraph(id: self.id, content: paragraphContent)
  }

  func convertRenderables(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> [MarkdownRenderable] {
    guard self.children.contains(where: { $0 is Markdown.Image }) else {
      return [convert(attributeContainer: attributeContainer, config: config)]
    }

    let container = paragraphAttributeContainer(inheriting: attributeContainer, config: config)
    var renderables: [MarkdownRenderable] = []
    var currentText = NSMutableAttributedString()

    func flushText() {
      guard currentText.length > 0 else { return }
      let textID = renderables.isEmpty ? id : "\(id)-paragraph-\(renderables.count)"
      renderables.append(.paragraph(id: textID, content: currentText))
      currentText = NSMutableAttributedString()
    }

    for child in self.children {
      if let image = child as? Markdown.Image {
        flushText()
        renderables.append(.image(id: image.id, image: image.markdownImage))
      } else {
        appendInlineChild(child, to: currentText, container: container, config: config)
      }
    }

    flushText()
    return renderables
  }

  private func paragraphAttributeContainer(inheriting attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> NSAttributeContainer {
    var container = attributeContainer
    container[.font] = config.paragraphStyle.textFonts.normal
    container[.typography] = config.paragraphStyle.textFonts
    if let kern = config.paragraphStyle.textFonts.preferredLetterSpacing {
      container[.kern] = kern
    }
    container[.foregroundColor] = config.paragraphStyle.textColor
    return container
  }
}

extension BlockMarkup {

  func buildParagraphContent(container: NSAttributeContainer, config: MarkdownRenderConfig) -> NSMutableAttributedString {
    let result = NSMutableAttributedString()

    for child in self.children {
      appendInlineChild(child, to: result, container: container, config: config)
    }

    return result
  }

  func appendInlineChild(_ child: Markup, to result: NSMutableAttributedString, container: NSAttributeContainer, config: MarkdownRenderConfig) {
    guard let convertible = child as? InlineConvertible else {
      return
    }

    let coder = config.citationConfig.coder
    if config.citationConfig.isEnabled,
       let link = child as? Markdown.Link,
       let destination = link.destination,
       link.isInlineCitation(coder: coder) {

      let attachmentData = coder.decode(linkDestination: destination)
      if let attachmentData = attachmentData,
         let attachment = InlineCitationAttachment(citationData: attachmentData, citationConfig: config.citationConfig) {
        let attachmentString = NSMutableAttributedString(attachment: attachment)

        attachmentString.addAttribute(
          .link,
          value: attachmentData.url,
          range: NSRange(location: 0, length: attachmentString.length)
        )

        attachmentString.addAttribute(
          .baselineOffset,
          value: config.paragraphStyle.textFonts.normal.descender,
          range: NSRange(location: 0, length: attachmentString.length)
        )

        result.append(attachmentString)
      }
    } else {
      let stringPart = convertible.convert(attributeContainer: container, config: config)
      result.append(stringPart)
    }
  }
}
