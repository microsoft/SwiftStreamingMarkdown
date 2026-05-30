//
//  Copyright © 2025 Microsoft. All rights reserved.
//
import Foundation
import UIKit
import SwiftUI

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


extension View {

  /// Set both the font and the preferred line height if different from the font's line height.
  /// - Parameter font: The font
  /// - Returns: The modified view
  public func font(_ font: TextFonts, bold: Bool = false, italic: Bool = false) -> some View {
    let fontToUse: UIFont?
    if bold && italic {
      fontToUse = font.boldItalic
    } else if bold {
      fontToUse = font.bold
    } else if italic {
      fontToUse = font.italic
    } else {
      fontToUse = font.normal
    }
    let letterSpacing = font.preferredLetterSpacing
    let extraLineSpacing: CGFloat? = font.preferredLineHeight.flatMap { lineHeight in
      lineHeight > font.normal.lineHeight ? lineHeight - font.normal.lineHeight : nil
    }
    return self
      .font(Font(fontToUse ?? font.normal))
      .if(letterSpacing != nil, content: { $0.kerning(letterSpacing ?? 0) })
      .if(extraLineSpacing != nil, content: { $0.lineSpacing(extraLineSpacing ?? 0) })
  }
}
