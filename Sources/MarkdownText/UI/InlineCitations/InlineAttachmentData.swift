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

  /// Initialize from a citation link destination
  init?(
    linkDestination: String
  ) {
    guard let url = URL.fromMixedEncodingString(linkDestination),
          let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
          let title = components.queryItems?.first(
            where: { $0.name == InlineCitationConstants.citationTitleParam }
          )?.value,
          let accessibilityLabel = components.queryItems?.first(
            where: { $0.name == InlineCitationConstants.citationFullTitleParam }
          )?.value
    else {
      return nil
    }

    self.type = .citation
    self.url = url
    self.title = title
    self.accessibilityLabel = accessibilityLabel
  }
}
