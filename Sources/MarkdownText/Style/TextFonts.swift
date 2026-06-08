//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//
import Foundation
import UIKit
import SwiftUI

/// A bundle of font variants (normal/italic/bold/boldItalic) plus optional
/// preferred letter and line spacing values, used by `MarkdownRenderConfig`
/// to style a run of text.
public struct TextFonts: Hashable, Sendable {
  /// Regular variant. Always required.
  public let normal: UIFont
  /// Italic variant, or `nil` to fall back to `normal` for emphasis.
  public let italic: UIFont?
  /// Bold variant, or `nil` to fall back to `normal` for strong runs.
  public let bold: UIFont?
  /// Bold-italic variant, or `nil` to fall back to `bold` then `italic`.
  public let boldItalic: UIFont?
  /// Optional kerning override applied via `NSAttributedString.Key.kern`.
  public let preferredLetterSpacing: CGFloat?
  /// Optional preferred line height in points. When greater than the font's
  /// natural line height, the renderer adds the difference as line spacing.
  public let preferredLineHeight: CGFloat?

  /// Create a font set with explicit variants and optional spacing overrides.
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

  func italicize(font: UIFont) -> UIFont? {
    if font == bold || font == boldItalic {
      return self.boldItalic
    }
    return self.italic
  }

  func bold(font: UIFont) -> UIFont? {
    if font == italic || font == boldItalic {
      return self.boldItalic
    }
    return self.bold
  }
}

extension View {

  func font(_ font: TextFonts, bold: Bool = false, italic: Bool = false) -> some View {
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
