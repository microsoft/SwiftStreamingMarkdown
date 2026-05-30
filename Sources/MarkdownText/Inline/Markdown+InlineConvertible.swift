//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown
import SwiftUI
import UniformTypeIdentifiers

extension Markdown.Text: InlineConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig, colorScheme: ColorScheme) -> NSMutableAttributedString {
    return NSMutableAttributedString(string: self.string).mergingAttributes(attributeContainer)
  }
}

extension Markdown.Emphasis: InlineConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig, colorScheme: ColorScheme) -> NSMutableAttributedString {
    let str = NSMutableAttributedString()
    var newContainer = attributeContainer
        
    if let currentTextFonts = attributeContainer[.typography] as? TextFonts {
      let currentFont = attributeContainer[.font] as? UIFont
      newContainer[.font] = currentFont.map { currentTextFonts.italicize(font: $0) } ?? currentTextFonts.italic
    } else {
      newContainer[.font] = config.paragraphStyle.textFonts.italic ?? config.paragraphStyle.textFonts.normal
    }
    self.inlineConvertibleChildren.forEach { convertible in
      str.append(convertible.convert(attributeContainer: newContainer, config: config, colorScheme: colorScheme))
    }
    return str
  }
}

extension Markdown.Strong: InlineConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig, colorScheme: ColorScheme) -> NSMutableAttributedString {
    let str = NSMutableAttributedString()
    var newContainer = attributeContainer
    if let currentTextFonts = attributeContainer[.typography] as? TextFonts {
      let currentFont = attributeContainer[.font] as? UIFont
      newContainer[.font] = currentFont.map { currentTextFonts.bold(font: $0) } ?? currentTextFonts.bold
    } else {
      newContainer[.font] = config.paragraphStyle.textFonts.bold ?? config.paragraphStyle.textFonts.normal
    }
    if self.parent is Paragraph && self.indexInParent == 0 && self.parent?.parent is ListItem && parent?.indexInParent == 0 {
      newContainer[.foregroundColor] = config.inlineStyle.boldTextColor
    }
    self.inlineConvertibleChildren.forEach { convertible in
      str.append(convertible.convert(attributeContainer: newContainer, config: config, colorScheme: colorScheme))
    }
    return str
  }
}

extension Markdown.Strikethrough: InlineConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig, colorScheme: ColorScheme) -> NSMutableAttributedString {
    let str = NSMutableAttributedString()
    var container = attributeContainer
    container[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
    container[.strikethroughColor] = container[.foregroundColor]
    self.inlineConvertibleChildren.forEach { convertible in
      str.append(convertible.convert(attributeContainer: container, config: config, colorScheme: colorScheme))
    }
    return str
  }
}

extension Markdown.Link: InlineConvertible {
  var isAttachmentCitation: Bool {
    self.plainText == InlineCitationConstants.citationMarkerValue
  }

  private var isInlineCitation: Bool {
    guard let destination = self.destination,
          let urlWithMarker = self.createURL(from: destination),
          let components = URLComponents(url: urlWithMarker, resolvingAgainstBaseURL: true)
    else {
      return false
    }
    let queryParam = components.queryItems?.first(
      where: {
        $0.name == InlineCitationConstants.citationMarkerQueryParam && $0.value == InlineCitationConstants.citationMarkerValue
      }
    )
    return queryParam != nil
  }

  private func createURL(from string: String) -> URL? {
    return URL.fromMixedEncodingString(string)
  }

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig, colorScheme: ColorScheme) -> NSMutableAttributedString {
    var container = attributeContainer

    func buildAttributedString() -> NSMutableAttributedString {
      let str = NSMutableAttributedString()
      self.inlineConvertibleChildren.forEach { convertible in
        str.append(convertible.convert(attributeContainer: container, config: config, colorScheme: colorScheme))
      }
      return str
    }

    guard let destination = self.destination,
          let url = self.createURL(from: destination)
    else {
      // Not a valid URL, return plain text
      return buildAttributedString()
    }

    if self.isInlineCitation {
      if self.isAttachmentCitation {
        // Extract title from URL query parameters for new attachment citation format
        if let attachmentData = InlineAttachmentData(linkDestination: destination),
           let citationAttachment = InlineCitationAttachment(citationData: attachmentData, citationConfig: config.citationConfig) {

          // Create attributed string with the citation attachment
          let attributedString = NSMutableAttributedString()
          attributedString.append(NSAttributedString(attachment: citationAttachment))

          return attributedString
        }
        // Fallback to empty string if we can't extract the title
        return NSMutableAttributedString(string: "")
      } else {
        return buildAttributedString()
      }
    } else {
      // Is a real link, provided as markdown
      container[.link] = url
      container[.font] = config.inlineStyle.linkTextFont
      container[.foregroundColor] = config.inlineStyle.linkTextColor
      container[.underlineStyle] = []
      return buildAttributedString()
    }
  }
}

extension Markdown.SoftBreak: InlineConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig, colorScheme: ColorScheme) -> NSMutableAttributedString {
    return NSMutableAttributedString(string: "\n").mergingAttributes(attributeContainer)
  }
}

extension Markdown.LineBreak: InlineConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig, colorScheme: ColorScheme) -> NSMutableAttributedString {
    return NSMutableAttributedString(string: "\n").mergingAttributes(attributeContainer)
  }
}

extension Markdown.InlineCode: InlineConvertible {

  var isInlineLatex: Bool {
    return self.code.hasPrefix(LaTexPreProcessorImpl.inlineCodePrefix) && self.code.hasSuffix(LaTexPreProcessorImpl.inlineCodeSuffix)
  }

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig, colorScheme: ColorScheme) -> NSMutableAttributedString {
    var codeContent = self.code
    if self.isInlineLatex {
      codeContent = String(self
        .code
        .dropFirst(LaTexPreProcessorImpl.inlineCodePrefix.count)
        .dropLast(LaTexPreProcessorImpl.inlineCodeSuffix.count))
      let font = attributeContainer[NSAttributedString.Key.font] as? UIFont ?? config.paragraphStyle.textFonts.normal
      let textColor = config.paragraphStyle.textColor
      let lightHex = textColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).toHexString()
      let darkHex = textColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).toHexString()
      let attachmentData = LatexAttachmentData(
        latex: codeContent,
        fontSize: font.pointSize,
        lightTextColor: lightHex,
        darkTextColor: darkHex
      )
      let encoder = JSONEncoder()
      if let payload = try? encoder.encode(attachmentData) {
        let attachment = NSTextAttachment(data: payload, ofType: UTType.data.identifier)
        return NSMutableAttributedString(attachment: attachment)
      }
    }
    var container = attributeContainer
    container[.font] = config.inlineStyle.codeTextFont
    container[.foregroundColor] = config.inlineStyle.codeTextColor
    container[.backgroundColor] = config.inlineStyle.codeBackgroundColor
    container[.underlineStyle] =  NSUnderlineStyle.patternDot.rawValue
    container[.underlineColor] = config.inlineStyle.codeUnderlineColor
    return NSMutableAttributedString(string: codeContent).mergingAttributes(container)
  }
}

extension Markdown.Table.Cell: InlineConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig, colorScheme: ColorScheme) -> NSMutableAttributedString {
    let str = NSMutableAttributedString()
    self.inlineConvertibleChildren.forEach { convertible in
      str.append(convertible.convert(attributeContainer: attributeContainer, config: config, colorScheme: colorScheme)
        .removingAllOccurrences(of: MarkdownConstants.openingInlineLatexMarker)
        .removingAllOccurrences(of: MarkdownConstants.closingInlineLatexMarker))
    }
    return str
  }
}
