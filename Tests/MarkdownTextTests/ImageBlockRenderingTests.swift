//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import Markdown
import XCTest

@MainActor
final class ImageBlockRenderingTests: XCTestCase {

  private func url(_ string: String) -> URL {
    guard let url = URL(string: string) else {
      fatalError("Invalid test URL: \(string)")
    }
    return url
  }

  private func renderables(
    for text: String,
    imageSupport: Bool
  ) async -> [MarkdownRenderable] {
    await renderables(for: text, imageConfig: ImageConfig(enabled: imageSupport))
  }

  private func renderables(
    for text: String,
    imageConfig: ImageConfig
  ) async -> [MarkdownRenderable] {
    let parser = MarkdownParserImpl()
    let config = MarkdownRenderConfig(imageConfig: imageConfig)
    let document = await parser.parse(
      text: text,
      option: .init(speculativeRewrite: false, imageSupport: imageConfig.enabled)
    ).document
    return await RenderableDocument(document: document, config: config).renderables
  }

  func test_standalone_image_renders_as_paragraph_when_disabled() async {
    let renderables = await renderables(
      for: "![alt](https://example.com/a.png)",
      imageSupport: false
    )

    XCTAssertEqual(renderables.count, 1)
    guard case .paragraph = renderables[0] else {
      return XCTFail("Expected a paragraph when image support is disabled")
    }
  }

  func test_standalone_image_renders_as_image_block_when_enabled() async {
    let renderables = await renderables(
      for: "![alt](https://example.com/a.png)",
      imageConfig: ImageConfig(enabled: true, allowedImageTypes: [.remote(allowedDomains: [])])
    )

    XCTAssertEqual(renderables.count, 1)
    guard case .image(_, let data) = renderables[0] else {
      return XCTFail("Expected an image block when image support is enabled")
    }
    XCTAssertEqual(data.source, .remote(url("https://example.com/a.png")))
    XCTAssertEqual(data.alt, "alt")
  }

  func test_image_data_precomputes_domain_eligibility_from_config() async {
    let config = ImageConfig(
      enabled: true,
      allowedImageTypes: [.remote(allowedDomains: ["allowed.example"])]
    )

    let allowed = await renderables(
      for: "![alt](https://allowed.example/a.png)",
      imageConfig: config
    )
    guard case .image(_, let allowedData) = allowed.first else {
      return XCTFail("Expected an image block for the allowed domain")
    }
    XCTAssertEqual(allowedData.source, .remote(url("https://allowed.example/a.png")))

    let blocked = await renderables(
      for: "![alt](https://blocked.example/a.png)",
      imageConfig: config
    )
    guard case .image(_, let blockedData) = blocked.first else {
      return XCTFail("Expected an image block for the blocked domain")
    }
    XCTAssertNil(blockedData.source)
  }

  func test_assets_scheme_resolves_to_asset_catalog_when_permitted() async {
    let renderables = await renderables(
      for: "![alt](assets://Images/logo)",
      imageConfig: ImageConfig(enabled: true, allowedImageTypes: [.assetCatalog])
    )

    guard case .image(_, let data) = renderables.first else {
      return XCTFail("Expected an image block for the asset-catalog source")
    }
    XCTAssertEqual(data.source, .assetCatalog(name: "Images/logo"))
  }

  func test_assets_scheme_is_not_allowed_without_asset_catalog_type() async {
    let renderables = await renderables(
      for: "![alt](assets://Images/logo)",
      imageConfig: ImageConfig(enabled: true, allowedImageTypes: [.remote(allowedDomains: [])])
    )

    guard case .image(_, let data) = renderables.first else {
      return XCTFail("Expected an image block")
    }
    XCTAssertNil(data.source)
  }

  func test_relative_path_resolves_to_bundled_resource_when_permitted() async {
    let renderables = await renderables(
      for: "![alt](logo.png)",
      imageConfig: ImageConfig(enabled: true, allowedImageTypes: [.bundledResource])
    )

    guard case .image(_, let data) = renderables.first else {
      return XCTFail("Expected an image block for the bundled-resource source")
    }
    XCTAssertEqual(data.source, .bundledResource(fileName: "logo", ext: "png"))
  }

  func test_dot_slash_relative_path_strips_prefix_for_bundled_resource() async {
    let renderables = await renderables(
      for: "![alt](./logo.png)",
      imageConfig: ImageConfig(enabled: true, allowedImageTypes: [.bundledResource])
    )

    guard case .image(_, let data) = renderables.first else {
      return XCTFail("Expected an image block for the bundled-resource source")
    }
    XCTAssertEqual(data.source, .bundledResource(fileName: "logo", ext: "png"))
  }

  func test_nested_relative_path_is_invalid_for_bundled_resource() async {
    let renderables = await renderables(
      for: "![alt](Images/logo.png)",
      imageConfig: ImageConfig(enabled: true, allowedImageTypes: [.bundledResource])
    )

    guard case .image(_, let data) = renderables.first else {
      return XCTFail("Expected an image block")
    }
    XCTAssertNil(data.source)
  }

  func test_relative_path_without_extension_is_invalid_for_bundled_resource() async {
    let renderables = await renderables(
      for: "![alt](logo)",
      imageConfig: ImageConfig(enabled: true, allowedImageTypes: [.bundledResource])
    )

    guard case .image(_, let data) = renderables.first else {
      return XCTFail("Expected an image block")
    }
    XCTAssertNil(data.source)
  }

  func test_relative_path_is_not_allowed_without_bundled_resource_type() async {
    let renderables = await renderables(
      for: "![alt](logo.png)",
      imageConfig: ImageConfig(enabled: true, allowedImageTypes: [.assetCatalog])
    )

    guard case .image(_, let data) = renderables.first else {
      return XCTFail("Expected an image block")
    }
    XCTAssertNil(data.source)
  }

  func test_plain_http_url_is_never_resolved() async {
    let renderables = await renderables(
      for: "![alt](http://example.com/a.png)",
      imageConfig: ImageConfig(enabled: true, allowedImageTypes: [.remote(allowedDomains: [])])
    )

    guard case .image(_, let data) = renderables.first else {
      return XCTFail("Expected an image block")
    }
    XCTAssertNil(data.source)
  }

  func test_remote_url_is_not_allowed_with_only_asset_catalog_type() async {
    let renderables = await renderables(
      for: "![alt](https://example.com/a.png)",
      imageConfig: ImageConfig(enabled: true, allowedImageTypes: [.assetCatalog])
    )

    guard case .image(_, let data) = renderables.first else {
      return XCTFail("Expected an image block")
    }
    XCTAssertNil(data.source)
  }

  func test_image_mixed_with_text_is_split_into_blocks_when_enabled() async {
    let renderables = await renderables(
      for: "before ![alt](https://example.com/a.png) after",
      imageSupport: true
    )

    XCTAssertEqual(renderables.count, 3)
    guard case .paragraph = renderables[0] else {
      return XCTFail("Expected leading text paragraph")
    }
    guard case .image = renderables[1] else {
      return XCTFail("Expected the middle block to be an image")
    }
    guard case .paragraph = renderables[2] else {
      return XCTFail("Expected trailing text paragraph")
    }
  }
}
