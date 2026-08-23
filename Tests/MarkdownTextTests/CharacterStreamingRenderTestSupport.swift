//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(UIKit) || canImport(AppKit)
import CoreGraphics

struct CharacterStreamingGlyphImageMetrics {
  let maximumAlpha: UInt8
  let faintPixelCount: Int
  let opaquePixelCount: Int
  let redPixelCount: Int
}

func characterStreamingGlyphImageMetrics(
  for image: CGImage
) -> CharacterStreamingGlyphImageMetrics {
  let width = image.width
  let height = image.height
  var pixels = [UInt8](repeating: 0, count: width * height * 4)
  pixels.withUnsafeMutableBytes { buffer in
    let context = CGContext(
      data: buffer.baseAddress,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: width * 4,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
    context?.draw(
      image,
      in: CGRect(x: 0, y: 0, width: width, height: height)
    )
  }

  var maximumAlpha: UInt8 = 0
  var faintPixelCount = 0
  var opaquePixelCount = 0
  var redPixelCount = 0
  for index in stride(from: 0, to: pixels.count, by: 4) {
    let red = pixels[index]
    let green = pixels[index + 1]
    let blue = pixels[index + 2]
    let alpha = pixels[index + 3]
    maximumAlpha = max(maximumAlpha, alpha)
    if alpha > 0, alpha < 64 {
      faintPixelCount += 1
    }
    if alpha > 192 {
      opaquePixelCount += 1
    }
    if alpha > 0, red > green, red > blue {
      redPixelCount += 1
    }
  }

  return CharacterStreamingGlyphImageMetrics(
    maximumAlpha: maximumAlpha,
    faintPixelCount: faintPixelCount,
    opaquePixelCount: opaquePixelCount,
    redPixelCount: redPixelCount
  )
}
#endif
