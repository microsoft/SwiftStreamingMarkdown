//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI
import Equatable

/// This is a view that is able to both parse and render markdown with default configuration.
/// Use this view instead of `DocumentView` if you don't want to perform the parsing yourself.
@Equatable
public struct MarkdownView: View {

  private let text: String
  private let config: MarkdownRenderConfig
  @StateObject var controller: MarkdownViewController

  public init(
    text: String,
    config: MarkdownRenderConfig = .default,
    listener: MarkdownListener? = nil
  ) {
    self.text = text
    self.config = config
    _controller = StateObject(wrappedValue: MarkdownViewController(config: config, listener: listener))
  }

  public var body: some View {
    Group {
      if let renderable = controller.renderable {
        DocumentView(renderableDocument: renderable, config: config, listener: controller.listener)
      } else {
        DocumentView(renderableDocument: .empty, config: config, listener: controller.listener)
      }
    }
    .task(id: text) {
      await controller.parse(text: text)
    }
  }
}

public final class MarkdownViewController: ObservableObject {

  @Published var renderable: RenderableDocument?

  private let config: MarkdownRenderConfig
  private let parser = MarkdownParserImpl()
  
  let listener: MarkdownListener?

  public init(config: MarkdownRenderConfig = .default, listener: MarkdownListener? = nil) {
    self.config = config
    self.listener = listener
  }

  func parse(text: String) async {
    let document = await parser.parse(text: text)
    let renderable = await RenderableDocument(document: document, config: config)
    await MainActor.run {
      self.renderable = renderable
    }
  }
}
