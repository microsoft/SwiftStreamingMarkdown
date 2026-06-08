//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI

@available(iOS 18.0, *)
struct VariableDurationFadeInTextTransition: Transition {

  static var properties: TransitionProperties {
    TransitionProperties(hasMotion: true)
  }

  let totalGlyphs: Int
  let glyphDelay: TimeInterval
  let glyphDuration: TimeInterval

  let totalDuration: TimeInterval

  init(totalGlyphs: Int, glyphDelay: TimeInterval, glyphDuration: TimeInterval) {
    self.totalGlyphs = totalGlyphs
    self.glyphDelay = glyphDelay
    self.glyphDuration = glyphDuration
    self.totalDuration = max(0, Double(totalGlyphs - 1) * glyphDelay) + glyphDuration
  }

  func body(content: Content, phase: TransitionPhase) -> some View {
    let renderer = VariableDurationFadeInTextRenderer(elapsedTime: phase.isIdentity ? self.totalDuration : 0, glyphCount: totalGlyphs, glyphDelay: glyphDelay, glyphDuration: glyphDuration)
    content.transaction { transaction in
      if !transaction.disablesAnimations {
        transaction.animation = .linear(duration: self.totalDuration)
      }
    } body: { view in
      view.textRenderer(renderer)
    }
  }
}

@available(iOS 18.0, *)
struct FixedDurationFadeInTextTransition: Transition {
  static var properties: TransitionProperties {
    TransitionProperties(hasMotion: true)
  }

  let totalDuration: TimeInterval
  let glyphDelay: TimeInterval
  let glyphDuration: TimeInterval

  init(duration: TimeInterval, glyphDelay: TimeInterval, glyphDuration: TimeInterval) {
    self.totalDuration = duration
    self.glyphDelay = glyphDelay
    self.glyphDuration = glyphDuration
  }

  func body(content: Content, phase: TransitionPhase) -> some View {
    let renderer = FixedDurationFadeInTextRenderer(
      elapsedTime: phase.isIdentity ? self.totalDuration : 0,
      duration: self.totalDuration,
      delay: glyphDelay,
      animationDuration: glyphDuration
    )

    content.transaction { transaction in
      if !transaction.disablesAnimations {
        transaction.animation = .linear(duration: self.totalDuration)
      }
    } body: { view in
      view.textRenderer(renderer)
    }
  }
}

@available(iOS 18.0, *)
struct VariableDurationFadeInTextRenderer: TextRenderer, Animatable {

  var elapsedTime: TimeInterval

  var animatableData: Double {
    get { elapsedTime }
    set { elapsedTime = newValue }
  }

  let glyphCount: Int
  let glyphDelay: TimeInterval
  let glyphDuration: TimeInterval

  init(elapsedTime: TimeInterval, glyphCount: Int, glyphDelay: TimeInterval, glyphDuration: TimeInterval) {
    self.elapsedTime = elapsedTime
    self.glyphCount = glyphCount
    self.glyphDelay = glyphDelay
    self.glyphDuration = glyphDuration
  }

  func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
    for (index, slice) in layout.flattenedRunSlices.enumerated() {
      let normalizedX = min(max(0, elapsedTime - Double(index) * glyphDelay) / glyphDuration, 1)
      ctx.opacity = UnitCurve.easeOut.value(at: normalizedX)
      ctx.draw(slice, options: .disablesSubpixelQuantization)
    }
  }
}

@available(iOS 18.0, *)
struct FixedDurationFadeInTextRenderer: TextRenderer, Animatable {
  var elapsedTime: TimeInterval

  let duration: TimeInterval
  let delay: TimeInterval
  let animationDuration: TimeInterval

  private func opacityForGlyph(groupIndex: Int, totalGroups: Int) -> Double {
    let normalizedX = min(max(0, elapsedTime - Double(groupIndex) * delay) / animationDuration, 1)
    return UnitCurve.easeOut.value(at: normalizedX)
  }

  var animatableData: Double {
    get { elapsedTime }
    set { elapsedTime = newValue }
  }

  init(elapsedTime: TimeInterval, duration: TimeInterval, delay: TimeInterval, animationDuration: TimeInterval) {
    self.elapsedTime = elapsedTime
    self.duration = duration
    self.delay = delay
    self.animationDuration = animationDuration
  }

  func draw(layout: Text.Layout, in context: inout GraphicsContext) {
    let numberOfGlyphs = layout.flattenedRunSlices.count
    guard numberOfGlyphs > 0 else {
      return
    }

    let glyphGroups = Int(max(1, (duration - animationDuration) / delay).rounded(.up))

    for (index, slice) in layout.flattenedRunSlices.enumerated() {
      let groupIndex = index * glyphGroups / numberOfGlyphs
      let opacity = opacityForGlyph(groupIndex: groupIndex, totalGroups: glyphGroups)
      context.opacity = opacity
      context.draw(slice, options: .disablesSubpixelQuantization)
    }
  }
}

@available(iOS 18.0, *)
extension Text.Layout {
  /// A helper function for easier access to all runs in a layout.
  var flattenedRuns: some RandomAccessCollection<Text.Layout.Run> {
    self.flatMap { line in
      line
    }
  }

  /// A helper function for easier access to all run slices in a layout.
  var flattenedRunSlices: some RandomAccessCollection<Text.Layout.RunSlice> {
    flattenedRuns.flatMap(\.self)
  }
}
