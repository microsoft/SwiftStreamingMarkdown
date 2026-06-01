//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import UIKit

/// The type of inline attachment, used to render different visual styles
enum AttachmentType: String, Codable {
  case citation
}

struct InlineAttachmentData: Codable {
  let type: AttachmentType
  let title: String
  let accessibilityLabel: String
  let url: URL

  init(type: AttachmentType, title: String, accessibilityLabel: String, url: URL) {
    self.type = type
    self.title = title
    self.accessibilityLabel = accessibilityLabel
    self.url = url
  }
}
