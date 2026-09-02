//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import Markdown
import SwiftUI
import UniformTypeIdentifiers

extension Markdown.Text: InlineConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> NSMutableAttributedString {
    return NSMutableAttributedString(string: self.string).mergingAttributes(attributeContainer)
  }
}

extension Markdown.Emphasis: InlineConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> NSMutableAttributedString {
    let str = NSMutableAttributedString()
    var newContainer = attributeContainer

    if let currentTextFonts = attributeContainer[.typography] as? TextFonts {
      let currentFont = attributeContainer[.font] as? MDFont
      newContainer[.font] = currentFont.map { currentTextFonts.italicize(font: $0) } ?? currentTextFonts.italic
    } else {
      newContainer[.font] = config.paragraphStyle.textFonts.italic ?? config.paragraphStyle.textFonts.normal
    }
    self.inlineConvertibleChildren.forEach { convertible in
      str.append(convertible.convert(attributeContainer: newContainer, config: config))
    }
    return str
  }
}

extension Markdown.Strong: InlineConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> NSMutableAttributedString {
    let str = NSMutableAttributedString()
    var newContainer = attributeContainer
    if let currentTextFonts = attributeContainer[.typography] as? TextFonts {
      let currentFont = attributeContainer[.font] as? MDFont
      newContainer[.font] = currentFont.map { currentTextFonts.bold(font: $0) } ?? currentTextFonts.bold
    } else {
      newContainer[.font] = config.paragraphStyle.textFonts.bold ?? config.paragraphStyle.textFonts.normal
    }
    if self.parent is Paragraph && self.indexInParent == 0 && self.parent?.parent is ListItem && parent?.indexInParent == 0 {
      newContainer[.foregroundColor] = MDColor(config.inlineStyle.boldTextColor)
    }
    self.inlineConvertibleChildren.forEach { convertible in
      str.append(convertible.convert(attributeContainer: newContainer, config: config))
    }
    return str
  }
}

extension Markdown.Strikethrough: InlineConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> NSMutableAttributedString {
    let str = NSMutableAttributedString()
    var container = attributeContainer
    container[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
    container[.strikethroughColor] = container[.foregroundColor]
    self.inlineConvertibleChildren.forEach { convertible in
      str.append(convertible.convert(attributeContainer: container, config: config))
    }
    return str
  }
}

extension Markdown.Link: InlineConvertible {
  /// True when this link is a citation that should render as an attachment
  /// bubble. Delegates to the supplied `CitationCoder` so the marker /
  /// query-param format is configurable per render.
  func isInlineCitation(coder: CitationCoder) -> Bool {
    guard let destination = self.destination,
          let url = self.createURL(from: destination)
    else {
      return false
    }
    return coder.isCitation(linkText: self.plainText, url: url)
  }

  private func createURL(from string: String) -> URL? {
    return URL.fromMixedEncodingString(string)
  }

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> NSMutableAttributedString {
    var container = attributeContainer

    func buildAttributedString() -> NSMutableAttributedString {
      let str = NSMutableAttributedString()
      self.inlineConvertibleChildren.forEach { convertible in
        str.append(convertible.convert(attributeContainer: container, config: config))
      }
      return str
    }

    guard let destination = self.destination,
          let url = self.createURL(from: destination)
    else {
      // Not a valid URL, return plain text
      return buildAttributedString()
    }

    let coder = config.citationConfig.coder
    if config.citationConfig.isEnabled, self.isInlineCitation(coder: coder) {
      // Extract title from URL query parameters for new attachment citation format
      if let attachmentData = coder.decode(linkDestination: destination),
         let citationAttachment = InlineCitationAttachment(citationData: attachmentData, citationConfig: config.citationConfig) {

        // Create attributed string with the citation attachment
        let attributedString = NSMutableAttributedString()
        attributedString.append(NSAttributedString(attachment: citationAttachment))

        return attributedString
      }
      // Fallback to empty string if we can't extract the title
      return NSMutableAttributedString(string: "")
    } else {
      // Is a real link, provided as markdown
      container[.link] = url
      container[.font] = config.inlineStyle.linkTextFont
      container[.foregroundColor] = MDColor(config.inlineStyle.linkTextColor)
      container[.underlineStyle] = config.inlineStyle.linkUnderlineStyle.rawValue
      return buildAttributedString()
    }
  }
}

extension Markdown.SoftBreak: InlineConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> NSMutableAttributedString {
    return NSMutableAttributedString(string: "\n").mergingAttributes(attributeContainer)
  }
}

extension Markdown.LineBreak: InlineConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> NSMutableAttributedString {
    return NSMutableAttributedString(string: "\n").mergingAttributes(attributeContainer)
  }
}

extension Markdown.InlineCode: InlineConvertible {

  var isInlineLatex: Bool {
    return self.code.hasPrefix(LaTexPreProcessorImpl.inlineCodePrefix) && self.code.hasSuffix(LaTexPreProcessorImpl.inlineCodeSuffix)
  }

  /// The footnote number when this inline code's payload matches the marker
  /// syntax and is a positive integer; `nil` for user-authored code that merely
  /// resembles one but has a non-numeric payload, which keeps its normal
  /// inline-code rendering. A numeric-payload match renders as a footnote
  /// superscript regardless of whether the preprocessor emitted it or a user
  /// authored it verbatim — the same trade-off the LaTeX marker syntax
  /// already makes.
  var footnoteReferenceNumber: Int? {
    guard self.code.hasPrefix(FootnotePreProcessorImpl.inlineCodePrefix),
          self.code.hasSuffix(FootnotePreProcessorImpl.inlineCodeSuffix)
    else {
      return nil
    }
    let payload = self.code
      .dropFirst(FootnotePreProcessorImpl.inlineCodePrefix.count)
      .dropLast(FootnotePreProcessorImpl.inlineCodeSuffix.count)
    guard let number = Int(payload), number > 0 else { return nil }
    return number
  }

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> NSMutableAttributedString {
    if let footnoteNumber = self.footnoteReferenceNumber {
      let baseFont = attributeContainer[NSAttributedString.Key.font] as? MDFont ?? config.paragraphStyle.textFonts.normal
      var container = attributeContainer
      container[.font] = baseFont.resized(to: baseFont.pointSize * 0.7)
      container[.baselineOffset] = baseFont.pointSize * 0.35
      return NSMutableAttributedString(string: String(footnoteNumber)).mergingAttributes(container)
    }
    var codeContent = self.code
    if self.isInlineLatex {
      codeContent = String(self
        .code
        .dropFirst(LaTexPreProcessorImpl.inlineCodePrefix.count)
        .dropLast(LaTexPreProcessorImpl.inlineCodeSuffix.count))
      let font = attributeContainer[NSAttributedString.Key.font] as? MDFont ?? config.paragraphStyle.textFonts.normal
      let textColor = MDColor(config.paragraphStyle.textColor)
      #if canImport(UIKit)
      let lightHex = textColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).toHexString()
      let darkHex = textColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).toHexString()
      #elseif canImport(AppKit)
      let lightHex = textColor.resolvedForAppearance(.aqua).toHexString()
      let darkHex = textColor.resolvedForAppearance(.darkAqua).toHexString()
      #endif
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
    container[.foregroundColor] = MDColor(config.inlineStyle.codeTextColor)
    container[.backgroundColor] = MDColor(config.inlineStyle.codeBackgroundColor)
    container[.underlineStyle] =  NSUnderlineStyle.patternDot.rawValue
    container[.underlineColor] = MDColor(config.inlineStyle.codeUnderlineColor)
    return NSMutableAttributedString(string: codeContent).mergingAttributes(container)
  }
}

extension Markdown.Table.Cell: InlineConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> NSMutableAttributedString {
    let str = NSMutableAttributedString()
    self.inlineConvertibleChildren.forEach { convertible in
      str.append(convertible.convert(attributeContainer: attributeContainer, config: config))
    }
    return str
  }
}
