//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftStreamingMarkdown

final class LLMChatInteractor: ObservableObject {
  /// Shared render config, also handed to `DocumentView` so on-screen styling
  /// matches how each `RenderableDocument` was parsed.
  let markdownConfig = MarkdownRenderConfig.default
    .withShouldAnimateText(value: true)
    .withImageConfig(ImageConfig(
      enabled: true,
      allowedImageTypes: [.assetCatalog, .bundledResource]
    ))

  private let parser = MarkdownParserImpl()
  private var nextResponseIndex = 0

  /// Stream the greeting once, when the transcript is still empty.
  func loadGreetingIfNeeded(into viewModel: LLMChatViewModel) async {
    guard await viewModel.messages.isEmpty else { return }
    await streamAssistantReply(markdown: Self.greeting, into: viewModel)
  }

  /// Send the current draft as a user message and stream a rotating reply.
  func send(into viewModel: LLMChatViewModel) async {
    guard let text = await viewModel.consumeDraft() else { return }
    await viewModel.appendUserMessage(text)

    let response = Self.mockResponses[nextResponseIndex]
    nextResponseIndex = (nextResponseIndex + 1) % Self.mockResponses.count
    await streamAssistantReply(markdown: response, into: viewModel)
  }

  /// Simulate streaming by parsing progressively larger prefixes of `markdown`
  /// and updating the same assistant bubble in place as its content grows.
  private func streamAssistantReply(markdown: String, into viewModel: LLMChatViewModel) async {
    let messageID = await viewModel.appendAssistantMessage(.empty)

    let chunkSize = 3
    var endIndex = markdown.startIndex

    while endIndex < markdown.endIndex {
      if Task.isCancelled { return }

      endIndex = markdown.index(
        endIndex,
        offsetBy: chunkSize,
        limitedBy: markdown.endIndex
      ) ?? markdown.endIndex

      let snapshot = String(markdown[..<endIndex])
      let isComplete = endIndex == markdown.endIndex
      let document = await parser.parse(
        text: snapshot,
        config: markdownConfig,
        speculativeRewrite: !isComplete
      )
      await viewModel.updateAssistantMessage(id: messageID, document: document)

      if endIndex == markdown.endIndex { break }
      try? await Task.sleep(nanoseconds: 30_000_000)
    }
  }

  private static let greeting =
    "Hi! Ask me anything to see Markdown responses with rich content."

  private static let mockResponses = [
    """
    SwiftStreamingMarkdown is designed to render Markdown incrementally as an LLM response arrives. It supports headings, lists, tables, citations, code blocks, math, and more.

    You can learn more in the [project documentation](https://github.com/microsoft/SwiftStreamingMarkdown?citationMarker=9F742443&citationTitle=SwiftStreamingMarkdown&citationA11yValue=SwiftStreamingMarkdown%20GitHub%20repository&citationId=chat-doc-1&chatItemId=llm-chat).
    """,
    """
    Here is an image loaded from the sample app's asset catalog:

    ![A mountain lake surrounded by trees](assets://Images/mountain-lake)
    """,
    """
    A pre-parsed Markdown view only needs a few lines:

    ```swift
    import SwiftStreamingMarkdown
    import SwiftUI

    struct ResponseView: View {
      let document: RenderableDocument

      var body: some View {
        DocumentView(renderableDocument: document)
      }
    }
    ```
    """,
    """
    Here is a quick feature comparison:

    | Content | Supported |
    | --- | --- |
    | Text styles | Yes |
    | Code blocks | Yes |
    | Citations | Yes |
    | Images | Yes |
    """,
    """
    You can structure an answer with several Markdown elements:

    1. **Summarize** the request.
    2. Provide concise implementation details.
    3. Highlight identifiers such as `DocumentView`.

    > Mock responses rotate each time you send a message.
    """
  ]
}
