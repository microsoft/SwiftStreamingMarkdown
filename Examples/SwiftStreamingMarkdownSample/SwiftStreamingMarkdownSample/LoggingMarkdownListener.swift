//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import UIKit
import SwiftStreamingMarkdown

class LoggingMarkdownListener: MarkdownListener, ObservableObject {
  func onRender(markdown: RenderableDocument, metadata: MarkdownMetadata?) async {
    print("[MarkdownListener] onRender(metadata: \(metadata.map { String(describing: $0) } ?? "nil"))")
  }

  func onTableCopyTap(content: String) async {
    UIPasteboard.general.string = content
    await presentCopyConfirmation()
  }

  func onTableDownloadTap(content: String) async {
    await presentShareSheet(for: content)
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
