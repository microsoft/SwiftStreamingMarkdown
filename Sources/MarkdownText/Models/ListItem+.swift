//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown

extension ListItem {
  var startsWithBold: Bool {
    return child(at: 0) is Paragraph && child(at: 0)?.child(at: 0) is Strong
  }
}
