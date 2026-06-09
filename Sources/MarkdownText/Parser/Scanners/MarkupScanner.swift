//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Markdown

protocol MarkupScanner {

  associatedtype Node: Markup

  /// Scan the markdown and determine whether this document is eligible for rewriting
  /// - Parameter document: The parsed markdown document
  /// - Returns: Boolean for eligibility
  func scan(document: Document) -> Node?
}
