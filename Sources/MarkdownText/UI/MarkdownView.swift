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
  private let horizontalPadding: CGFloat
  private let config: MarkdownRenderConfig
  @StateObject var controller: MarkdownViewController
  @Environment(\.colorScheme) private var colorScheme

  public init(
    text: String,
    horizontalPadding: CGFloat = 0,
    config: MarkdownRenderConfig = .default,
    listener: MarkdownListener? = nil
  ) {
    self.text = text
    self.horizontalPadding = horizontalPadding
    self.config = config
    _controller = StateObject(wrappedValue: MarkdownViewController(config: config, listener: listener))
  }

  public var body: some View {
    Group {
      if let renderable = controller.renderable {
        DocumentView(renderableDocument: renderable, horizontalPadding: horizontalPadding, config: config, listener: controller.listener)
      } else {
        DocumentView(renderableDocument: .empty, horizontalPadding: horizontalPadding, config: config, listener: controller.listener)
      }
    }
    .task(id: text) {
      await controller.parse(text: text, colorScheme: colorScheme)
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

  func parse(text: String, colorScheme: ColorScheme) async {
    let document = await parser.parse(text: text)
    let renderable = await RenderableDocument(document: document, config: config, colorScheme: colorScheme)
    await MainActor.run {
      self.renderable = renderable
    }
  }
}
