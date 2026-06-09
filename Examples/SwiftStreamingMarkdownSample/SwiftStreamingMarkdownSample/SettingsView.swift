//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI

struct SettingsView: View {
  @AppStorage(SampleSettings.preferStreamedMarkdownKey) private var preferStreamedMarkdown = true
  @AppStorage(SampleSettings.appearanceModeKey) private var appearanceMode = AppearanceMode.device
  @AppStorage(SampleSettings.markdownThemeKey) private var markdownTheme = SampleMarkdownTheme.automatic

  var body: some View {
    Form {
      Toggle("Streamed", isOn: $preferStreamedMarkdown)
      Picker("Markdown Theme", selection: $markdownTheme) {
        ForEach(SampleMarkdownTheme.allCases) { theme in
          Text(theme.displayName).tag(theme)
        }
      }
      .pickerStyle(.menu)
      Picker("Appearance", selection: $appearanceMode) {
        ForEach(AppearanceMode.allCases) { mode in
          Text(mode.displayName).tag(mode)
        }
      }
      .pickerStyle(.menu)
    }
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
  }
}
