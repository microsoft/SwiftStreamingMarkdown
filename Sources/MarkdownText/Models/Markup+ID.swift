//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import Markdown

extension Markup {

  /// A unique ID of the markdown node, formed by using the path from root.
  var id: String {
    var parentNode = self.parent
    var path = [String]()
    while parentNode != nil {
      path.append(String(self.indexInParent))
      parentNode = parentNode?.parent
    }
    return path.joined(separator: "-")
  }
}
