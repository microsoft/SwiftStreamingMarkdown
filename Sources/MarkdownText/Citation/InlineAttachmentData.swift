//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import UIKit

enum AttachmentType: String, Codable {
  case citation
}

struct InlineAttachmentData: Codable {
  let type: AttachmentType
  let title: String
  let accessibilityLabel: String
  let url: URL
}
