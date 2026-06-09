//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import Markdown

extension Markup {

  var inlineConvertibleChildren: [InlineConvertible] {
    return self.children.compactMap { $0 as? InlineConvertible }
  }
}
