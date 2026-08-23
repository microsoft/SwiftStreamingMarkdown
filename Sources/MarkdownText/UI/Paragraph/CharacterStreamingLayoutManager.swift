//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(UIKit) || canImport(AppKit)
import CoreImage
import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct CharacterStreamingGlyphAnimationFrame: Equatable {
  let range: NSRange
  let transform: CharacterStreamingTransform
  let startTime: CFTimeInterval
}

struct CharacterStreamingGlyphBlend: Equatable {
  let blurredAlpha: CGFloat
  let sharpAlpha: CGFloat
  let blurRadius: CGFloat

  static func value(
    for transform: CharacterStreamingTransform
  ) -> CharacterStreamingGlyphBlend {
    let blurFraction = min(
      max(
        transform.blurRadius
          / ParagraphAnimationConstants.initialCharacterBlurRadius,
        0
      ),
      1
    )
    return CharacterStreamingGlyphBlend(
      blurredAlpha: transform.opacity * blurFraction,
      sharpAlpha: transform.opacity * (1 - blurFraction),
      blurRadius: transform.blurRadius
    )
  }
}

private struct CharacterStreamingGlyphImageSignature: Equatable {
  let range: NSRange
  let bounds: CGRect
  let scale: CGFloat
  let glyphs: [UInt32]
  let attributedString: NSAttributedString?

  static func == (
    lhs: CharacterStreamingGlyphImageSignature,
    rhs: CharacterStreamingGlyphImageSignature
  ) -> Bool {
    guard lhs.range == rhs.range,
          lhs.bounds == rhs.bounds,
          lhs.scale == rhs.scale,
          lhs.glyphs == rhs.glyphs else {
      return false
    }
    switch (lhs.attributedString, rhs.attributedString) {
    case (nil, nil):
      return true
    case let (lhs?, rhs?):
      return lhs.isEqual(to: rhs)
    default:
      return false
    }
  }
}

private struct CharacterStreamingGlyphImageCacheEntry {
  let signature: CharacterStreamingGlyphImageSignature
  let sourceImage: CGImage
  var blurredImages: [Int: CGImage] = [:]
}

private struct CharacterStreamingGlyphDrawingFrame {
  let range: NSRange
  let origin: CGPoint
  let bounds: CGRect
  let anchor: CGPoint
  let transform: CharacterStreamingTransform
  let backingScale: CGFloat
  let cacheID: CFTimeInterval
}

final class CharacterStreamingLayoutManager: NSLayoutManager {
  private static let blurContext = CIContext(
    options: [.cacheIntermediates: false]
  )
  private static let blurRadiusStep: CGFloat = 0.25
  private var animationFrames: [CharacterStreamingGlyphAnimationFrame] = []
  private var glyphImageCache: [
    CFTimeInterval: CharacterStreamingGlyphImageCacheEntry
  ] = [:]
  private(set) var renderedGlyphImageCount = 0

  var cachedGlyphImageCount: Int {
    glyphImageCache.count
  }

  var cachedBlurredImageCount: Int {
    glyphImageCache.values.reduce(0) {
      $0 + $1.blurredImages.count
    }
  }

  func updateAnimations(
    _ animations: [CharacterStreamingAnimation],
    at time: CFTimeInterval
  ) {
    updateAnimationFrames(animations.map {
      CharacterStreamingGlyphAnimationFrame(
        range: $0.range,
        transform: $0.transform(at: time),
        startTime: $0.startTime
      )
    })
  }

  func updateAnimationFrames(
    _ frames: [CharacterStreamingGlyphAnimationFrame]
  ) {
    let invalidatedRange = Self.unionRange(
      (animationFrames + frames).map(\.range)
    )
    animationFrames = frames
    let activeStartTimes = Set(frames.map(\.startTime))
    glyphImageCache = glyphImageCache.filter {
      activeStartTimes.contains($0.key)
    }
    if let invalidatedRange {
      invalidateDisplay(forCharacterRange: invalidatedRange)
    }
  }

  func clearAnimations() {
    let invalidatedRange = Self.unionRange(animationFrames.map(\.range))
    animationFrames.removeAll()
    glyphImageCache.removeAll()
    if let invalidatedRange {
      invalidateDisplay(forCharacterRange: invalidatedRange)
    }
  }

  override func drawGlyphs(
    forGlyphRange glyphsToShow: NSRange,
    at origin: CGPoint
  ) {
    guard !animationFrames.isEmpty else {
      super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
      return
    }

    let glyphFrames: [CharacterStreamingGlyphAnimationFrame] = animationFrames.compactMap { frame in
      let frameGlyphRange = glyphRange(
        forCharacterRange: frame.range,
        actualCharacterRange: nil
      )
      let visibleRange = NSIntersectionRange(frameGlyphRange, glyphsToShow)
      guard visibleRange.length > 0 else { return nil }
      return CharacterStreamingGlyphAnimationFrame(
        range: visibleRange,
        transform: frame.transform,
        startTime: frame.startTime
      )
    }
    let shapedClusters = Self.coalescedGlyphFrames(glyphFrames)
    var nextGlyphLocation = glyphsToShow.location
    let glyphEnd = NSMaxRange(glyphsToShow)

    for cluster in shapedClusters {
      if nextGlyphLocation < cluster.range.location {
        super.drawGlyphs(
          forGlyphRange: NSRange(
            location: nextGlyphLocation,
            length: cluster.range.location - nextGlyphLocation
          ),
          at: origin
        )
      }

      let transformedRange = NSIntersectionRange(
        cluster.range,
        NSRange(
          location: nextGlyphLocation,
          length: max(0, glyphEnd - nextGlyphLocation)
        )
      )
      if transformedRange.length > 0 {
        drawTransformedGlyphs(
          in: transformedRange,
          at: origin,
          frame: cluster
        )
        nextGlyphLocation = NSMaxRange(transformedRange)
      }
    }

    if nextGlyphLocation < glyphEnd {
      super.drawGlyphs(
        forGlyphRange: NSRange(
          location: nextGlyphLocation,
          length: glyphEnd - nextGlyphLocation
        ),
        at: origin
      )
    }
  }

  static func coalescedGlyphFrames(
    _ frames: [CharacterStreamingGlyphAnimationFrame]
  ) -> [CharacterStreamingGlyphAnimationFrame] {
    let sortedFrames = frames.sorted {
      if $0.range.location == $1.range.location {
        $0.startTime < $1.startTime
      } else {
        $0.range.location < $1.range.location
      }
    }
    var clusters: [CharacterStreamingGlyphAnimationFrame] = []
    for frame in sortedFrames {
      guard let last = clusters.last,
            NSIntersectionRange(last.range, frame.range).length > 0 else {
        clusters.append(frame)
        continue
      }
      let newest = frame.startTime >= last.startTime ? frame : last
      clusters[clusters.count - 1] = CharacterStreamingGlyphAnimationFrame(
        range: NSUnionRange(last.range, frame.range),
        transform: newest.transform,
        startTime: newest.startTime
      )
    }
    return clusters
  }

  static func unionRange(_ ranges: [NSRange]) -> NSRange? {
    ranges.reduce(nil) { result, range in
      result.map { NSUnionRange($0, range) } ?? range
    }
  }

  private func drawTransformedGlyphs(
    in glyphRange: NSRange,
    at origin: CGPoint,
    frame: CharacterStreamingGlyphAnimationFrame
  ) {
    guard let context = currentGraphicsContext(),
          let textContainer = textContainer(
            forGlyphAt: glyphRange.location,
            effectiveRange: nil
          ) else {
      super.drawGlyphs(forGlyphRange: glyphRange, at: origin)
      return
    }

    let bounds = boundingRect(
      forGlyphRange: glyphRange,
      in: textContainer
    ).offsetBy(dx: origin.x, dy: origin.y)
    let anchor = CGPoint(x: bounds.midX, y: bounds.maxY)
    let transform = frame.transform
    let blend = CharacterStreamingGlyphBlend.value(for: transform)
    let drawingFrame = CharacterStreamingGlyphDrawingFrame(
      range: glyphRange,
      origin: origin,
      bounds: bounds,
      anchor: anchor,
      transform: transform,
      backingScale: Self.backingScale(for: context),
      cacheID: frame.startTime
    )

    if blend.blurredAlpha > 0, blend.blurRadius > 0 {
      drawGlyphPass(
        drawingFrame,
        context: context,
        alpha: blend.blurredAlpha,
        blurRadius: blend.blurRadius
      )
    }
    if blend.sharpAlpha > 0 {
      drawGlyphPass(
        drawingFrame,
        context: context,
        alpha: blend.sharpAlpha,
        blurRadius: nil
      )
    }
  }

  private func drawGlyphPass(
    _ frame: CharacterStreamingGlyphDrawingFrame,
    context: CGContext,
    alpha: CGFloat,
    blurRadius: CGFloat?
  ) {
    context.saveGState()
    context.translateBy(
      x: 0,
      y: Self.baselineTranslation(frame.transform.baselineOffset)
    )
    context.translateBy(x: frame.anchor.x, y: frame.anchor.y)
    context.scaleBy(x: frame.transform.scale, y: frame.transform.scale)
    context.translateBy(x: -frame.anchor.x, y: -frame.anchor.y)

    if let blurRadius, blurRadius > 0 {
      drawBlurredGlyphs(
        in: frame.range,
        at: frame.origin,
        bounds: frame.bounds,
        radius: blurRadius,
        scale: frame.backingScale,
        cacheID: frame.cacheID,
        alpha: alpha
      )
    } else {
      context.setAlpha(alpha)
      super.drawGlyphs(forGlyphRange: frame.range, at: frame.origin)
    }

    context.restoreGState()
  }

  private func drawBlurredGlyphs(
    in glyphRange: NSRange,
    at origin: CGPoint,
    bounds: CGRect,
    radius: CGFloat,
    scale: CGFloat,
    cacheID: CFTimeInterval,
    alpha: CGFloat
  ) {
    let padding = ParagraphAnimationConstants.initialCharacterBlurRadius * 4
    let imageBounds = bounds.insetBy(dx: -padding, dy: -padding)
    guard imageBounds.width > 0,
          imageBounds.height > 0,
          let sourceImage = cachedGlyphImage(
            in: glyphRange,
            at: origin,
            bounds: imageBounds,
            scale: scale,
            cacheID: cacheID
          ) else {
      super.drawGlyphs(forGlyphRange: glyphRange, at: origin)
      return
    }

    let blurIndex = max(
      1,
      Int(ceil(radius / Self.blurRadiusStep))
    )
    let quantizedRadius = min(
      ParagraphAnimationConstants.initialCharacterBlurRadius,
      CGFloat(blurIndex) * Self.blurRadiusStep
    )
    guard let blurredImage = cachedBlurredImage(
      for: sourceImage,
      radius: quantizedRadius,
      scale: scale,
      cacheID: cacheID,
      blurIndex: blurIndex
    ) else {
      super.drawGlyphs(forGlyphRange: glyphRange, at: origin)
      return
    }

    #if canImport(UIKit)
    UIImage(
      cgImage: blurredImage,
      scale: scale,
      orientation: .up
    ).draw(
      in: imageBounds,
      blendMode: .normal,
      alpha: alpha
    )
    #elseif canImport(AppKit)
    NSImage(
      cgImage: blurredImage,
      size: imageBounds.size
    ).draw(
      in: imageBounds,
      from: .zero,
      operation: .sourceOver,
      fraction: alpha,
      respectFlipped: true,
      hints: nil
    )
    #endif
  }

  private func cachedGlyphImage(
    in glyphRange: NSRange,
    at origin: CGPoint,
    bounds: CGRect,
    scale: CGFloat,
    cacheID: CFTimeInterval
  ) -> CGImage? {
    let signature = glyphImageSignature(
      in: glyphRange,
      bounds: bounds,
      scale: scale
    )
    if let entry = glyphImageCache[cacheID],
       entry.signature == signature {
      return entry.sourceImage
    }
    guard let sourceImage = glyphImage(
      in: glyphRange,
      at: origin,
      bounds: bounds,
      scale: scale
    ) else {
      return nil
    }
    glyphImageCache[cacheID] = CharacterStreamingGlyphImageCacheEntry(
      signature: signature,
      sourceImage: sourceImage
    )
    return sourceImage
  }

  private func cachedBlurredImage(
    for sourceImage: CGImage,
    radius: CGFloat,
    scale: CGFloat,
    cacheID: CFTimeInterval,
    blurIndex: Int
  ) -> CGImage? {
    if let blurredImage = glyphImageCache[cacheID]?
      .blurredImages[blurIndex] {
      return blurredImage
    }

    let inputImage = CIImage(cgImage: sourceImage)
    guard let filter = CIFilter(name: "CIGaussianBlur") else {
      return nil
    }
    filter.setValue(inputImage, forKey: kCIInputImageKey)
    filter.setValue(radius * scale, forKey: kCIInputRadiusKey)
    guard let outputImage = filter.outputImage?.cropped(to: inputImage.extent),
          let blurredImage = Self.blurContext.createCGImage(
            outputImage,
            from: inputImage.extent
          ) else {
      return nil
    }
    glyphImageCache[cacheID]?.blurredImages[blurIndex] = blurredImage
    return blurredImage
  }

  private func glyphImageSignature(
    in glyphRange: NSRange,
    bounds: CGRect,
    scale: CGFloat
  ) -> CharacterStreamingGlyphImageSignature {
    let glyphs = (glyphRange.location..<NSMaxRange(glyphRange)).map {
      UInt32(glyph(at: $0))
    }
    let attributedString: NSAttributedString?
    if let textStorage {
      let characterRange = characterRange(
        forGlyphRange: glyphRange,
        actualGlyphRange: nil
      )
      attributedString = textStorage.attributedSubstring(
        from: characterRange
      )
    } else {
      attributedString = nil
    }
    return CharacterStreamingGlyphImageSignature(
      range: glyphRange,
      bounds: bounds,
      scale: scale,
      glyphs: glyphs,
      attributedString: attributedString
    )
  }

  private func glyphImage(
    in glyphRange: NSRange,
    at origin: CGPoint,
    bounds: CGRect,
    scale: CGFloat
  ) -> CGImage? {
    renderedGlyphImageCount += 1
    #if canImport(UIKit)
    let format = UIGraphicsImageRendererFormat()
    format.opaque = false
    format.scale = scale
    let image = UIGraphicsImageRenderer(
      size: bounds.size,
      format: format
    ).image { rendererContext in
      rendererContext.cgContext.translateBy(
        x: -bounds.minX,
        y: -bounds.minY
      )
      drawSourceGlyphs(in: glyphRange, at: origin)
    }
    return image.cgImage
    #elseif canImport(AppKit)
    let image = NSImage(size: bounds.size, flipped: true) { _ in
      guard let context = NSGraphicsContext.current?.cgContext else {
        return false
      }
      context.translateBy(x: -bounds.minX, y: -bounds.minY)
      self.drawSourceGlyphs(in: glyphRange, at: origin)
      return true
    }
    var proposedRect = CGRect(origin: .zero, size: bounds.size)
    return image.cgImage(
      forProposedRect: &proposedRect,
      context: nil,
      hints: nil
    )
    #endif
  }

  private func drawSourceGlyphs(
    in glyphRange: NSRange,
    at origin: CGPoint
  ) {
    super.drawGlyphs(forGlyphRange: glyphRange, at: origin)
  }

  private static func backingScale(for context: CGContext) -> CGFloat {
    let transform = context.ctm
    let xScale = hypot(transform.a, transform.c)
    let yScale = hypot(transform.b, transform.d)
    return max(1, max(xScale, yScale))
  }

  private func currentGraphicsContext() -> CGContext? {
    #if canImport(UIKit)
    UIGraphicsGetCurrentContext()
    #elseif canImport(AppKit)
    NSGraphicsContext.current?.cgContext
    #endif
  }

  static func baselineTranslation(_ offset: CGFloat) -> CGFloat {
    offset
  }
}
#endif
