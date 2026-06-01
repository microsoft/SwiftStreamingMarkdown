//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown

/// Scan for a specific node matching a certain criteria in a Markdown.
public protocol MarkupScanner {

  associatedtype Node: Markup

  /// Scan the markdown and determine whether this document is eligible for rewriting
  /// - Parameter document: The parsed markdown document
  /// - Returns: Boolean for eligibility
  func scan(document: Document) -> Node?
}
