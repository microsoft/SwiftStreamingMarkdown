//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI

extension View {
  /// Presents the built-in fullscreen image viewer for a resolved image source.
  ///
  /// The viewer is an iOS-only feature; on other platforms this is a no-op.
  @ViewBuilder
  func imageViewer(
    source: ImageData.Source?,
    alt: String,
    isPresented: Binding<Bool>
  ) -> some View {
    #if os(iOS)
    fullScreenCover(isPresented: isPresented) {
      if let source {
        ImageViewerView(source: source, alt: alt) {
          isPresented.wrappedValue = false
        }
      }
    }
    #else
    self
    #endif
  }
}

#if os(iOS)

/// The built-in fullscreen image viewer presented when a user taps a rendered
/// block-level image and `ImageConfig.fullscreenViewerEnabled` is `true`.
///
/// Displays the image on a dimmed background inside a zoomable, pannable
/// `PinchZoomView`, with a close control and swipe-to-dismiss.
///
/// - Important: Image support is **experimental**. See
///   `MarkdownRenderConfig.imageConfig`.
struct ImageViewerView: View {

  let source: ImageData.Source
  let alt: String
  let onDismiss: () -> Void

  var body: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()

      zoomableImage
        .accessibilityLabel(alt.isEmpty ? Text(String.imageLabel) : Text(alt))

      dismissButton
    }
  }

  @ViewBuilder
  private var zoomableImage: some View {
    switch source {
    case .remote(let url):
      AsyncImage(url: url) { phase in
        switch phase {
        case .success(let image):
          PinchZoomView(image: image, onSwipeToDismiss: onDismiss)
        case .failure:
          BlockImageFailureView()
        case .empty:
          ProgressView()
            .tint(.white)
        @unknown default:
          BlockImageFailureView()
        }
      }
    case .assetCatalog(let name):
      PinchZoomView(image: Image(name), onSwipeToDismiss: onDismiss)
    case .bundledResource(let fileName, let ext):
      BundledResourceZoomView(fileName: fileName, ext: ext, onSwipeToDismiss: onDismiss)
    }
  }

  private var dismissButton: some View {
    VStack {
      HStack {
        Spacer()
        Button(action: onDismiss) {
          Image(systemName: "xmark")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(12)
            .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel(Text(String.imageViewerCloseLabel))
        .padding(16)
      }
      Spacer()
    }
  }
}

/// Loads a bundled resource image, then presents it inside a `PinchZoomView`.
private struct BundledResourceZoomView: View {

  let fileName: String
  let ext: String
  let onSwipeToDismiss: () -> Void

  @Environment(\.markdownController) private var controller
  @State private var image: MDImage?
  @State private var didLoad = false

  var body: some View {
    Group {
      if let image {
        PinchZoomView(image: Image(mdImage: image), onSwipeToDismiss: onSwipeToDismiss)
      } else if didLoad {
        BlockImageFailureView()
      } else {
        ProgressView()
          .tint(.white)
      }
    }
    .task {
      image = await fileName.bundledResourceImage(withExtension: ext, controller: controller)
      didLoad = true
    }
  }
}

#endif
