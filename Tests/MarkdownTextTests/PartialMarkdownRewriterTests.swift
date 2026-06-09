//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Markdown
@testable import SwiftStreamingMarkdown
import XCTest

// swiftlint:disable force_unwrapping
// swiftlint:disable force_try
// swiftlint:disable force_cast
public final class PartialMarkdownRewriterTests: XCTestCase {

  let partialEmphasisScanner = PartialEmphasisScanner()
  let partialTableScanner = PartialTableScanner()

  func test_rewrite_partial_emphasis() {
    let text = """
    # Welcome to StackEdit!

    Hi! I'm your first Markdown file in **StackEdit**. If you want to learn about StackEdit, you can read me. If you want to play with Markdown, you can edit me. Once you have finished with me, you can create new files by opening the **file explorer
    """
    let document = Document(parsing: text)
    let targetNode = partialEmphasisScanner.scan(document: document)
    XCTAssertNotNil(targetNode)
    var rewriter = PartialEmphasisRewriter(targetNode: targetNode!)
    let rewroteDocument = rewriter.visit(document) as! Document
    let rightMostDescendantAfterRewrite = rewroteDocument.child(at: 1)?.child(at: 3) as? Strong
    XCTAssertNotNil(rightMostDescendantAfterRewrite)
    XCTAssertEqual(rightMostDescendantAfterRewrite?.plainText, "file explorer")
  }

  func test_rewrite_partial_emphasis_underscore() {
    let text = """
    # Welcome to StackEdit!

    Hi! I'm your first Markdown file in **StackEdit**. If you want to learn about StackEdit, you can read me. If you want to play with Markdown, you can edit me. Once you have finished with me, you can create new files by opening the __file explorer
    """
    let document = Document(parsing: text)
    let targetNode = partialEmphasisScanner.scan(document: document)
    XCTAssertNotNil(targetNode)
    var rewriter = PartialEmphasisRewriter(targetNode: targetNode!)
    let rewroteDocument = rewriter.visit(document) as! Document
    let rightMostDescendantAfterRewrite = rewroteDocument.child(at: 1)?.child(at: 3) as? Strong
    XCTAssertNotNil(rightMostDescendantAfterRewrite)
    XCTAssertEqual(rightMostDescendantAfterRewrite?.plainText, "file explorer")
  }

  func test_rewrite_partial_heading_underscore() {
    let text = """
    Here’s another tale with twists and secrets, perfect for you.

    ---

    ### **The Echo
    """
    let document = Document(parsing: text)
    let targetNode = partialEmphasisScanner.scan(document: document)
    XCTAssertNotNil(targetNode)
    var rewriter = PartialEmphasisRewriter(targetNode: targetNode!)
    let rewroteDocument = rewriter.visit(document) as! Document
    let node = rewroteDocument.child(at: 2)?.child(at: 0) as? Strong
    XCTAssertNotNil(node)
  }

  func test_rewrite_emphasis_to_strong() {
    let text = """
    Here’s another tale with twists and secrets, perfect for you.

    ---

    Yeah, this is **cool*
    """
    let document = Document(parsing: text)
    let targetNode = partialEmphasisScanner.scan(document: document)
    XCTAssertNotNil(targetNode)
    var rewriter = PartialEmphasisRewriter(targetNode: targetNode!)
    let rewroteDocument = rewriter.visit(document) as! Document
    let node = rewroteDocument.child(at: 2)?.child(at: 1) as? Strong
    XCTAssertNotNil(node)
  }

  func test_rewrite_emphasis_to_strong_underscore() {
    let text = """
    Here’s another tale with twists and secrets, perfect for you.

    ---

    Yeah, this is __cool_
    """
    let document = Document(parsing: text)
    let targetNode = partialEmphasisScanner.scan(document: document)
    XCTAssertNotNil(targetNode)
    var rewriter = PartialEmphasisRewriter(targetNode: targetNode!)
    let rewroteDocument = rewriter.visit(document) as! Document
    let node = rewroteDocument.child(at: 2)?.child(at: 1) as? Strong
    XCTAssertNotNil(node)
  }

  func test_rewrite_emphasis_to_strong_in_table() {
    let text = """
    # Heading1
    files

    ## Heading2

    | Month | Savings | Column3 |
    |  --------  |  -------  | ------- |
    | **Ja*
    """
    let document = Document(parsing: text)
    let targetNode = partialEmphasisScanner.scan(document: document)
    XCTAssertNotNil(targetNode)
    var rewriter = PartialEmphasisRewriter(targetNode: targetNode!)
    let rewroteDocument = rewriter.visit(document) as! Document
    let node = rewroteDocument.child(at: 3)?.child(at: 1)?.child(at: 0)?.child(at: 0)?.child(at: 0) as? Strong
    XCTAssertNotNil(node)
  }

  func test_rewrite_emphasis_to_strong_in_heading() {
    let text = """
    # Heading1
    files

    ## This is a **great*
    """
    let document = Document(parsing: text)
    let targetNode = partialEmphasisScanner.scan(document: document)
    XCTAssertNotNil(targetNode)
    var rewriter = PartialEmphasisRewriter(targetNode: targetNode!)
    let rewroteDocument = rewriter.visit(document) as! Document
    let node = rewroteDocument.child(at: 2)?.child(at: 1) as? Strong
    XCTAssertNotNil(node)
  }

  func test_partial_emphasis_in_table_cell() {
    let text = """
    # Heading1
    files

    ## Heading2

    | Month | Savings | Column3 |
    |  --------  |  -------  | ------- |
    | **Ja
    """
    let document = Document(parsing: text)
    let targetNode = partialEmphasisScanner.scan(document: document)
    XCTAssertNotNil(targetNode)
    var rewriter = PartialEmphasisRewriter(targetNode: targetNode!)
    let rewroteDocument = rewriter.visit(document) as! Document
    let targetAfterRewrite = rewroteDocument.child(at: 3)?.child(at: 1)?.child(at: 0)?.child(at: 0)?.child(at: 0) as? Strong
    XCTAssertNotNil(targetAfterRewrite)
    XCTAssertEqual(targetAfterRewrite?.plainText, "Ja")
  }

  func test_partial_rewrite_headings() {
    let text = """
    This is a paragraph

    ## This is a **title
    """
    let document = Document(parsing: text)
    let targetNode = partialEmphasisScanner.scan(document: document)
    XCTAssertNotNil(targetNode)
    var rewriter = PartialEmphasisRewriter(targetNode: targetNode!)
    let rewroteDocument = rewriter.visit(document) as! Document
    let target = rewroteDocument.child(at: 1)?.child(at: 1) as? Strong
    XCTAssertNotNil(target)
  }

  func test_partial_rewrite_code_block_should_not_rewrite() {
    let text = """
    This is a paragraph

    ```java
    String a = "abc"
    String b = "**"
    ```
    """
    let document = Document(parsing: text)
    let targetNode = partialEmphasisScanner.scan(document: document)
    XCTAssertNil(targetNode)
  }

  func test_partial_table_header() {
    var text = """
    # Heading1
    files

    ## Heading2

    | Month | Savings | Column3 |
    | ----
    """
    verifyTableRewrite(text: text)

    text = """
    # Heading1
    files

    ## Heading2

    | Month | Savings | Column3 |
    """
    verifyTableRewrite(text: text)

    text = """
    # Heading1
    files

    ## Heading2

    | Month |
    """
    verifyTableRewrite(text: text)
  }

  private func verifyTableRewrite(text: String) {
    let document = Document(parsing: text)
    let targetNode = partialTableScanner.scan(document: document)
    XCTAssertNotNil(targetNode)
    var rewriter = PartialTableRewriter(targetParagraph: targetNode!)
    let rewroteDocument = rewriter.visit(document) as! Document
    XCTAssertEqual(rewroteDocument.child(at: 3)!.childCount, 0)
  }
}
// swiftlint:enable force_unwrapping
// swiftlint:enable force_try
// swiftlint:enable force_cast
