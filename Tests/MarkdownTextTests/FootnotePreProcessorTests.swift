//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import XCTest

final class FootnotePreProcessorTests: XCTestCase {

  private let preprocessor = FootnotePreProcessorImpl()

  func test_referenceAndDefinition_producesMarkerAndSection() {
    let input = """
    hello[^1]

    [^1]: note
    """
    let expected = """
    hello`[[fnref:1]]`

    ---

    1. note
    """
    XCTAssertEqual(preprocessor.process(input: input), expected)
  }

  func test_numberingFollowsFirstAppearance() {
    let input = """
    a[^b] then [^a]

    [^a]: A
    [^b]: B
    """
    let expected = """
    a`[[fnref:1]]` then `[[fnref:2]]`

    ---

    1. B
    2. A
    """
    XCTAssertEqual(preprocessor.process(input: input), expected)
  }

  func test_namedLabelRendersAsNumber() {
    let input = """
    x[^note]

    [^note]: hi
    """
    let expected = """
    x`[[fnref:1]]`

    ---

    1. hi
    """
    XCTAssertEqual(preprocessor.process(input: input), expected)
  }

  func test_undefinedReference_staysLiteral() {
    XCTAssertEqual(preprocessor.process(input: "x[^nope]"), "x[^nope]")

    let mixed = """
    x[^nope] y[^1]

    [^1]: ok
    """
    let expected = """
    x[^nope] y`[[fnref:1]]`

    ---

    1. ok
    """
    XCTAssertEqual(preprocessor.process(input: mixed), expected)
  }

  func test_unreferencedDefinition_isDroppedWithoutSection() {
    let input = """
    plain text

    [^1]: orphan
    """
    XCTAssertEqual(preprocessor.process(input: input), "plain text\n")
  }

  func test_repeatedReference_sharesNumber() {
    let input = """
    a[^1] b[^1]

    [^1]: x
    """
    let expected = """
    a`[[fnref:1]]` b`[[fnref:1]]`

    ---

    1. x
    """
    XCTAssertEqual(preprocessor.process(input: input), expected)
  }

  func test_fencedCodeBlock_isUntouched() {
    let input = """
    ```
    code [^1]
    [^1]: not a definition
    ```

    text[^1]

    [^1]: real
    """
    let expected = """
    ```
    code [^1]
    [^1]: not a definition
    ```

    text`[[fnref:1]]`

    ---

    1. real
    """
    XCTAssertEqual(preprocessor.process(input: input), expected)
  }

  func test_inlineCodeSpan_isUntouched() {
    let input = """
    use `[^1]` as marker[^1]

    [^1]: note
    """
    let expected = """
    use `[^1]` as marker`[[fnref:1]]`

    ---

    1. note
    """
    XCTAssertEqual(preprocessor.process(input: input), expected)
  }

  func test_textWithoutFootnotes_isUnchanged() {
    let input = "plain **text** with `code` and a [link](https://example.com)"
    XCTAssertEqual(preprocessor.process(input: input), input)
  }

  func test_definitionKeepsInlineMarkdown() {
    let input = """
    x[^1]

    [^1]: has **bold** and `code`
    """
    let expected = """
    x`[[fnref:1]]`

    ---

    1. has **bold** and `code`
    """
    XCTAssertEqual(preprocessor.process(input: input), expected)
  }
}
