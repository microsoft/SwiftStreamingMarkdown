//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftUI

struct ThematicBreakView: View {

  @Environment(\.markdownConfig) var config: MarkdownRenderConfig

  var body: some View {
    Divider()
      .foregroundColor(config.thematicBreakColor)
      .frame(height: 4)
      .padding([.top, .bottom], 8)
      .transition(.opacity)
  }
}
