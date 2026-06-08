//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import UIKit

extension UIColor {
  convenience init?(hex: String) {
    let normalized = hex
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "#", with: "")
      .replacingOccurrences(of: "0x", with: "")
      .replacingOccurrences(of: "0X", with: "")

    guard !normalized.isEmpty else {
      return nil
    }

    var value: UInt64 = 0
    guard Scanner(string: normalized).scanHexInt64(&value) else {
      return nil
    }

    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    switch normalized.count {
    case 3:
      red = CGFloat((value >> 8) & 0xF) / 15.0
      green = CGFloat((value >> 4) & 0xF) / 15.0
      blue = CGFloat(value & 0xF) / 15.0
      alpha = 1.0
    case 6:
      red = CGFloat((value >> 16) & 0xFF) / 255.0
      green = CGFloat((value >> 8) & 0xFF) / 255.0
      blue = CGFloat(value & 0xFF) / 255.0
      alpha = 1.0
    case 8:
      alpha = CGFloat((value >> 24) & 0xFF) / 255.0
      red = CGFloat((value >> 16) & 0xFF) / 255.0
      green = CGFloat((value >> 8) & 0xFF) / 255.0
      blue = CGFloat(value & 0xFF) / 255.0
    default:
      return nil
    }

    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }

  func toHexString(includeAlpha: Bool = false) -> String {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
      return "#000000"
    }

    let r = Int((red * 255.0).rounded())
    let g = Int((green * 255.0).rounded())
    let b = Int((blue * 255.0).rounded())

    if includeAlpha || alpha < 1.0 {
      let a = Int((alpha * 255.0).rounded())
      return String(format: "#%02X%02X%02X%02X", a, r, g, b)
    }

    return String(format: "#%02X%02X%02X", r, g, b)
  }
}
