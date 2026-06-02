//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import SwiftUI
import SwiftStreamingMarkdown

struct DemonstrationView: View {
  @AppStorage(SampleSettings.preferStreamedMarkdownKey) private var preferStreamedMarkdown = true
  @AppStorage(SampleSettings.appearanceModeKey) private var appearanceMode = AppearanceMode.device

  let demonstration: Demonstration
  let markdownText: String
  @StateObject var listener = LoggingMarkdownListener()
  @State private var pendingStreamingScroll = false
  @State private var followsStreamingMarkdown = true

  private static let streamBottomAnchorID = "stream-bottom-anchor"
  private static let streamingScrollAnimationDuration = 0.16

  private var streamedRenderConfig: MarkdownRenderConfig {
    let base: MarkdownRenderConfig
    switch demonstration {
    case .robotoTheme:
      base = RobotoTheme.renderConfig
    default:
      base = .default
    }
    return base
      .withTextContextMenu(value: demonstration.customContextMenu)
      .withShouldAnimateText(value: true)
  }

  private var nonStreamedRenderConfig: MarkdownRenderConfig {
    switch demonstration {
    case .robotoTheme: RobotoTheme.renderConfig
    default: .default
    }
  }

  private var backgroundColor: Color {
    switch demonstration {
    case .robotoTheme: RobotoTheme.pageBackground
    default: Color(.systemBackground)
    }
  }

  var body: some View {
    ScrollViewReader { scrollProxy in
      ScrollView {
        VStack(spacing: 0) {
          Group {
            if preferStreamedMarkdown {
              StreamedMarkdownView(
                text: markdownText,
                config: streamedRenderConfig,
                chunkInterval: 0.2,
                onStreamUpdate: {
                  scrollToStreamingBottom(with: scrollProxy)
                }
              ).environmentObject(listener)
            } else {
              MarkdownView(
                text: markdownText,
                config: nonStreamedRenderConfig,
                listener: listener
              )
            }
          }
          .padding(.horizontal, 16)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 16)

          Color.clear
            .frame(height: 1)
            .id(Self.streamBottomAnchorID)
        }
      }
    }
    .background(backgroundColor.ignoresSafeArea())
    .navigationTitle(demonstration.rawValue)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        if preferStreamedMarkdown {
          Button {
            followsStreamingMarkdown.toggle()
          } label: {
            Image(systemName: followsStreamingMarkdown ? "arrow.down.circle.fill" : "arrow.down.circle")
          }
          .accessibilityLabel(followsStreamingMarkdown ? "Disable follow scrolling" : "Enable follow scrolling")
        }

        Menu {
          Picker("Appearance", selection: $appearanceMode) {
            ForEach(AppearanceMode.allCases) { mode in
              Text(mode.displayName).tag(mode)
            }
          }
        } label: {
          Image(systemName: "circle.righthalf.filled")
            .accessibilityLabel("Appearance")
        }
      }
    }
  }

  private func scrollToStreamingBottom(with scrollProxy: ScrollViewProxy) {
    guard preferStreamedMarkdown, followsStreamingMarkdown else { return }
    guard !pendingStreamingScroll else { return }

    pendingStreamingScroll = true
    DispatchQueue.main.async {
      withAnimation(.linear(duration: Self.streamingScrollAnimationDuration)) {
        scrollProxy.scrollTo(Self.streamBottomAnchorID, anchor: .bottom)
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + Self.streamingScrollAnimationDuration) {
        pendingStreamingScroll = false
      }
    }
  }
}
