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
  public let preferredLetterSpacing: CGFloat
  public let preferredLineHeight: CGFloat
}

extension TextFonts {
  
  public func italicize(font: UIFont) -> UIFont? {
    if font == bold {
      return self.boldItalic
    }
    return self.italic
  }
  
  public func bold(font: UIFont) -> UIFont? {
    if font == italic {
      return self.boldItalic
    }
    return self.bold
  }
}
