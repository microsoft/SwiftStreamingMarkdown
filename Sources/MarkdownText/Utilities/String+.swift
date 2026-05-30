//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown

extension String {

  public func withoutCitationLinks() async -> String {
    // Identify all link markdown that have URLs that contain "citationMarker" as a query param name (plus surrounding whitespace)
    // The pattern matches markdown links [text](url) where the URL contains "citationMarker".
    // Since parentheses in citation titles are now percent-encoded as %28 and %29,
    // we use a non-greedy match that stops at the first unmatched closing parenthesis.
    let citationLinkPattern = #"(\s*)\[[^\]]*\]\([^)]*citationMarker[^)]*\)(\s*)"#
    if let citationRegex = try? NSRegularExpression(pattern: citationLinkPattern, options: []) {
      let range = NSRange(self.startIndex..<self.endIndex, in: self)
      let withoutCitationLinks = citationRegex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
      return withoutCitationLinks
    } else {
      return self
    }
  }

  public func markdownToPlainText(removeHeading: Bool = false) async -> String {
    let markdownParser = MarkdownParserImpl()
    let document = await markdownParser.parse(text: self)
    return document.extractPlainText(removeHeading: removeHeading)
  }

  static func itemPositionInTable(rowIndex: Int, totalRow: Int, columnIndex: Int, totalColumn: Int) -> String {
    return String(format:
      NSLocalizedString(
        "a11y_item_position_in_table",
        bundle: .module,
        value: "Row %d of %d, Column %d of %d",
        comment: "a11y understand their position in the table"
      ), rowIndex, totalRow, columnIndex, totalColumn)
  }

  static func openCitation(citationLabel: String) -> String {
    return String(format:
      NSLocalizedString(
        "a11y_open_citation",
        bundle: .module,
        value: "Open %@, link",
        comment: "Accessibility action to open a citation link"
      ), citationLabel)
  }

  static func markdownList(length: String) -> String {
    return String(format:
      NSLocalizedString(
        "markdown_list",
        bundle: .module,
        value: "List with %@ items",
        comment: "Description for a list with some items"
      ),
      length)
  }

  static let codeCopyLabel = NSLocalizedString(
    "code_block_copy",
    bundle: .module,
    value: "Copy",
    comment: "Button label to copy a code block to clipboard"
  )

  static let codeCopiedLabel = NSLocalizedString(
    "code_block_copied",
    bundle: .module,
    value: "Copied",
    comment: "Button label shown after a code block has been copied to clipboard"
  )

}

extension Markdown.Document {
  func extractPlainText(removeHeading: Bool) -> String {
    var result = ""

    for child in children {
      result += child.extractPlainText(removeHeading: removeHeading)
      result += "\n\n"
    }

    return result.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

extension Markup {
  /// Recursively extracts plain text from any markdown element
  func extractPlainText(removeHeading: Bool) -> String {
    // Handle specific markup types
    switch self {
    case let text as Markdown.Text:
      return text.string

    case let heading as Heading:
      return removeHeading ? "" : heading.plainText

    case let paragraph as Paragraph:
      // Extract text from paragraph children to handle attachment citations
      return paragraph.children.map {
        $0.extractPlainText(removeHeading: removeHeading)
      }.joined()

    case let codeBlock as CodeBlock:
      return codeBlock.code

    case let inlineCode as Markdown.InlineCode:
      return inlineCode.code

    case let link as Markdown.Link:
      // Handle attachment citations by extracting title from URL parameters
      if let destination = link.destination,
         let url = URL.fromMixedEncodingString(destination),
         CitationCoder.default.isCitation(linkText: link.plainText, url: url),
         let attachmentData = CitationCoder.default.decode(linkDestination: destination) {
        return attachmentData.title
      }

      // For regular links, extract the link text content, not the URL
      var linkText = ""
      for child in link.children {
        linkText += child.extractPlainText(removeHeading: removeHeading)
      }
      return linkText.isEmpty ? (link.destination ?? "") : linkText

    case let emphasis as Markdown.Emphasis:
      var text = ""
      for child in emphasis.children {
        text += child.extractPlainText(removeHeading: removeHeading)
      }
      return text

    case let strong as Markdown.Strong:
      var text = ""
      for child in strong.children {
        text += child.extractPlainText(removeHeading: removeHeading)
      }
      return text

    case let strikethrough as Markdown.Strikethrough:
      var text = ""
      for child in strikethrough.children {
        text += child.extractPlainText(removeHeading: removeHeading)
      }
      return text

    case let listItem as ListItem:
      var text = ""
      for child in listItem.children {
        text += child.extractPlainText(removeHeading: removeHeading)
      }
      return text

    case let orderedList as OrderedList:
      var text = ""
      for (index, child) in orderedList.children.enumerated() {
        if let listItem = child as? ListItem {
          text += "\(index + 1). \(listItem.extractPlainText(removeHeading: removeHeading))\n"
        }
      }
      return text

    case let unorderedList as UnorderedList:
      var text = ""
      for child in unorderedList.children {
        if let listItem = child as? ListItem {
          text += "• \(listItem.extractPlainText(removeHeading: removeHeading))\n"
        }
      }
      return text

    case let blockQuote as BlockQuote:
      var text = ""
      for child in blockQuote.children {
        text += child.extractPlainText(removeHeading: removeHeading)
      }
      return text

    case let table as Markdown.Table:
      var text = ""
      // Extract table headers
      for cell in table.head.children {
        if let tableCell = cell as? Markdown.Table.Cell {
          text += tableCell.extractPlainText(removeHeading: removeHeading) + "\t"
        }
      }
      text += "\n"

      // Extract table rows
      for row in table.body.children {
        if let tableRow = row as? Markdown.Table.Row {
          for cell in tableRow.children {
            if let tableCell = cell as? Markdown.Table.Cell {
              text += tableCell.extractPlainText(removeHeading: removeHeading) + "\t"
            }
          }
          text += "\n"
        }
      }
      return text

    case let tableCell as Markdown.Table.Cell:
      var text = ""
      for child in tableCell.children {
        text += child.extractPlainText(removeHeading: removeHeading)
      }
      return text

    case is ThematicBreak:
      return "---"

    case is Markdown.LineBreak:
      return "\n"

    case is Markdown.SoftBreak:
      return " "

    default:
      // For any other markup type, recursively process children
      var text = ""
      for child in children {
        text += child.extractPlainText(removeHeading: removeHeading)
      }
      return text
    }
  }
}
