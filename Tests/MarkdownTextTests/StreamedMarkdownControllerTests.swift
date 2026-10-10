//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import XCTest

@MainActor
final class StreamedMarkdownControllerTests: XCTestCase {

  private final class StubSource: StreamedMarkdownSource {
    let text: AsyncStream<String>

    init(stream: AsyncStream<String>) {
      self.text = stream
    }
  }

  private func makeStream() -> (AsyncStream<String>, AsyncStream<String>.Continuation) {
    return AsyncStream<String>.makeStream(of: String.self)
  }

  private func waitForRender(_ controller: StreamedMarkdownController) async {
    for _ in 0..<200 where controller.markdownToRender.renderables.isEmpty {
      try? await Task.sleep(ms: 5)
    }
  }

  func test_partial_trailing_strong_is_speculatively_closed_midstream() async {
    let (stream, continuation) = makeStream()
    let controller = StreamedMarkdownController(source: StubSource(stream: stream), config: .default)
    await controller.start()

    continuation.yield("Yeah, this is **cool")
    await waitForRender(controller)
    XCTAssertEqual(controller.markdownToRender.plainText, "Yeah, this is cool")

    continuation.yield("Yeah, this is **cooler**.")
    continuation.finish()
    await controller.task?.value
    XCTAssertEqual(controller.markdownToRender.plainText, "Yeah, this is cooler.")
    await controller.end()
  }

  func test_literal_trailing_marker_is_restored_when_stream_completes() async {
    let (stream, continuation) = makeStream()
    let controller = StreamedMarkdownController(source: StubSource(stream: stream), config: .default)
    await controller.start()

    // Mid-stream the trailing "*" is speculatively treated as emphasis.
    continuation.yield("2 * 3")
    await waitForRender(controller)
    XCTAssertEqual(controller.markdownToRender.plainText, "2  3")

    // Once the stream finishes the final snapshot re-renders literally.
    continuation.finish()
    await controller.task?.value
    XCTAssertEqual(controller.markdownToRender.plainText, "2 * 3")
    await controller.end()
  }

  func test_cancelled_controller_does_not_republish_on_stream_finish() async {
    let (stream, continuation) = makeStream()
    let controller = StreamedMarkdownController(source: StubSource(stream: stream), config: .default)
    await controller.start()

    continuation.yield("2 * 3")
    await waitForRender(controller)
    XCTAssertEqual(controller.markdownToRender.plainText, "2  3")

    await controller.end()
    continuation.finish()
    try? await Task.sleep(ms: 50)
    // The cancelled task must not publish the settled literal render.
    XCTAssertEqual(controller.markdownToRender.plainText, "2  3")
  }

  func test_partial_table_header_is_hidden_until_complete() async {
    let (stream, continuation) = makeStream()
    let controller = StreamedMarkdownController(source: StubSource(stream: stream), config: .default)
    await controller.start()

    continuation.yield("intro\n\n| Month | Savings |")
    await waitForRender(controller)
    XCTAssertTrue(controller.markdownToRender.plainText.contains("intro"))
    XCTAssertFalse(controller.markdownToRender.plainText.contains("Month"))

    continuation.yield("intro\n\n| Month | Savings |\n| ----- | ------- |\n| Jan | 100 |")
    continuation.finish()
    await controller.task?.value
    XCTAssertTrue(controller.markdownToRender.plainText.contains("Month"))
    await controller.end()
  }
}
