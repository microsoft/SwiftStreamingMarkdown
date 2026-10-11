//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if os(iOS)
@testable import SwiftStreamingMarkdown
import SwiftUI
import UIKit
import XCTest

@MainActor
final class ImageViewerTransitionTests: XCTestCase {
  func test_builtin_viewer_uses_native_zoom_transition() async throws {
    guard #available(iOS 18.0, *) else {
      throw XCTSkip("Native zoom transitions require iOS 18")
    }
    let controller = UIHostingController(rootView: ImageViewerFixture())
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
    window.rootViewController = controller
    window.isHidden = false
    defer {
      window.isHidden = true
      controller.dismiss(animated: false)
      window.rootViewController = nil
    }
    let presented = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in controller.presentedViewController != nil },
      object: controller
    )

    await fulfillment(of: [presented], timeout: 5)

    let viewer = try XCTUnwrap(controller.presentedViewController)
    XCTAssertNotNil(viewer.preferredTransition)
  }
}

private struct ImageViewerFixture: View {
  @Namespace private var namespace
  @State private var isPresented = true

  var body: some View {
    Image(systemName: "photo")
      .resizable()
      .frame(width: 200, height: 120)
      .matchedImageSource(namespace: namespace)
      .imageViewer(
        source: .bundledResource(fileName: "sample-landscape", ext: "png"),
        alt: "Landscape",
        isPresented: $isPresented,
        namespace: namespace
      )
      .environment(\.markdownController, MarkdownController(listener: TransitionResourceListener()))
  }
}

private extension View {
  @ViewBuilder
  func matchedImageSource(namespace: Namespace.ID) -> some View {
    if #available(iOS 18.0, *) {
      matchedTransitionSource(id: "image", in: namespace)
    } else {
      self
    }
  }
}

private final class TransitionResourceListener: MarkdownListener {
  func onRender(markdown: RenderableDocument) async {}
  func onTableCopyTap(content: String) async {}
  func onTableDownloadTap(content: String) async {}
  func onContextMenuAppear(id: String, selectedContent: String) async {}
  func onContextMenuTap(id: String, selectedContent: String) async {}
  func onImageTap(image: MarkdownImage) async {}

  func resolveBundledResource(fileName: String, ext: String?) -> URL? {
    Bundle.module.url(forResource: fileName, withExtension: ext)
  }
}
#endif
