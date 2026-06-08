//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftUI

struct FadeInTextTransitionViewModifier: ViewModifier {

  @State private var show = false
  let config: FadeInTransitionConfig

  func body(content: Content) -> some View {
    if #available(iOS 18.0, *) {
      ZStack {
        if show {
          content
            .transition(config.asTransition)
        }
      }
      .onAppear {
        show = true
      }
    } else {
      content
        .transition(.opacity)
    }
  }
}

extension View {
  func fadeInTextTransition(config: FadeInTransitionConfig = .fixedDuration(duration: 2.0, glyphDelay: 0.02, glyphDuration: 0.2)) -> some View {
    modifier(FadeInTextTransitionViewModifier(config: config))
  }
}

enum FadeInTransitionConfig {
  case fixedDuration(duration: TimeInterval, glyphDelay: TimeInterval, glyphDuration: TimeInterval)
  case variableDuration(glyphCount: Int, glyphDelay: TimeInterval, glyphDuration: TimeInterval)

  @available(iOS 18.0, *)
  var asTransition: AnyTransition {
    switch self {
    case .fixedDuration(let duration, let glyphDelay, let glyphDuration):
      AnyTransition(FixedDurationFadeInTextTransition(duration: duration, glyphDelay: glyphDelay, glyphDuration: glyphDuration))
    case .variableDuration(let glyphCount, let glyphDelay, let glyphDuration):
      AnyTransition(VariableDurationFadeInTextTransition(totalGlyphs: glyphCount, glyphDelay: glyphDelay, glyphDuration: glyphDuration))
    }
  }
}

#if DEBUG

struct WrapperView: View {

  @State var text: String = "Welcome to Copilot!"
  @State var show: Bool = false

  var body: some View {
    VStack {
      if show {
        Text(text)
          .font(.largeTitle)
          .fadeInTextTransition()
      }
      Spacer()
    }
    .task {
      var count = 0
      while true {
        do {
          try await Task.sleep(ms: 4000)
        } catch {}
        show.toggle()
        count += 1
      }
    }
  }
}

#Preview("Text", body: {
  WrapperView()
})

#endif
