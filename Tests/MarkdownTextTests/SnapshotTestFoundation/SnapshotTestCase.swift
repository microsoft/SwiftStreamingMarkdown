//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

//  SnapshotTestCase is a utility class extending XCTestCase.
//
//  By default, it registers a diff tool ("diff-image") to assist in comparing mismatched snapshots.
//  You can toggle recording behavior by setting `isRecording` to `true` or `false` in `setUp()`.
//
import SnapshotTesting
import SwiftUI
import XCTest
@testable import SwiftStreamingMarkdown

open class SnapshotTestCase: XCTestCase {
  override open func setUp() {
    super.setUp()
    SnapshotTesting.diffTool = "diff-image"
    ParagraphViewCache.shared.clearCache()
    // isRecording = true
  }

  #if canImport(UIKit)
  /* Function to perform snapshot tests. Embeds all views in a ViewController for.
   - Parameters:
   - view: View to be tested
   - variants: Device variants to be tested. Defaults to the standard collection of device variants
   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called.
   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
   */

  public func assert<V: View>(
    _ view: V,
    variants: [IOSVariant] = .standard(precision: 0.99, perceptualPrecision: 1.00),
    testName: String = #function,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    variants.forEach { variant in
      assertSnapshot(
        of: view.environment(\.colorScheme, variant.colorScheme).asViewController,
        as: variant.snapshot,
        named: variant.name,
        file: file,
        testName: testName,
        line: line
      )
    }
  }
  #elseif canImport(AppKit)
  /// Perform snapshot tests on macOS using window-size-based variants.
  public func assert<V: View>(
    _ view: V,
    variants: [MacVariant] = .standard(precision: 0.99, perceptualPrecision: 1.00),
    testName: String = #function,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    variants.forEach { variant in
      assertSnapshot(
        of: view.environment(\.colorScheme, variant.colorScheme).asViewController,
        as: variant.snapshot,
        named: variant.name,
        file: file,
        testName: testName,
        line: line
      )
    }
  }
  #endif
}

#if canImport(UIKit)
import UIKit

private extension View {
  var asViewController: UIViewController {
    let vc = UIHostingController(rootView: self)
    vc.view.backgroundColor = .clear
    return vc
  }
}
#elseif canImport(AppKit)
import AppKit

private extension View {
  var asViewController: NSViewController {
    let vc = NSHostingController(rootView: self)
    vc.view.wantsLayer = true
    vc.view.layer?.backgroundColor = NSColor.clear.cgColor
    return vc
  }
}
#endif
