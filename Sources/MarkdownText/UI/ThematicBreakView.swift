//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftUI

struct ThematicBreakView: View {

  var body: some View {
    Divider()
      .foregroundColor(Color.Theme.Stroke.Default.Default300)
      .frame(height: 4)
      .padding([.top, .bottom], 8)
      .transition(.opacity)
  }
}
