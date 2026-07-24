//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI

/// The placeholder shown when a block image fails to load.
struct BlockImageFailureView: View {

  var body: some View {
    Image(systemName: "photo.badge.exclamationmark")
      .imageScale(.large)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
  }
}
