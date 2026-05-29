//
//  Copyright © 2025 Microsoft. All rights reserved.
//
import Foundation
import UIKit

public struct TextFonts: Hashable, Sendable {
  public let normal: UIFont
  public let italic: UIFont?
  public let bold: UIFont?
  public let boldItalic: UIFont?
  public let preferredLetterSpacing: CGFloat?
  public let preferredLineHeight: CGFloat?

  public init(normal: UIFont, italic: UIFont?, bold: UIFont?, boldItalic: UIFont?, preferredLetterSpacing: CGFloat?, preferredLineHeight: CGFloat?) {
    self.normal = normal
    self.italic = italic
    self.bold = bold
    self.boldItalic = boldItalic
    self.preferredLetterSpacing = preferredLetterSpacing
    self.preferredLineHeight = preferredLineHeight
  }
}

extension TextFonts {
  
  public func italicize(font: UIFont) -> UIFont? {
    if font == bold || font == boldItalic {
      return self.boldItalic
    }
    return self.italic
  }
  
  public func bold(font: UIFont) -> UIFont? {
    if font == italic || font == boldItalic {
      return self.boldItalic
    }
    return self.bold
  }
}
