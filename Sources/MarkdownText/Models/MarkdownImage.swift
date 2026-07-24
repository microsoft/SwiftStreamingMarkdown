//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

/// The image payload delivered to `MarkdownListener.onImageTap(image:)` when a
/// user taps a block-level Markdown image.
///
/// - Important: Image support is **experimental**. See
///   `MarkdownRenderConfig.imageConfig`.
public struct MarkdownImage: Equatable, Sendable {

  /// The resolved source of a tapped image.
  public enum Source: Equatable, Sendable {
    /// A remote image loaded over `https`.
    case remote(URL)
    /// A bundled image resolved from the app's asset catalog by name.
    case assetCatalog(name: String)
    /// A loose image resource from the app's main bundle, delivered as its raw
    /// file bytes.
    case bundledResource(data: Data)
  }

  /// The resolved image source.
  public let source: Source

  /// The image's alternate text.
  public let alt: String

  /// Create an image payload.
  public init(source: Source, alt: String) {
    self.source = source
    self.alt = alt
  }
}
