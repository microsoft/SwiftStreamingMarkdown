//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import XCTest

final class TaskListTests: XCTestCase {

  private let parser = MarkdownParserImpl()

  func test_taskList_carriesCheckboxStates() async {
    let text = """
    - [x] completed task
    - [ ] open task
    - regular item
    """
    let document = await parser.parse(text: text)
    let renderables = document.convert(with: .default)

    guard case .unorderedList(_, let items, _) = renderables.first else {
      return XCTFail("Expected the parsed document to start with an unordered list")
    }
    XCTAssertEqual(items.count, 3)
    XCTAssertEqual(items[0].checkbox, .checked)
    XCTAssertEqual(items[1].checkbox, .unchecked)
    XCTAssertNil(items[2].checkbox)
  }

  func test_regularUnorderedList_hasNoCheckbox() async {
    let text = """
    - item 1
    - item 2
    """
    let document = await parser.parse(text: text)
    let renderables = document.convert(with: .default)

    guard case .unorderedList(_, let items, _) = renderables.first else {
      return XCTFail("Expected the parsed document to start with an unordered list")
    }
    XCTAssertTrue(items.allSatisfy { $0.checkbox == nil })
  }

  func test_orderedTaskList_keepsCurrentBehavior() async {
    let text = """
    1. [x] completed task
    2. [ ] open task
    """
    let document = await parser.parse(text: text)
    let renderables = document.convert(with: .default)

    guard case .orderedList(_, let items) = renderables.first else {
      return XCTFail("Expected the parsed document to start with an ordered list")
    }
    XCTAssertTrue(items.allSatisfy { $0.checkbox == nil })
  }

  func test_nestedTaskList_carriesCheckboxStates() async {
    let text = """
    - top level item
      - [x] nested completed task
      - [ ] nested open task
    """
    let document = await parser.parse(text: text)
    let renderables = document.convert(with: .default)

    guard case .unorderedList(_, let items, _) = renderables.first,
          case .unorderedList(_, let nestedItems, let nestedLevel) = items.first?.children.last
    else {
      return XCTFail("Expected a nested unordered list inside the first list item")
    }
    XCTAssertEqual(nestedLevel, 1)
    XCTAssertEqual(nestedItems.map(\.checkbox), [.checked, .unchecked])
  }
}
