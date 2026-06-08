//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import CoreGraphics
import SnapshotTesting
import UIKit

/// Convenience initializer catering for optional height

extension ViewImageConfig {
  init(config: ViewImageConfig, height: CGFloat?) {
    self.init(
      safeArea: config.safeArea,
      size: CGSize(width: config.size?.width, height: height) ?? config.size,
      traits: config.traits
    )
  }

  public static let iPhone16 = ViewImageConfig.iPhone16(.portrait)

  public static func iPhone16(_ orientation: Orientation) -> ViewImageConfig {
    let safeArea: UIEdgeInsets
    let size: CGSize
    switch orientation {
    case .landscape:
      safeArea = .init(top: 0, left: 59, bottom: 21, right: 59)
      size = .init(width: 852, height: 393)
    case .portrait:
      safeArea = .init(top: 59, left: 0, bottom: 34, right: 0)
      size = .init(width: 393, height: 852)
    }

    return .init(
      safeArea: safeArea, size: size, traits: UITraitCollection.iPhone16(orientation))
  }
}

/// UITraitCollection extension for iPhone 16

extension UITraitCollection {
  public static func iPhone16(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
    let base: [UITraitCollection] = [
      .init(displayScale: 3.0),
      .init(horizontalSizeClass: .compact),
      .init(userInterfaceIdiom: .phone),
      .init(userInterfaceStyle: .light)
    ]

    switch orientation {
    case .portrait:
      return .init(traitsFrom: base + [.init(verticalSizeClass: .regular)])
    case .landscape:
      return .init(traitsFrom: base + [.init(verticalSizeClass: .compact)])
    }
  }
}

/// Convenience failable CGSize initializer

private extension CGSize {
  init?(width: CGFloat?, height: CGFloat?) {
    guard let width = width, let height = height else { return nil }
    self.init(width: width, height: height)
  }
}
