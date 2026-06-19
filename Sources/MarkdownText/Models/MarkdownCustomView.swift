//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftUI

/// A parsed custom Markdown block directive ready for app-provided rendering.
public struct MarkdownCustomBlock: Equatable, Sendable {
  /// Stable identifier derived from the parsed Markdown node.
  public let id: String
  /// Directive name, e.g. `Callout` for `@Callout(...)`.
  public let name: String
  /// Parsed directive arguments keyed by argument name. The first unnamed
  /// argument, if present, uses an empty string key.
  public let arguments: [String: String]
  /// Raw argument text exactly as exposed by swift-markdown.
  public let rawArguments: String
  /// Fallback Markdown content contained by the directive.
  public let content: RenderableDocument

  /// Create a custom block payload.
  public init(
    id: String,
    name: String,
    arguments: [String: String] = [:],
    rawArguments: String = "",
    content: RenderableDocument = .empty
  ) {
    self.id = id
    self.name = name
    self.arguments = arguments
    self.rawArguments = rawArguments
    self.content = content
  }
}

/// Content that can be handled by a custom view builder.
public enum MarkdownCustomView: Equatable, Sendable {
  /// A standard Markdown image.
  case image(MarkdownImage)
  /// A swift-markdown block directive.
  case block(MarkdownCustomBlock)
}

/// Type-erased app hook for replacing parsed Markdown payloads with SwiftUI views.
public struct MarkdownCustomViewBuilder: Hashable, @unchecked Sendable {
  private let id: String
  // swiftlint:disable:next no_anyview
  private let buildView: @MainActor @Sendable (MarkdownCustomView) -> AnyView?

  /// Create a custom view builder.
  /// - Parameters:
  ///   - id: Stable identity used for `MarkdownRenderConfig` equality.
  ///   - build: Returns a custom view for supported payloads, or `nil` to use
  ///     the renderer's default/fallback view.
  public init(
    id: String,
    // swiftlint:disable:next no_anyview
    build: @escaping @MainActor @Sendable (MarkdownCustomView) -> AnyView?
  ) {
    self.id = id
    self.buildView = build
  }

  @MainActor
  // swiftlint:disable:next no_anyview
  func view(for customView: MarkdownCustomView) -> AnyView? {
    buildView(customView)
  }

  public static func == (lhs: MarkdownCustomViewBuilder, rhs: MarkdownCustomViewBuilder) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
