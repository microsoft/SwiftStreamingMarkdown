//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

/// All typography styles used by this package.
public enum Typography: CaseIterable, Sendable {
  case extraLargeStrong
  case extraLargeStrongItalic
  case extraLarge
  case extraLargeItalic

  case largeStrong
  case largeStrongItalic
  case large
  case largeItalic

  case mediumStrong
  case mediumStrongItalic
  case medium
  case mediumItalic

  case baseStrong
  case baseStrongItalic
  case baseItalic
  case base

  case smallStrong
  case smallStrongItalic
  case small
  case smallItalic

  case extraSmallStrong
  case extraSmallStrongItalic
  case extraSmall
  case extraSmallItalic

  case code
  case tripleExtraSmallCustom450

  /// The UIFont instance of the typography.
  public var uiFont: UIFont {
    return switch self {
    case .tripleExtraSmallCustom450: Self.systemFont(size: 10.0, weight: .regular)
    case .code: Self.systemMonospacedFont(size: 15.0, weight: .regular)

    case .extraLargeStrong: Self.systemFont(size: 28.0, weight: .semibold)
    case .extraLargeStrongItalic: Self.systemFont(size: 28.0, weight: .semibold, italic: true)
    case .extraLarge: Self.systemFont(size: 28.0, weight: .regular)
    case .extraLargeItalic: Self.systemFont(size: 28.0, weight: .regular, italic: true)

    case .largeStrong: Self.systemFont(size: 24.0, weight: .semibold)
    case .largeStrongItalic: Self.systemFont(size: 24.0, weight: .semibold, italic: true)
    case .large: Self.systemFont(size: 24.0, weight: .regular)
    case .largeItalic: Self.systemFont(size: 24.0, weight: .regular, italic: true)

    case .mediumStrong: Self.systemFont(size: 20.0, weight: .semibold)
    case .mediumStrongItalic: Self.systemFont(size: 20.0, weight: .semibold, italic: true)
    case .medium: Self.systemFont(size: 20.0, weight: .regular)
    case .mediumItalic: Self.systemFont(size: 20.0, weight: .regular, italic: true)

    case .baseStrong: Self.systemFont(size: 17.0, weight: .semibold)
    case .baseStrongItalic: Self.systemFont(size: 17.0, weight: .semibold, italic: true)
    case .baseItalic: Self.systemFont(size: 17.0, weight: .regular, italic: true)
    case .base: Self.systemFont(size: 17.0, weight: .regular)

    case .smallStrong: Self.systemFont(size: 15.0, weight: .semibold)
    case .smallStrongItalic: Self.systemFont(size: 15.0, weight: .semibold, italic: true)
    case .small: Self.systemFont(size: 15.0, weight: .regular)
    case .smallItalic: Self.systemFont(size: 15.0, weight: .regular, italic: true)

    case .extraSmallStrong: Self.systemFont(size: 14.0, weight: .semibold)
    case .extraSmallStrongItalic: Self.systemFont(size: 14.0, weight: .semibold, italic: true)
    case .extraSmall: Self.systemFont(size: 14.0, weight: .regular)
    case .extraSmallItalic: Self.systemFont(size: 14.0, weight: .regular, italic: true)
    }
  }

  private static func systemFont(size: CGFloat, weight: UIFont.Weight, italic: Bool = false) -> UIFont {
    let scaledSize = UIFontMetrics.default.scaledValue(for: size)
    let baseFont = UIFont.systemFont(ofSize: scaledSize, weight: weight)
    guard italic else {
      return baseFont
    }
    return baseFont.withItalicTrait()
  }

  private static func systemMonospacedFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
    let scaledSize = UIFontMetrics.default.scaledValue(for: size)
    return UIFont.monospacedSystemFont(ofSize: scaledSize, weight: weight)
  }

  /// The SwiftUI `Font` instance of the typography.
  public var font: Font {
    return Font(uiFont)
  }

  public static var extraLargeTextFonts: TextFonts {
    return TextFonts(
      normal: Typography.extraLarge.uiFont,
      italic: Typography.extraLargeItalic.uiFont,
      bold: Typography.extraLargeStrong.uiFont,
      boldItalic: Typography.extraLargeStrongItalic.uiFont,
      preferredLetterSpacing: -0.28,
      preferredLineHeight: 32.0
    )
  }

  public static var largeTextFonts: TextFonts {
    return TextFonts(
      normal: Typography.large.uiFont,
      italic: Typography.largeItalic.uiFont,
      bold: Typography.largeStrong.uiFont,
      boldItalic: Typography.largeStrongItalic.uiFont,
      preferredLetterSpacing: -0.24,
      preferredLineHeight: 32.0
    )
  }

  public static var mediumTextFonts: TextFonts {
    return TextFonts(
      normal: Typography.medium.uiFont,
      italic: Typography.mediumItalic.uiFont,
      bold: Typography.mediumStrong.uiFont,
      boldItalic: Typography.mediumStrongItalic.uiFont,
      preferredLetterSpacing: -0.2,
      preferredLineHeight: 26.0
    )
  }

  public static var baseTextFonts: TextFonts {
    return TextFonts(
      normal: Typography.base.uiFont,
      italic: Typography.baseItalic.uiFont,
      bold: Typography.baseStrong.uiFont,
      boldItalic: Typography.baseStrongItalic.uiFont,
      preferredLetterSpacing: 0.0,
      preferredLineHeight: 26.0
    )
  }

  public static var smallTextFonts: TextFonts {
    return TextFonts(
      normal: Typography.small.uiFont,
      italic: Typography.smallItalic.uiFont,
      bold: Typography.smallStrong.uiFont,
      boldItalic: Typography.smallStrongItalic.uiFont,
      preferredLetterSpacing: 0.0,
      preferredLineHeight: 20.0
    )
  }

  public static var extraSmallTextFonts: TextFonts {
    return TextFonts(
      normal: Typography.extraSmall.uiFont,
      italic: Typography.extraSmallItalic.uiFont,
      bold: Typography.extraSmallStrong.uiFont,
      boldItalic: Typography.extraSmallStrongItalic.uiFont,
      preferredLetterSpacing: 0.0,
      preferredLineHeight: 20.0
    )
  }

  public static var codeTextFonts: TextFonts {
    return TextFonts(
      normal: Typography.code.uiFont,
      italic: nil,
      bold: nil,
      boldItalic: nil,
      preferredLetterSpacing: -0.12,
      preferredLineHeight: 20.0
    )
  }
}

private extension UIFont {
  func withItalicTrait() -> UIFont {
    let traits = fontDescriptor.symbolicTraits.union(.traitItalic)
    guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
      return self
    }
    return UIFont(descriptor: descriptor, size: pointSize)
  }
}
