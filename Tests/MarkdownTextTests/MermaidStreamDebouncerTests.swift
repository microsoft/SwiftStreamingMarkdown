//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

@testable import SwiftStreamingMarkdown
import XCTest

@MainActor
final class MermaidStreamDebouncerTests: XCTestCase {

  func test_rapid_updates_coalesce_to_last_source() async {
    let debouncer = MermaidStreamDebouncer(delayMs: 10)
    var committed: [String] = []
    debouncer.onCommit = { committed.append($0) }

    debouncer.schedule("a")
    debouncer.schedule("b")
    debouncer.schedule("c")

    try? await Task.sleep(ms: 80)
    XCTAssertEqual(committed, ["c"])
  }

  func test_quiet_gap_between_updates_commits_each() async {
    let debouncer = MermaidStreamDebouncer(delayMs: 10)
    var committed: [String] = []
    debouncer.onCommit = { committed.append($0) }

    debouncer.schedule("first")
    try? await Task.sleep(ms: 50)
    debouncer.schedule("second")

    try? await Task.sleep(ms: 80)
    XCTAssertEqual(committed, ["first", "second"])
  }

  func test_cancel_suppresses_pending_commit() async {
    let debouncer = MermaidStreamDebouncer(delayMs: 10)
    var committed: [String] = []
    debouncer.onCommit = { committed.append($0) }

    debouncer.schedule("a")
    debouncer.cancel()

    try? await Task.sleep(ms: 80)
    XCTAssertTrue(committed.isEmpty)
  }
}
