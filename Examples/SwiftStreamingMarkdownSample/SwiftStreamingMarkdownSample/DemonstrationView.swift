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
    ScrollView {
      VStack(spacing: 0) {
        Group {
          if preferStreamedMarkdown {
            StreamedMarkdownView(
              source: TextSimulatedStreamSource(
                text: markdownText,
                chunkSize: 48,
                chunkInterval: 0.2
              ),
              config: streamedRenderConfig,
              listener: listener
            )
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
      }
    }
    .scrollPosition($listener.scrollPosition)
    .background(backgroundColor.ignoresSafeArea())
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
}
