//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(AppKit)
import SwiftUI

struct ParagraphView: NSViewRepresentable {
  @Environment(\.openURL) var openURL
  @Environment(\.markdownConfig) var config: MarkdownRenderConfig
  @Environment(\.markdownController) var markdownController: MarkdownController?

  var contents: NSMutableAttributedString
  var lineSpacing: CGFloat?

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeNSView(context: Context) -> ParagraphNSView {
    let openUrlFunction = openURL.callAsFunction(_:)
    // Do not reuse paragraph views on macOS. Reused NSTextView instances can retain
    // stale attachment subviews (e.g. LaTeX views vended by LatexViewProvider) from a
    // previously displayed document, which then render at the wrong positions. Each
    // paragraph gets its own view instead.
    let view = ParagraphNSView()
    view.onUrlTap = openUrlFunction
    view.setParagraphContents(contents, lineSpacing: lineSpacing, animatedByWord: false)
    view.setTextContextMenu(config.resolvedTextContextMenu)
    view.setMarkdownController(markdownController)

    if config.shouldAnimateText {
      view.alphaValue = 0
      NSAnimationContext.runAnimationGroup { ctx in
        ctx.duration = ParagraphNSView.animationDuration
        view.animator().alphaValue = 1
      }
    }

    return view
  }

  func updateNSView(_ view: ParagraphNSView, context: Context) {
    if view.paragraphContents != contents || view.lineSpacing != lineSpacing {
      let shouldAnimate = view.window != nil && config.shouldAnimateText
      view.setParagraphContents(contents, lineSpacing: lineSpacing, animatedByWord: shouldAnimate)
    }
    view.setTextContextMenu(config.resolvedTextContextMenu)
    view.setMarkdownController(markdownController)
  }

  func sizeThatFits(_ proposal: ProposedViewSize, nsView: ParagraphNSView, context: Context) -> CGSize? {
    guard let width = proposal.width, width > 0, width.isFinite else {
      return nil
    }

    if contents != context.coordinator.lastContents || lineSpacing != context.coordinator.lastLineSpacing {
      context.coordinator.sizeCache.removeAll()
      context.coordinator.lastContents = contents
      context.coordinator.lastLineSpacing = lineSpacing
    }

    let cacheKey = (width * 10).rounded() / 10

    if let cachedSize = context.coordinator.sizeCache[cacheKey] {
      return cachedSize
    }

    let calculatedSize = nsView.measureSize(fittingWidth: width)

    context.coordinator.sizeCache[cacheKey] = calculatedSize
    return calculatedSize
  }

  class Coordinator {
    var sizeCache: [CGFloat: CGSize] = [:]
    var lastContents: NSMutableAttributedString?
    var lastLineSpacing: CGFloat?
  }
}

extension ParagraphView: Equatable {
  static func == (lhs: ParagraphView, rhs: ParagraphView) -> Bool {
    lhs.contents.isEqual(to: rhs.contents) && lhs.lineSpacing == rhs.lineSpacing
  }
}
#endif
