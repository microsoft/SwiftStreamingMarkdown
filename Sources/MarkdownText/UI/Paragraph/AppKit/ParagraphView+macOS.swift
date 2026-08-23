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
  @Environment(\.accessibilityReduceMotion) var reduceMotion
  @Environment(\.isMarkdownStreamComplete) var isStreamComplete
  @Environment(\.isMarkdownStreamingTailBranch) var isStreamingTailBranch

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
    let view = ParagraphNSView(
      characterStreaming: config.textAnimation == .characterStreaming
    )
    view.onUrlTap = openUrlFunction
    view.setParagraphContents(
      contents,
      lineSpacing: lineSpacing,
      textAnimation: resolvedAnimation,
      isStreamComplete: paragraphStreamComplete
    )
    view.setTextContextMenu(config.resolvedTextContextMenu)
    view.setMarkdownController(markdownController)

    return view
  }

  func updateNSView(_ view: ParagraphNSView, context: Context) {
    if view.paragraphContents != contents || view.lineSpacing != lineSpacing {
      view.setParagraphContents(
        contents,
        lineSpacing: lineSpacing,
        textAnimation: view.window == nil ? .none : resolvedAnimation,
        isStreamComplete: paragraphStreamComplete
      )
    } else {
      view.setParagraphContents(
        contents,
        lineSpacing: lineSpacing,
        textAnimation: resolvedAnimation,
        isStreamComplete: paragraphStreamComplete
      )
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

    let cacheKey = ParagraphSizeCacheKey(
      width: (width * 10).rounded() / 10,
      visibleUTF16Length: nsView.textStorage?.length ?? 0
    )
    context.coordinator.updateVisibleUTF16Length(
      nsView.textStorage?.length ?? 0
    )

    if let cachedSize = context.coordinator.sizeCache[cacheKey] {
      return cachedSize
    }

    let calculatedSize = nsView.measureSize(fittingWidth: width)

    context.coordinator.sizeCache[cacheKey] = calculatedSize
    return calculatedSize
  }

  class Coordinator {
    var sizeCache: [ParagraphSizeCacheKey: CGSize] = [:]
    var lastContents: NSMutableAttributedString?
    var lastLineSpacing: CGFloat?
    private(set) var lastVisibleUTF16Length: Int?

    func updateVisibleUTF16Length(_ length: Int) {
      guard lastVisibleUTF16Length != length else { return }
      sizeCache.removeAll()
      lastVisibleUTF16Length = length
    }
  }

  private var resolvedAnimation: MarkdownRenderConfig.TextAnimation {
    resolvedTextAnimation(config.textAnimation, reduceMotion: reduceMotion)
  }

  private var paragraphStreamComplete: Bool {
    isStreamComplete || !isStreamingTailBranch
  }
}

extension ParagraphView: Equatable {
  static func == (lhs: ParagraphView, rhs: ParagraphView) -> Bool {
    lhs.contents.isEqual(to: rhs.contents)
      && lhs.lineSpacing == rhs.lineSpacing
  }
}
#endif
