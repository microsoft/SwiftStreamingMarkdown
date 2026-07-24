//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

extension String {

  /// Loads a loose image resource, where `self` is the resource's base file
  /// name and `ext` its extension (e.g.
  /// `"logo".bundledResourceImage(withExtension: "png", controller: controller)`).
  ///
  /// As a nonisolated `async` method, this runs off the main actor, so the file
  /// read does not block rendering. Returns `nil` when the resource is missing
  /// or cannot be decoded.
  func bundledResourceImage(withExtension ext: String, controller: MarkdownController?) async -> MDImage? {
    guard let data = await bundledResourceData(withExtension: ext, controller: controller) else {
      return nil
    }
    return MDImage(data: data)
  }

  /// Reads the raw bytes of a loose image resource, where `self` is the
  /// resource's base file name and `ext` its extension.
  ///
  /// Resolution prefers the app's main bundle; when the resource is not found
  /// there, it falls back to `controller`'s listener via
  /// `MarkdownListener.resolveBundledResource(fileName:ext:)`.
  ///
  /// As a nonisolated `async` method, this runs off the main actor, so the file
  /// read does not block rendering. Returns `nil` when the resource cannot be
  /// resolved or is unreadable.
  func bundledResourceData(withExtension ext: String, controller: MarkdownController?) async -> Data? {
    guard let url = Bundle.main.url(forResource: self, withExtension: ext)
      ?? controller?.resolveBundledResource(fileName: self, ext: ext) else {
      return nil
    }
    return try? Data(contentsOf: url)
  }
}
