//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import XCTest

final class ImageTapTests: XCTestCase {

  private func url(_ string: String) -> URL {
    guard let url = URL(string: string) else {
      fatalError("Invalid test URL: \(string)")
    }
    return url
  }

  func test_makeMarkdownImage_maps_remote_and_asset_catalog_sources() async {
    let remote = await ImageData(
      source: ImageData.Source.remote(url("https://example.com/a.png")),
      alt: "a"
    ).makeMarkdownImage()
    XCTAssertEqual(remote, MarkdownImage(source: .remote(url("https://example.com/a.png")), alt: "a"))

    let asset = await ImageData(
      source: ImageData.Source.assetCatalog(name: "Images/logo"),
      alt: "b"
    ).makeMarkdownImage()
    XCTAssertEqual(asset, MarkdownImage(source: .assetCatalog(name: "Images/logo"), alt: "b"))
  }

  func test_makeMarkdownImage_is_nil_without_a_resolved_source() async {
    let payload = await ImageData(source: nil, alt: "d").makeMarkdownImage()
    XCTAssertNil(payload)
  }

  func test_makeMarkdownImage_is_nil_for_missing_bundled_resource() async {
    let payload = await ImageData(
      source: ImageData.Source.bundledResource(fileName: "does-not-exist", ext: "png"),
      alt: "c"
    ).makeMarkdownImage()
    XCTAssertNil(payload)
  }

  func test_makeMarkdownImage_resolves_bundled_resource_via_listener() async {
    let controller = MarkdownController(listener: BundleResourceListener(bundle: .module))
    let payload = await ImageData(
      source: ImageData.Source.bundledResource(fileName: "sample-landscape", ext: "png"),
      alt: "landscape"
    ).makeMarkdownImage(controller: controller)

    guard case .bundledResource(let bytes)? = payload?.source else {
      return XCTFail("Expected a bundled-resource payload resolved via the listener")
    }
    XCTAssertFalse(bytes.isEmpty)
  }

  func test_controller_forwards_image_tap_to_listener() async {
    let listener = RecordingMarkdownListener()
    let controller = MarkdownController(listener: listener)
    let image = MarkdownImage(source: MarkdownImage.Source.assetCatalog(name: "Images/logo"), alt: "logo")

    controller.onImageTap(image: image)

    let received = await listener.nextImageTap()
    XCTAssertEqual(received, image)
  }
}

/// Minimal `MarkdownListener` that records the last tapped image.
private actor RecordingMarkdownListener: MarkdownListener {

  private var tappedImage: MarkdownImage?
  private var continuation: CheckedContinuation<MarkdownImage, Never>?

  func nextImageTap() async -> MarkdownImage {
    if let tappedImage {
      return tappedImage
    }
    return await withCheckedContinuation { continuation in
      self.continuation = continuation
    }
  }

  nonisolated func onRender(markdown: RenderableDocument) async {}
  nonisolated func onTableCopyTap(content: String) async {}
  nonisolated func onTableDownloadTap(content: String) async {}
  nonisolated func onContextMenuAppear(id: String, selectedContent: String) async {}
  nonisolated func onContextMenuTap(id: String, selectedContent: String) async {}

  func onImageTap(image: MarkdownImage) async {
    if let continuation {
      self.continuation = nil
      continuation.resume(returning: image)
    } else {
      tappedImage = image
    }
  }
}

/// Minimal `MarkdownListener` that resolves bundled resources from a specific
/// bundle, standing in for a dependency package or framework bundle.
private final class BundleResourceListener: MarkdownListener {

  let bundle: Bundle

  init(bundle: Bundle) {
    self.bundle = bundle
  }

  func onRender(markdown: RenderableDocument) async {}
  func onTableCopyTap(content: String) async {}
  func onTableDownloadTap(content: String) async {}
  func onContextMenuAppear(id: String, selectedContent: String) async {}
  func onContextMenuTap(id: String, selectedContent: String) async {}
  func onImageTap(image: MarkdownImage) async {}

  func resolveBundledResource(fileName: String, ext: String?) -> URL? {
    bundle.url(forResource: fileName, withExtension: ext)
  }
}
