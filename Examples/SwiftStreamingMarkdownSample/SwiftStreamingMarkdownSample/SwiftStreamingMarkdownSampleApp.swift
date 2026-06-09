//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI

@main
struct SwiftStreamingMarkdownSampleApp: App {
  @AppStorage(SampleSettings.appearanceModeKey) private var appearanceMode = AppearanceMode.device

  var body: some Scene {
    WindowGroup {
      NavigationView()
        .preferredColorScheme(appearanceMode.colorScheme)
    }
  }
}
