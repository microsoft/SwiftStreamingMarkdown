//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI
import AsyncExtensions
import Equatable

/// A source of incremental Markdown text for `StreamedMarkdownView`.
///
/// Each value yielded by `text` is a *complete snapshot* of the Markdown
/// source so far (a growing prefix), not an incremental delta. The view
/// re-parses each snapshot and updates the rendered output.
public protocol StreamedMarkdownSource {
  var text: AnyAsyncSequence<String> { get }
}

/// A SwiftUI view that incrementally parses and renders streamed Markdown.
///
/// Provide a `StreamedMarkdownSource` whose `text` async sequence yields
/// progressively larger snapshots of the Markdown source; the view re-parses
/// on each emission and refreshes the rendered output.
@Equatable
public struct StreamedMarkdownView: View {

  private let config: MarkdownRenderConfig
  @StateObject private var controller: StreamedMarkdownController

  /// Create a `StreamedMarkdownView`.
  /// - Parameters:
  ///   - source: The streamed Markdown source. Each emission must be the
  ///     complete Markdown source so far, not an incremental delta.
  ///   - config: Render configuration. Defaults to `.default`.
  ///   - listener: Optional listener that receives render and interaction events.
  public init(
    source: StreamedMarkdownSource,
    config: MarkdownRenderConfig = .default,
    listener: MarkdownListener? = nil
  ) {
    self.config = config
    _controller = StateObject(
      wrappedValue: StreamedMarkdownController(source: source, config: config, listener: listener)
    )
  }

  public var body: some View {
    DocumentView(
      renderableDocument: controller.markdownToRender,
      config: config,
      listener: controller.listener
    )
    .task {
      controller.start()
    }
    .onDisappear {
      controller.end()
    }
  }
}

final class StreamedMarkdownController: ObservableObject {

  @Published var markdownToRender: RenderableDocument = .empty
  let config: MarkdownRenderConfig
  let listener: MarkdownListener?

  private let source: StreamedMarkdownSource
  private let parser = MarkdownParserImpl()
  private var task: Task<Void, Never>?

  init(
    source: StreamedMarkdownSource,
    config: MarkdownRenderConfig,
    listener: MarkdownListener? = nil
  ) {
    self.source = source
    self.config = config
    self.listener = listener
  }

  func start() {
    task?.cancel()
    task = Task { [weak self] in
      guard let self else { return }
      do {
        for try await text in self.source.text {
          if Task.isCancelled { return }
          let renderable = await self.parser.parse(text: text, config: self.config)
          if Task.isCancelled { return }
          await MainActor.run {
            self.markdownToRender = renderable
          }
        }
      } catch {
        // Stream terminated with an error; nothing further to render.
      }
    }
  }

  func end() {
    task?.cancel()
    task = nil
  }
}
