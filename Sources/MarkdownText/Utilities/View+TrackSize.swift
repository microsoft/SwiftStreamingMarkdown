//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import SwiftUI

struct TrackSizeModifier: ViewModifier {

  let onChange: (CGSize) -> Void

  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { proxy in
          Color.clear
            .hidden()
            .onAppear {
              onChange(proxy.size)
            }
            .onChange(of: proxy.size) { newSize in
              onChange(newSize)
            }
        }
      )
  }
}

extension View {

  func onSizeChange(perform onChange: @escaping (CGSize) -> Void) -> some View {
    modifier(TrackSizeModifier(onChange: onChange))
  }

  func onHeightChange(perform onChange: @escaping (CGFloat) -> Void) -> some View {
    onSizeChange { size in onChange(size.height) }
  }

  func onWidthChange(perform onChange: @escaping (CGFloat) -> Void) -> some View {
    onSizeChange { size in onChange(size.width) }
  }
}
