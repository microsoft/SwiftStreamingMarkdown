//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

extension ImageConfig {

  /// Resolves a Markdown image source into a permitted `ImageData.Source`, or
  /// `nil` when the source is empty, malformed, or not allowed by the config.
  func resolvedSource(for rawSource: String?) -> ImageData.Source? {
    guard enabled, let rawSource, !rawSource.isEmpty,
      let url = URL.fromMixedEncodingString(rawSource) else {
      return nil
    }

    switch url.scheme?.lowercased() {
    case "https":
      guard allowsRemoteImage(host: url.host(percentEncoded: false)) else { return nil }
      return .remote(url)
    case "assets":
      guard allowsAssetCatalog, let name = url.assetCatalogName else { return nil }
      return .assetCatalog(name: name)
    case .some:
      // An explicit but unsupported scheme (e.g. `file`, `data`, plain `http`).
      return nil
    case .none:
      guard allowsBundledResource, let resource = rawSource.bundledResourceComponents else {
        return nil
      }
      return .bundledResource(fileName: resource.fileName, ext: resource.ext)
    }
  }

  /// Whether an `https` image served from `host` is permitted by a configured
  /// `.remote` type. The caller has already matched the `https` scheme, so only
  /// the host is validated against each type's `allowedDomains`.
  private func allowsRemoteImage(host: String?) -> Bool {
    guard let host = host?.lowercased() else { return false }
    for case .remote(let allowedDomains) in allowedImageTypes {
      guard !allowedDomains.isEmpty else { return true }
      let matches = allowedDomains.contains { domain in
        let domain = domain.lowercased()
        return host == domain || host.hasSuffix("." + domain)
      }
      if matches { return true }
    }
    return false
  }
}

private extension URL {

  /// The asset-catalog name for an `assets`-scheme URL, taken from its host and
  /// path (e.g. `assets://Images/logo` → `Images/logo`). `nil` when empty.
  var assetCatalogName: String? {
    let name = (host(percentEncoded: false) ?? "") + path(percentEncoded: false)
    return name.isEmpty ? nil : name
  }
}

private extension String {

  /// Splits a scheme-less relative path into a bundle resource's base file name
  /// and extension (e.g. `./logo.png` → (`logo`, `png`)). `nil` for nested
  /// paths or sources without a file extension.
  var bundledResourceComponents: (fileName: String, ext: String)? {
    let path = hasPrefix("./") ? String(dropFirst(2)) : self
    // Only a bare file name is supported; nested paths are invalid.
    guard !path.isEmpty, !path.contains("/") else { return nil }

    let fileName = (path as NSString).deletingPathExtension
    let ext = (path as NSString).pathExtension
    guard !fileName.isEmpty, !ext.isEmpty else { return nil }
    return (fileName, ext)
  }
}
