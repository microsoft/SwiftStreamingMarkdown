//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import SwiftUI
import UIKit
import SwiftStreamingMarkdown

class LoggingMarkdownListener: MarkdownListener, ObservableObject {
  private static let streamingScrollAnimationDuration = 0.16

  @Published var followsStreamingMarkdown: Bool = true
  @Published var scrollPosition = ScrollPosition(edge: .top)
  /// Whether the current rendering context is a streamed source. When `false`,
  /// `onRender` callbacks will not auto-scroll, which lets the same listener
  /// be shared between streamed and static `MarkdownView`s without the static
  /// case yanking the scroll position on first render.
  @Published var isStreamingActive: Bool = false
  var viewModel: DemonstrationViewModel?
  private var pendingStreamingScroll = false

  func onRender(markdown: RenderableDocument) async {
    await viewModel?.recordRender()

    guard isStreamingActive else { return }
    if followsStreamingMarkdown && !pendingStreamingScroll {
      await scrollToStreamingBottom()
    }
  }

  @MainActor
  func toggleFollowScrolling() {
    followsStreamingMarkdown.toggle()
    if followsStreamingMarkdown {
      scrollToStreamingBottom(force: true)
    }
  }

  @MainActor
  func scrollToStreamingBottom(force: Bool = false) {
    guard followsStreamingMarkdown || force else { return }
    guard !pendingStreamingScroll || force else { return }

    pendingStreamingScroll = true
    DispatchQueue.main.async {
      withAnimation(.linear(duration: Self.streamingScrollAnimationDuration)) {
        self.scrollPosition.scrollTo(edge: .bottom)
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + Self.streamingScrollAnimationDuration) {
        self.pendingStreamingScroll = false
      }
    }
  }

  func onTableCopyTap(content: String) async {
    UIPasteboard.general.string = content
    await presentCopyConfirmation()
  }

  func onTableDownloadTap(content: String) async {
    await presentShareSheet(for: content)
  }

  func onContextMenuAppear(id: String, selectedContent: String) async {
    print("[MarkdownListener] onContextMenuAppear(id: \(id), selectedContent: \(selectedContent))")
  }

  func onContextMenuTap(id: String, selectedContent: String) async {
    print("[MarkdownListener] onContextMenuTap(id: \(id), selectedContent: \(selectedContent))")
  }

  @MainActor
  private func presentCopyConfirmation() {
    guard let presenter = topPresentingViewController() else {
      return
    }

    let alert = UIAlertController(
      title: "Copied",
      message: "Table content copied to clipboard.",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    presenter.present(alert, animated: true)
  }

  @MainActor
  private func presentShareSheet(for content: String) {
    guard let presenter = topPresentingViewController() else {
      return
    }

    let activityViewController = UIActivityViewController(
      activityItems: [content],
      applicationActivities: nil
    )

    if let popover = activityViewController.popoverPresentationController {
      popover.sourceView = presenter.view
      popover.sourceRect = CGRect(
        x: presenter.view.bounds.midX,
        y: presenter.view.bounds.midY,
        width: 0,
        height: 0
      )
      popover.permittedArrowDirections = []
    }

    presenter.present(activityViewController, animated: true)
  }

  @MainActor
  private func topPresentingViewController() -> UIViewController? {
    guard
      let scene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
      let rootViewController = scene.keyWindow?.rootViewController
    else {
      return nil
    }

    var presenter = rootViewController
    while let presented = presenter.presentedViewController {
      presenter = presented
    }
    return presenter
  }
}
