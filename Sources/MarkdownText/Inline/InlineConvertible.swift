//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI

typealias NSAttributeContainer = [NSAttributedString.Key: Any]

extension NSAttributedString.Key {
  static let typography = NSAttributedString.Key("markdown.textFonts")
}

/// Have a inline Markdown node conform to this if it can be converted into an `AttributedString`

protocol InlineConvertible {

  /// Render into an attributed string
  /// - Parameter attributeContainer: The existing attribtues inherited from parent element
  /// - Parameter config: The mark down rendering config used to override fonts & text color if needed.
  /// - Parameter colorScheme: The color scheme of the view using. It's used to determine the font color during converstion.
  /// - Returns: The result attributed string
  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig, colorScheme: ColorScheme) -> NSMutableAttributedString
}

extension NSMutableAttributedString {
  func mergingAttributes(_ attributes: NSAttributeContainer) -> NSMutableAttributedString {
    addAttributes(attributes, range: NSRange(location: 0, length: length))
    return self
  }
}
