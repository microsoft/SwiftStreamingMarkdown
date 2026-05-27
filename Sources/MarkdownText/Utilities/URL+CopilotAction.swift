//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation

extension URL {
  /// Whether this URL uses a copilot action scheme (`copilot-action://` or `ca://`), case-insensitive.
  ///
  /// Copilot action links trigger in-app actions rather than opening external URLs.
  var isCopilotActionLink: Bool {
    guard let scheme = scheme?.lowercased() else { return false }
    return scheme == "copilot-action" || scheme == "ca"
  }
}
