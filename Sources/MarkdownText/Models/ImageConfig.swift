//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

/// Configuration controlling whether and how Markdown images are rendered as
/// block-level content.
///
/// - Important: Image support is **experimental**. The behavior, API, and
///   rendering output may change in future releases.
public struct ImageConfig: Hashable, Sendable {

  /// A category of image source permitted while image rendering is enabled.
  public enum ImageType: Hashable, Sendable {
    /// Remote images loaded over `https`, restricted to the hosts in
    /// `allowedDomains`. Plain `http` is never permitted.
    ///
    /// An empty list permits any host. Matching is case-insensitive and
    /// includes subdomains, so `example.com` also matches `cdn.example.com`.
    ///
    /// Maps from sources with an `https` scheme, e.g.
    /// `![logo](https://example.com/logo.png)`.
    case remote(allowedDomains: [String])

    /// Bundled images resolved from the app's asset catalog by name via
    /// `Image(_:)`.
    ///
    /// Maps from sources with an `assets` scheme, where the asset name is the
    /// remainder of the source, e.g. `![logo](assets://Images/logo)` resolves
    /// the asset named `Images/logo`.
    case assetCatalog

    /// Bundled images resolved from a loose resource file in the app's main
    /// bundle by name.
    ///
    /// Maps from scheme-less relative paths, e.g. `![logo](logo.png)` or
    /// `![logo](./logo.png)`.
    case bundledResource
  }

  /// Whether Markdown images are rendered as block-level content.
  public let enabled: Bool

  /// The image sources permitted while `enabled` is `true`. An image whose
  /// source matches none of these types renders a placeholder instead.
  public let allowedImageTypes: [ImageType]

  /// Whether tapping a rendered image opens the built-in, zoomable fullscreen
  /// image viewer. Independent of `MarkdownListener.onImageTap(image:)`, which
  /// always fires on tap regardless of this flag.
  public let fullscreenViewerEnabled: Bool

  /// Create an image configuration.
  /// - Parameters:
  ///   - enabled: See `enabled`. Defaults to `false`.
  ///   - allowedImageTypes: See `allowedImageTypes`. Defaults to empty, which
  ///     permits no image sources.
  ///   - fullscreenViewerEnabled: See `fullscreenViewerEnabled`. Defaults to
  ///     `true`.
  public init(
    enabled: Bool = false,
    allowedImageTypes: [ImageType] = [],
    fullscreenViewerEnabled: Bool = true
  ) {
    self.enabled = enabled
    self.allowedImageTypes = allowedImageTypes
    self.fullscreenViewerEnabled = fullscreenViewerEnabled
  }

  /// Image support disabled.
  public static let disabled = ImageConfig(enabled: false)

  /// Whether bundled asset-catalog images are permitted under this config.
  var allowsAssetCatalog: Bool {
    guard enabled else { return false }
    return allowedImageTypes.contains { $0 == .assetCatalog }
  }

  /// Whether loose bundled resource images are permitted under this config.
  var allowsBundledResource: Bool {
    guard enabled else { return false }
    return allowedImageTypes.contains { $0 == .bundledResource }
  }
}
