//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI

#if os(iOS)

/// A zoomable, pannable image view supporting pinch-to-zoom, double-tap zoom,
/// and swipe-to-dismiss. Used by the built-in fullscreen image viewer.
struct PinchZoomView: View {
  static let dismissVelocity = 1500.0
  static let panVelocity = 500.0
  static let minZoomScale: CGFloat = 1.0
  static let maxZoomScale: CGFloat = 4.0
  static let doubleTapZoomScale: CGFloat = 2.0
  static let bounceDistance: CGFloat = 5
  static let elasticityFactor: CGFloat = 0.4

  @State private var scale: CGFloat = 1.0
  @GestureState private var activeScale: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var lastDragDist: CGSize = .zero
  @State private var imageSize: CGSize = .zero

  private var isScaled: Bool { scale > Self.minZoomScale }

  let image: Image
  let onSwipeToDismiss: () -> Void

  init(image: Image, onSwipeToDismiss: @escaping () -> Void) {
    self.image = image
    self.onSwipeToDismiss = onSwipeToDismiss
  }

  var body: some View {
    GeometryReader { geometry in
      image
        .resizable()
        .aspectRatio(contentMode: .fit)
        .scaleEffect(scale * activeScale)
        .offset(offset)
        .background(
          GeometryReader { proxy in
            Color.clear
              .onAppear {
                imageSize = proxy.size
              }
              .onChange(of: proxy.size) { newSize in
                imageSize = newSize
              }
          }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onTapGesture(count: 2) { location in
          handleDoubleTap(at: location, in: geometry)
        }
        .gesture(
          SimultaneousGesture(
            DragGesture()
              .onChanged { value in
                let deltaWidth = value.translation.width - lastDragDist.width
                let deltaHeight = value.translation.height - lastDragDist.height
                self.lastDragDist = value.translation
                let newOffset = CGSize(width: deltaWidth + self.offset.width, height: deltaHeight + self.offset.height)
                self.offset = elasticOffset(newOffset, geometry: geometry)
              }
              .onEnded { value in
                lastDragDist = .zero
                if !isScaled, value.velocity.height > Self.dismissVelocity {
                  onSwipeToDismiss()
                }

                if let newOffset = adjustPositionIfNeeded(containerSize: geometry.size) {
                  animateOffset(to: newOffset)
                } else if abs(value.velocity.width) > Self.panVelocity || abs(value.velocity.height) > Self.panVelocity {
                  panOffset(velocity: value.velocity, containerSize: geometry.size)
                }
              },
            MagnificationGesture()
              .updating($activeScale, body: { value, state, _ in
                state = value
              })
              .onEnded { value in
                let newScale = self.scale * value
                scale = min(max(newScale, Self.minZoomScale), Self.maxZoomScale)
                if let newOffset = adjustPositionIfNeeded(containerSize: geometry.size) {
                  animateOffset(to: newOffset)
                }
              }
          )
        )
    }
  }

  private func handleDoubleTap(at location: CGPoint, in geometry: GeometryProxy) {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      if scale > Self.minZoomScale {
        resetToOriginalSize()
      } else {
        scale = Self.doubleTapZoomScale

        let imageCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let tapOffset = CGSize(
          width: (imageCenter.x - location.x) * (scale - 1),
          height: (imageCenter.y - location.y) * (scale - 1)
        )
        offset = tapOffset
      }
    }
  }

  private func resetToOriginalSize() {
    withAnimation(.easeInOut(duration: 0.25)) {
      scale = Self.minZoomScale
      offset = .zero
    }
  }

  /// Calculate the maximum allowed offset for the current zoom scale.
  private func maxOffsets(containerSize: CGSize) -> CGSize {
    let actualImageWidth = imageSize.width * scale
    let actualImageHeight = imageSize.height * scale
    let horizontalThreshold = max(0, (actualImageWidth - containerSize.width) / 2)
    let verticalThreshold = max(0, (actualImageHeight - containerSize.height) / 2)
    return CGSize(width: horizontalThreshold, height: verticalThreshold)
  }

  private func elasticOffset(_ newOffset: CGSize, geometry: GeometryProxy) -> CGSize {
    let maxOffset = maxOffsets(containerSize: geometry.size)

    // Calculate elastic offset
    func applyElasticity(to value: CGFloat, max: CGFloat) -> CGFloat {
      if abs(value) <= max {
        return value
      } else {
        let excess = abs(value) - max
        let normalizedExcess = excess / Self.bounceDistance
        let dampingRatio: CGFloat
        if normalizedExcess <= 1.0 {
          // Use linear damping for short distances
          dampingRatio = Self.elasticityFactor * normalizedExcess * 0.6
        } else {
          // Use logarithmic damping for long distances
          dampingRatio = Self.elasticityFactor * (0.6 + 0.4 * log(normalizedExcess))
        }
        let dampedExcess = excess * dampingRatio
        return value < 0 ? -(max + dampedExcess) : (max + dampedExcess)
      }
    }

    return CGSize(
      width: applyElasticity(to: newOffset.width, max: maxOffset.width),
      height: applyElasticity(to: newOffset.height, max: maxOffset.height)
    )
  }

  private func animateOffset(to offset: CGSize) {
    withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
      self.offset = offset
    }
  }

  private func panOffset(velocity: CGSize, containerSize: CGSize) {
    let maxOffset = maxOffsets(containerSize: containerSize)
    let newOffsetX = max(-maxOffset.width, min(offset.width + velocity.width / 2 * 0.5, maxOffset.width))
    let newOffsetY = max(-maxOffset.height, min(offset.height + velocity.height / 2 * 0.5, maxOffset.height))
    withAnimation(.easeOut(duration: 0.5)) {
      self.offset = CGSize(width: newOffsetX, height: newOffsetY)
    }
  }

  private func adjustPositionIfNeeded(containerSize: CGSize) -> CGSize? {

    if !isScaled {
      if offset != .zero {
        return .zero
      } else {
        return nil
      }
    }

    let maxOffset = maxOffsets(containerSize: containerSize)
    if abs(offset.width) <= maxOffset.width && abs(offset.height) <= maxOffset.height {
      return nil
    }

    var resultOffset = offset

    if abs(offset.width) > maxOffset.width {
      if resultOffset.width > 0 {
        resultOffset.width -= abs(offset.width) - maxOffset.width
      } else {
        resultOffset.width += abs(offset.width) - maxOffset.width
      }
    }

    if abs(offset.height) > maxOffset.height {
      if resultOffset.height > 0 {
        resultOffset.height -= abs(offset.height) - maxOffset.height
      } else {
        resultOffset.height += abs(offset.height) - maxOffset.height
      }
    }

    if resultOffset != offset {
      return resultOffset
    }

    return nil
  }
}

#endif
