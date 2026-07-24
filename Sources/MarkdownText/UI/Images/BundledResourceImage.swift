//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI

/// Loads and renders a loose image resource from the app's main bundle.
struct BundledResourceImage: View {

  let fileName: String
  let ext: String

  @Environment(\.markdownController) private var controller
  @State private var image: MDImage?
  @State private var didLoad = false

  var body: some View {
    Group {
      if let image {
        Image(mdImage: image)
          .resizable()
          .scaledToFit()
      } else if didLoad {
        BlockImageFailureView()
      } else {
        BlockImageLoadingView()
      }
    }
    .task {
      image = await fileName.bundledResourceImage(withExtension: ext, controller: controller)
      didLoad = true
    }
  }
}
