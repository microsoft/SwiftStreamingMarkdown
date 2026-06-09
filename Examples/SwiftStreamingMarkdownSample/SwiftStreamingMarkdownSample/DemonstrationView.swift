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
  @StateObject private var viewModel: DemonstrationViewModel

  init(demonstration: Demonstration, markdownText: String) {
    self.demonstration = demonstration
    self.markdownText = markdownText
    _viewModel = StateObject(wrappedValue: DemonstrationViewModel(text: markdownText))
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        Group {
          if preferStreamedMarkdown {
            StreamedMarkdownView(
              source: viewModel,
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
              await viewModel.reset(totalCharacters: markdownText.count, mode: .staticMarkdown)
              await viewModel.recordChunk(snapshotLength: markdownText.count, isFinal: true)
            }
          }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: 760, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 16)
        .padding(.bottom, viewModel.isControlDrawerPresented ? 190 : 58)
      }
    }
    .onScrollGeometryChange(for: Bool.self) { geometry in
      let distanceFromBottom =
        geometry.contentSize.height
        - geometry.contentOffset.y
        - geometry.containerSize.height
      return distanceFromBottom <= 12
    } action: { _, isAtBottom in
      viewModel.isAtScrollBottom = isAtBottom
    }
    .scrollPosition($listener.scrollPosition)
    .background(markdownTheme.backgroundColor(for: demonstration).ignoresSafeArea())
    .overlay(alignment: .bottom) {
      StreamingControlDrawerView(
        viewModel: viewModel,
        listener: listener,
        isStreaming: preferStreamedMarkdown
      )
      .ignoresSafeArea(edges: .bottom)
    }
    .onAppear {
      listener.viewModel = viewModel
    }
    .onChange(of: preferStreamedMarkdown, initial: true) { _, isStreamed in
      listener.isStreamingActive = isStreamed
      if isStreamed {
        viewModel.play()
      }
    }
    .onChange(of: viewModel.isControlDrawerPresented) { _, isPresented in
      guard isPresented && viewModel.isComplete && viewModel.isAtScrollBottom else { return }
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
    "\(demonstration.id)-\(markdownTheme.id)-\(viewModel.streamID)"
  }

  private var staticContentID: String {
    "\(demonstration.id)-\(markdownTheme.id)-static"
  }
}
