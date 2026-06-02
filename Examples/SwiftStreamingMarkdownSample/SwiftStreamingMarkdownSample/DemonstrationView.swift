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

  var body: some View {
    Group {
      if #available(iOS 18.0, *) {
        ScrollPositionStreamingView(listener: listener) {
          markdownContent
        }
      } else {
        ScrollViewReaderStreamingView(listener: listener) {
          markdownContent
        }
      }
    }
    .background(demonstration.backgroundColor.ignoresSafeArea())
    .onAppear {
      listener.isStreamingActive = preferStreamedMarkdown
    }
    .onChange(of: preferStreamedMarkdown) { isStreamed in
      listener.isStreamingActive = isStreamed
    }
    .navigationTitle(demonstration.rawValue)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        if preferStreamedMarkdown {
          Button {
            listener.followsStreamingMarkdown.toggle()
          } label: {
            Image(systemName: listener.followsStreamingMarkdown ? "arrow.down.circle.fill" : "arrow.down.circle")
          }
          .accessibilityLabel(listener.followsStreamingMarkdown ? "Disable follow scrolling" : "Enable follow scrolling")
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

  @ViewBuilder
  private var markdownContent: some View {
    Group {
      if preferStreamedMarkdown {
        StreamedMarkdownView(
          source: TextSimulatedStreamSource(
            text: markdownText,
            chunkSize: 48,
            chunkInterval: 0.2
          ),
          config: demonstration.streamedRenderConfig,
          listener: listener
        )
      } else {
        MarkdownView(
          text: markdownText,
          config: demonstration.nonStreamedRenderConfig,
          listener: listener
        )
      }
    }
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 16)
  }
}

private struct ScrollViewReaderStreamingView<Content: View>: View {
  @ObservedObject var listener: LoggingMarkdownListener
  let content: () -> Content
  private let streamingBottomID = "streaming-bottom"

  init(listener: LoggingMarkdownListener, @ViewBuilder content: @escaping () -> Content) {
    self.listener = listener
    self.content = content
  }

  var body: some View {
    ScrollViewReader { scrollProxy in
      ScrollView {
        VStack(spacing: 0) {
          content()

          Color.clear
            .frame(height: 1)
            .id(streamingBottomID)
        }
      }
      .onReceive(listener.$streamingScrollRequest) { request in
        guard request > 0 else { return }

        withAnimation(.linear(duration: LoggingMarkdownListener.streamingScrollAnimationDuration)) {
          scrollProxy.scrollTo(streamingBottomID, anchor: .bottom)
        }
      }
    }
  }
}

@available(iOS 18.0, *)
private struct ScrollPositionStreamingView<Content: View>: View {
  @ObservedObject var listener: LoggingMarkdownListener
  @State private var scrollPosition = ScrollPosition(edge: .top)
  let content: () -> Content

  init(listener: LoggingMarkdownListener, @ViewBuilder content: @escaping () -> Content) {
    self.listener = listener
    self.content = content
  }

  var body: some View {
    ScrollView {
      content()
    }
    .scrollPosition($scrollPosition)
    .onReceive(listener.$streamingScrollRequest) { request in
      guard request > 0 else { return }

      withAnimation(.linear(duration: LoggingMarkdownListener.streamingScrollAnimationDuration)) {
        scrollPosition.scrollTo(edge: .bottom)
      }
    }
  }
}
