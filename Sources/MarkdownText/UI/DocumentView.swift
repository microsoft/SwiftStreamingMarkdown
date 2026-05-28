//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Equatable
import Markdown
import SwiftUI

@Equatable
public struct DocumentView: View {
  @Environment(\.colorScheme) var colorScheme

  @StateObject var controller: MarkdownController

  let renderableDocument: RenderableDocument
  let config: MarkdownRenderConfig

  public init(
    renderableDocument: RenderableDocument,
    config: MarkdownRenderConfig = .default,
    metaData: MarkdownMetadata? = nil,
    listener: MarkdownListener? = nil
  ) {
    self.renderableDocument = renderableDocument
    self.config = config
    self._controller = StateObject(wrappedValue: MarkdownController(listener: listener, metadata: metaData))
  }

  public var body: some View {
    BlockView(renderables: renderableDocument.renderables)
    .environment(\.markdownConfig, config)
    .environment(\.markdownController, controller)
    .task {
      controller.onAppear(markdown: renderableDocument)
    }
    .onChange(of: renderableDocument, perform: { md in
      controller.onChange(markdown: md)
    })
    .onDisappear {
      controller.onDisappear()
    }
  }
}

extension EnvironmentValues {
  @Entry public var markdownConfig: MarkdownRenderConfig = .default
  @Entry public var markdownController: MarkdownController?
  @Entry public var textContextMenu: TextContextMenu?
}

#if DEBUG

let text = """
 I found some resources that can help you compare gyms in your neighborhood. Here's a brief overview:

1. **The Ultimate Gym Guide** provides a comprehensive database of gyms where you can compare amenities, locations with pools, saunas, childcare, and more.
2. **Best Gyms Near Me** on Yelp lists gyms with a variety of classes, equipment, and amenities, from budget-friendly options to high-end gyms with all the bells and whistles.

You can visit these sites to get detailed information on membership prices and amenities for each gym. Remember to consider what's most important for your fitness routine when making your decision!
"""

#Preview {
  return MarkdownView(text: text)
}

#endif
