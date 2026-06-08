//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import iosMath
import SwiftUI

struct BlockMathView: UIViewRepresentable {
  let latex: String
  let color: Color
  let pointSize: CGFloat

  init(latex: String, color: Color = Color.Theme.Foreground.Primary.Primary750, pointSize: CGFloat = Typography.base.uiFont.pointSize) {
    self.latex = latex
    self.color = color
    self.pointSize = pointSize
  }

  func makeUIView(context: Context) -> MTMathUILabel {
    let label = MTMathUILabel()
    label.latex = latex
    label.textColor = UIColor(color)
    label.displayErrorInline = false
    label.fontSize = pointSize
    label.setContentHuggingPriority(.defaultHigh, for: .vertical)
    return label
  }

  func updateUIView(_ uiView: MTMathUILabel, context: Context) {
    uiView.textColor = UIColor(color)
    uiView.latex = latex
  }

  func sizeThatFits(_ proposal: ProposedViewSize, uiView: MTMathUILabel, context: Context) -> CGSize? {
    uiView.sizeToFit()
    let size = uiView.bounds.size
    // It's a known issue that MTMathUILabel may be cut off for some short statement. Manually add 1 to the height fix it.
    return CGSize(width: size.width.rounded(.up), height: size.height.rounded(.up) + 1)
  }
}
