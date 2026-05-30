//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI

public enum InlineCitationConstants {
  /*
   We use this data to distinguish between a "real" link provided via markdown and a
    clientside created citation link.

   Inline citations have the format:

   - url -> citation's url
   - query params:
      - citationMarkerQueryParam = citationMarkerValue
      - citationTitleParam = the title to display
      - citationIdParam = comma separated array of citation ids
      - citationChatItemIdParam = chat item id the citation belongs to

   [citationMarkerValue](url?queryParams)

   This format contains the metadata needed for inline citations
   to be intercepted and read when tapped
   */
  public static let citationMarkerQueryParam = "citationMarker"
  public static let citationMarkerValue = "9F742443-6C92-4C44-BF58-8F5A7C53B6F1"
  public static let citationTitleParam = "citationTitle"
  public static let citationFullTitleParam = "citationFullTitle"
  public static let citationIdParam = "citationId"
  public static let citationChatItemIdParam = "chatItemId"

  // MARK: - Shared Layout

  /// Shared layout constants for citation label rendering.
  /// Used by both `AttachmentCitationLabel` (live UIView) and
  /// `InlineCitationAttachment.renderCitationImage` (static image fallback)
  /// to ensure visual consistency.
  static let attachmentTextInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
  static let attachmentCornerRadius: CGFloat = 6
}
