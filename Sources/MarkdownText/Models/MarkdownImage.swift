//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation

/// A parsed Markdown image ready for rendering.
public struct MarkdownImage: Equatable, Sendable {
  /// Stable identifier derived from the parsed Markdown node.
  public let id: String
  /// The image source from the Markdown destination.
  public let source: String
  /// Optional title from the Markdown image.
  public let title: String?
  /// Plain-text alternative text from the Markdown image label.
  public let alternativeText: String

  /// Create a parsed Markdown image payload.
  public init(id: String, source: String, title: String? = nil, alternativeText: String = "") {
    self.id = id
    self.source = source
    self.title = title
    self.alternativeText = alternativeText
  }
}
