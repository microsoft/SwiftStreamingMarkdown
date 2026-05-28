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

  private var streamedRenderConfig: MarkdownRenderConfig {
    MarkdownRenderConfig
      .default
      .withTextContextMenu(value: demonstration.customContextMenu)
      .withShouldAnimateText(value: true)
  }

  var body: some View {
    ScrollView {
      Group {
        if preferStreamedMarkdown {
          StreamedMarkdownView(
            text: markdownText,
            config: streamedRenderConfig,
            chunkInterval: 0.2
          ).environmentObject(listener)
        } else {
          MarkdownView(
            text: markdownText,
            config: .default,
            listener: listener
          )
        }
      }
      .padding(.horizontal, 16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 16)
    }
    .navigationTitle(demonstration.rawValue)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
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
}
