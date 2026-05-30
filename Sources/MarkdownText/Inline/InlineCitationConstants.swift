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
      - citationFullTitleParam = the full title to display

   [citationMarkerValue](url?queryParams)

   This format contains the metadata needed for inline citations
   to be intercepted and read when tapped
   */
  public static let citationMarkerQueryParam = "citationMarker"
  public static let citationMarkerValue = "9F742443-6C92-4C44-BF58-8F5A7C53B6F1"
  public static let citationTitleParam = "citationTitle"
  public static let citationFullTitleParam = "citationFullTitle"
}
