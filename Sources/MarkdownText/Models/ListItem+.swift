//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import Markdown

extension ListItem {
  var startsWithBold: Bool {
    return child(at: 0) is Paragraph && child(at: 0)?.child(at: 0) is Strong
  }

  var checkBox: MarkdownListItem.Checkbox? {
    switch checkbox {
    case .checked: return .checked
    case .unchecked: return .unchecked
    case .none: return nil
    }
  }
}
