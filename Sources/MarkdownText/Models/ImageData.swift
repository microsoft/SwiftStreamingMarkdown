//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import Markdown

/// The payload for an image-only block, promoted from a Markdown `Image` node
/// during pre-rendering.
///
/// - Important: Image support is **experimental**. See
///   `MarkdownRenderConfig.imageConfig`.
struct ImageData: Equatable, Sendable {

  /// A resolved image source that the active `ImageConfig` permits.
  enum Source: Equatable, Sendable {
    /// A remote image loaded asynchronously over `https`.
    case remote(URL)
    /// A bundled image resolved from the app's asset catalog by name.
    case assetCatalog(name: String)
    /// A loose image resource resolved from the app's main bundle by its base
    /// file name and extension (e.g. `logo.png` → `fileName: "logo"`,
    /// `ext: "png"`).
    case bundledResource(fileName: String, ext: String)
  }

  /// The permitted image source, or `nil` when the source is missing,
  /// unparseable, or not allowed by the config — in which case the view layer
  /// renders a placeholder. Precomputed during pre-rendering so the view does
  /// not evaluate eligibility in its body.
  let source: Source?

  /// The image's alternate text, used as the accessibility label.
  let alt: String

  init(source: Source?, alt: String) {
    self.source = source
    self.alt = alt
  }

  init(image: Markdown.Image, imageConfig: ImageConfig) {
    self.alt = image.plainText
    self.source = imageConfig.resolvedSource(for: image.source)
  }

  /// Builds the public tap payload for this image, or `nil` when the source is
  /// not resolvable. For bundled-resource images the raw file bytes are read
  /// off the main actor and passed along, so the listener receives the actual
  /// image data rather than an internal file reference. `controller` supplies
  /// the listener fallback used when the resource is absent from the main
  /// bundle.
  func makeMarkdownImage(controller: MarkdownController? = nil) async -> MarkdownImage? {
    guard let source else { return nil }
    switch source {
    case .remote(let url):
      return MarkdownImage(source: .remote(url), alt: alt)
    case .assetCatalog(let name):
      return MarkdownImage(source: .assetCatalog(name: name), alt: alt)
    case .bundledResource(let fileName, let ext):
      guard let data = await fileName.bundledResourceData(withExtension: ext, controller: controller) else {
        return nil
      }
      return MarkdownImage(source: .bundledResource(data: data), alt: alt)
    }
  }
}
