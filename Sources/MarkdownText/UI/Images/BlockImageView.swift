//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftUI

/// Renders a block-level Markdown image, loaded asynchronously from a remote
/// URL, resolved from the app's asset catalog, or loaded from a bundled
/// resource file.
///
/// - Important: Image support is **experimental**. See
///   `MarkdownRenderConfig.imageConfig`.
struct BlockImageView: View {

  let data: ImageData

  @Environment(\.markdownController) private var controller
  @Environment(\.markdownConfig) private var config

  @State private var isViewerPresented = false

  var body: some View {
    imageContent
      .frame(maxWidth: .infinity, alignment: .center)
      .accessibilityLabel(data.alt.isEmpty ? Text(String.imageLabel) : Text(data.alt))
      .contentShape(Rectangle())
      .onTapGesture {
        handleTap()
      }
      .imageViewer(source: data.source, alt: data.alt, isPresented: $isViewerPresented)
  }

  private func handleTap() {
    guard data.source != nil else { return }
    if config.imageConfig.fullscreenViewerEnabled {
      isViewerPresented = true
    }
    Task {
      guard let image = await data.makeMarkdownImage(controller: controller) else { return }
      controller?.onImageTap(image: image)
    }
  }

  @ViewBuilder
  private var imageContent: some View {
    switch data.source {
    case .remote(let url):
      remoteImage(url: url)
    case .assetCatalog(let name):
      Image(name)
        .resizable()
        .scaledToFit()
    case .bundledResource(let fileName, let ext):
      BundledResourceImage(fileName: fileName, ext: ext)
    case nil:
      BlockImageFailureView()
    }
  }

  @ViewBuilder
  private func remoteImage(url: URL) -> some View {
    AsyncImage(url: url) { phase in
      switch phase {
      case .success(let image):
        image
          .resizable()
          .scaledToFit()
      case .failure:
        BlockImageFailureView()
      case .empty:
        BlockImageLoadingView()
      @unknown default:
        BlockImageFailureView()
      }
    }
  }
}
