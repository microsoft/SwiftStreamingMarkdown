//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(UIKit)
import SnapshotTesting
import SwiftUI
import XCTest

/// Device variant model needed for Snapshot testing

public struct IOSVariant {
  let title: DeviceName
  let snapshot: Snapshotting<UIViewController, UIImage>
  let colorScheme: ColorScheme
}

extension IOSVariant {
  var regionCode: String {
    "US"
  }

  var languageCode: String {
    "en"
  }

  var name: String {
    "\(title.rawValue)-\(colorScheme.description)-\(regionCode)-\(languageCode)"
  }
}

// MARK: - Convenience Extension

private extension ColorScheme {
  var description: String {
    switch self {
    case .light:
      return "light"
    case .dark:
      return "dark"
    @unknown default:
      fatalError()
    }
  }
}

extension IOSVariant {
  /// All snapshot devices in Portait mode

  enum Vertical {
    static func iPhone16(
      size: CGFloat? = nil,
      colorScheme: ColorScheme = .light,
      precision: Float = 1,
      perceptualPrecision: Float = 1
    ) -> IOSVariant {
      IOSVariant(
        title: .iPhone16,
        snapshot: .image(on: .init(config: ViewImageConfig.iPhone16(.portrait), height: size), precision: precision, perceptualPrecision: perceptualPrecision),
        colorScheme: colorScheme
      )
    }

    static func iPadPro11(
      size: CGFloat? = nil,
      colorScheme: ColorScheme = .light,
      precision: Float = 1,
      perceptualPrecision: Float = 1
    ) -> IOSVariant {
      IOSVariant(
        title: .iPadPro11,
        snapshot: .image(on: .init(config: .iPadPro11(.portrait), height: size), precision: precision, perceptualPrecision: perceptualPrecision),
        colorScheme: colorScheme
      )
    }
  }

  /// All snapshot devices in Landscape mode

  enum Horizontal {
    static func iPadPro11(
      size: CGFloat? = nil,
      colorScheme: ColorScheme = .light,
      precision: Float = 1,
      perceptualPrecision: Float = 1
    ) -> IOSVariant {
      IOSVariant(
        title: .iPadPro11Landscape,
        snapshot: .image(on: .init(config: .iPadPro11(.landscape), height: size), precision: precision, perceptualPrecision: perceptualPrecision),
        colorScheme: colorScheme
      )
    }
  }

  enum DeviceName: String {
    case iPhone16
    case iPadPro11
    case iPadPro11Landscape
  }
}

extension Collection where Element == IOSVariant {
  /// Standard device variant list – one iPhone light / dark, one iPad light / dark
  /// - Parameters:
  ///   - height: An optional height for the virtual device. If not provided, a default height will be used.
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. 98-99% mimics the precision of the human eye.
  ///     This parameter defaults to 1.0 for standard precision.
  /// - Returns: an array of device variants
  public static func standard(
    height: CGFloat? = nil,
    precision: Float = 1,
    perceptualPrecision: Float = 1.0
  ) -> [IOSVariant] {
    iPhoneOnly(
      height: height,
      precision: precision,
      perceptualPrecision: perceptualPrecision
    ) + iPadOnly(
      height: height,
      precision: precision,
      perceptualPrecision: perceptualPrecision
    )
  }

  /// Only iPhone variants (light and dark).
  /// - Parameters:
  ///   - height: An optional height for the virtual device. If not provided, a default height will be used.
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. 98-99% mimics the precision of the human eye.
  ///     This parameter defaults to 1.0 for standard precision.
  /// - Returns: an array of iPhone device variants
  public static func iPhoneOnly(
    height: CGFloat? = nil,
    precision: Float = 1,
    perceptualPrecision: Float = 1.0
  ) -> [IOSVariant] {
    [
      // iPhone 16, light
      IOSVariant.Vertical.iPhone16(
        size: height,
        colorScheme: .light,
        precision: precision,
        perceptualPrecision: perceptualPrecision
      ),
      // iPhone 16, dark
      IOSVariant.Vertical.iPhone16(
        size: height,
        colorScheme: .dark,
        precision: precision,
        perceptualPrecision: perceptualPrecision
      )
    ]
  }

  /// Only iPad variants (vertical/light, horizontal/dark).
  /// - Parameters:
  ///   - height: An optional height for the virtual device. If not provided, a default height will be used.
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. 98-99% mimics the precision of the human eye.
  ///     This parameter defaults to 1.0 for standard precision.
  /// - Returns: an array of iPad device variants
  public static func iPadOnly(
    height: CGFloat? = nil,
    precision: Float = 1,
    perceptualPrecision: Float = 1.0
  ) -> [IOSVariant] {
    [
      // iPad Pro 11 in portrait (light)
      IOSVariant.Vertical.iPadPro11(
        size: height,
        colorScheme: .light,
        precision: precision,
        perceptualPrecision: perceptualPrecision
      ),
      // iPad Pro 11 in landscape (dark)
      IOSVariant.Horizontal.iPadPro11(
        size: height,
        colorScheme: .dark,
        precision: precision,
        perceptualPrecision: perceptualPrecision
      )
    ]
  }
}
#endif
