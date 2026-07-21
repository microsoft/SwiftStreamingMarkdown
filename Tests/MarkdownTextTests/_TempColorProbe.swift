import Foundation
import SwiftUI
@testable import SwiftStreamingMarkdown
import XCTest

final class TempColorProbeTests: XCTestCase {
  func test_dynamicColorIdentityEquality() {
    let swiftUIColor = MarkdownRenderConfig.default.paragraphStyle.textColor
    let c1 = MDColor(swiftUIColor)
    let c2 = MDColor(swiftUIColor)
    print("c1 == c2 (two independent constructions):", c1 == c2)
    print("c1.isEqual(c2):", c1.isEqual(c2))

    // Archive/unarchive round trip
    let data = try! NSKeyedArchiver.archivedData(withRootObject: c1, requiringSecureCoding: true)
    let c1Restored = try! NSKeyedUnarchiver.unarchivedObject(ofClass: MDColor.self, from: data)!
    print("c1 == c1Restored (archive round-trip):", c1 == c1Restored)
    print("c1 class:", String(describing: type(of: c1)), "restored class:", String(describing: type(of: c1Restored)))

    #if canImport(UIKit)
    let lightC1 = c1.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    let lightRestored = c1Restored.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    print("resolved light equal:", lightC1 == lightRestored, lightC1, lightRestored)
    let darkC1 = c1.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
    let darkRestored = c1Restored.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
    print("resolved dark equal:", darkC1 == darkRestored, darkC1, darkRestored)
    #endif
  }
}
