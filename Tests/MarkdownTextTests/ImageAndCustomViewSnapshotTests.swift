//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import SwiftUI
import XCTest

@MainActor
final class ImageAndCustomViewSnapshotTests: SnapshotTestCase {

  private let parser: MarkdownParser = MarkdownParserImpl()

  func testImageWithCustomViewBuilder() async throws {
    let config = MarkdownRenderConfig(
      customViewBuilder: MarkdownCustomViewBuilder(id: "snapshot-image-builder") { customView in
        guard case .image(let image) = customView else { return nil }
        return AnyView(SnapshotMarkdownImageView(image: image))
      }
    )
    let renderable = await parser.parse(
      text: "![Streaming Markdown sample](snapshot-image)",
      config: config
    )

    let view = CanvasView {
      DocumentView(renderableDocument: renderable, config: config)
        .padding(.horizontal, 24)
    }

    assert(view)
  }

  func testCustomBlockViewBuilder() async throws {
    let config = MarkdownRenderConfig(
      customViewBuilder: MarkdownCustomViewBuilder(id: "snapshot-callout-builder") { customView in
        guard case .block(let block) = customView, block.name == "Callout" else { return nil }
        return AnyView(SnapshotCalloutView(block: block))
      }
    )
    let renderable = await parser.parse(
      text: """
      @Callout(title: "Custom rendering", icon: "wand.and.stars") {
      This directive is rendered by a custom SwiftUI view.
      }
      """,
      config: config
    )

    let view = CanvasView {
      DocumentView(renderableDocument: renderable, config: config)
        .padding(.horizontal, 24)
    }

    assert(view)
  }
}

private struct SnapshotMarkdownImageView: View {
  let image: MarkdownImage

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      RoundedRectangle(cornerRadius: 8)
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.08, green: 0.24, blue: 0.36),
              Color(red: 0.44, green: 0.80, blue: 0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(height: 156)
        .overlay(alignment: .leading) {
          VStack(alignment: .leading, spacing: 8) {
            Text("# Markdown")
              .font(.system(size: 28, weight: .bold, design: .monospaced))
            Text("**streaming** `tokens`")
              .font(.system(size: 16, weight: .semibold, design: .monospaced))
          }
          .foregroundStyle(.white)
          .padding(20)
        }

      Text(image.alternativeText)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

private struct SnapshotCalloutView: View {
  let block: MarkdownCustomBlock

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Image(systemName: block.arguments["icon"] ?? "sparkles")
          .font(.system(size: 14, weight: .semibold))
        Text(block.arguments["title"] ?? block.name)
          .font(.headline)
      }

      Text(block.content.attributedStrings.map(\.string).joined(separator: " "))
        .font(.body)
    }
    .foregroundStyle(Color.Theme.Foreground.Primary.Primary750)
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.Theme.Overlay.Black.Black5)
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}
