//
//  Copyright © 2025 Microsoft. All rights reserved.
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
