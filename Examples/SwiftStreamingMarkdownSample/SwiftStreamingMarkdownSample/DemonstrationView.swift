//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI
import SwiftStreamingMarkdown

struct DemonstrationView: View {
  @AppStorage(SampleSettings.preferStreamedMarkdownKey) private var preferStreamedMarkdown = true
  @AppStorage(SampleSettings.appearanceModeKey) private var appearanceMode = AppearanceMode.device
  @AppStorage(SampleSettings.markdownThemeKey) private var markdownTheme = SampleMarkdownTheme.automatic

  let demonstration: Demonstration
  let markdownText: String
  @StateObject var listener = LoggingMarkdownListener()
  @StateObject private var playback = StreamingPlaybackController()
  @StateObject private var performanceMetrics = StreamingPerformanceModel()
  @State private var isControlDrawerPresented = true
  @State private var isAtScrollBottom = true

  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 0) {
          Group {
            if preferStreamedMarkdown {
              StreamedMarkdownView(
                source: TextSimulatedStreamSource(
                  text: markdownText,
                  chunkSize: 48,
                  chunkInterval: 0.2,
                  playback: playback,
                  performanceMetrics: performanceMetrics
                ),
                config: demonstration.renderConfig(theme: markdownTheme, isStreaming: true),
                listener: listener
              )
              .id(streamedContentID)
            } else {
              MarkdownView(
                text: markdownText,
                config: demonstration.renderConfig(theme: markdownTheme, isStreaming: false),
                listener: listener
              )
              .id(staticContentID)
              .task(id: staticContentID) {
                await performanceMetrics.reset(totalCharacters: markdownText.count, mode: .staticMarkdown)
                await performanceMetrics.recordChunk(snapshotLength: markdownText.count, isFinal: true)
              }
            }
          }
          .padding(.horizontal, 28)
          .frame(maxWidth: 760, alignment: .leading)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 16)
          .padding(.bottom, isControlDrawerPresented ? 190 : 58)
          .background {
            GeometryReader { contentGeometry in
              Color.clear.preference(
                key: ScrollContentBottomPreferenceKey.self,
                value: contentGeometry.frame(in: .named(Self.scrollCoordinateSpaceName)).maxY
              )
            }
          }
        }
      }
      .coordinateSpace(name: Self.scrollCoordinateSpaceName)
      .onPreferenceChange(ScrollContentBottomPreferenceKey.self) { contentBottom in
        isAtScrollBottom = contentBottom <= geometry.size.height + 12
      }
    }
    .scrollPosition($listener.scrollPosition)
    .background(markdownTheme.backgroundColor(for: demonstration).ignoresSafeArea())
    .overlay(alignment: .bottom) {
      StreamingControlDrawerView(
        isPresented: $isControlDrawerPresented,
        playback: playback,
        performanceMetrics: performanceMetrics,
        listener: listener,
        isStreaming: preferStreamedMarkdown
      )
      .ignoresSafeArea(edges: .bottom)
    }
    .onAppear {
      listener.performanceMetrics = performanceMetrics
    }
    .onChange(of: preferStreamedMarkdown, initial: true) { _, isStreamed in
      listener.isStreamingActive = isStreamed
      if isStreamed {
        playback.play()
      }
    }
    .onChange(of: isControlDrawerPresented) { _, isPresented in
      guard isPresented && performanceMetrics.isComplete && isAtScrollBottom else { return }
      Task { @MainActor in
        try? await Task.sleep(nanoseconds: 80_000_000)
        listener.scrollToStreamingBottom(force: true)
      }
    }
    .navigationTitle(demonstration.rawValue)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        Menu {
          Picker("Markdown Theme", selection: $markdownTheme) {
            ForEach(SampleMarkdownTheme.allCases) { theme in
              Text(theme.displayName).tag(theme)
            }
          }

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

  private var streamedContentID: String {
    "\(demonstration.id)-\(markdownTheme.id)-\(playback.streamID)"
  }

  private var staticContentID: String {
    "\(demonstration.id)-\(markdownTheme.id)-static"
  }

  private static let scrollCoordinateSpaceName = "demonstration-scroll"
}

private struct ScrollContentBottomPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}
