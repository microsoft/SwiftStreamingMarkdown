// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwiftStreamingMarkdown",
  defaultLocalization: "en",
  platforms: [.iOS(.v16)],
  products: [
    .library(
      name: "SwiftStreamingMarkdown",
      targets: ["SwiftStreamingMarkdown"])
  ],
  dependencies: [
    // Structured-concurrency helpers used by the streaming parser.
    .package(url: "https://github.com/sideeffect-io/AsyncExtensions", exact: "0.5.5"),
    // Compile-time `Equatable` synthesis for SwiftUI view structs (Apache 2.0).
    .package(url: "https://github.com/ordo-one/equatable", exact: "1.0.10"),
    // Snapshot tests for the UIKit/SwiftUI rendering pipeline (test-only).
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.18.1"),
    // CommonMark parsing primitives the package builds on (Apache 2.0).
    .package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.7.3"),
    // Syntax highlighting for fenced code blocks.
    .package(url: "https://github.com/appstefan/highlightswift", revision: "99c431b38a1444a5fd6a4978307fbbefe3a7af53"),
    // Renders inline SVG attachments in rendered markdown.
    .package(url: "https://github.com/exyte/SVGView.git", exact: "1.0.6"),
    // LaTeX math rendering for `$...$` and `$$...$$` blocks.
    .package(url: "https://github.com/maitbayev/iosMath", revision: "066ba2f8353782a644889efe9ceb884ea844180b")
  ],
  targets: [
    .target(
      name: "SwiftStreamingMarkdown",
      dependencies: [
        "SVGView",
        .product(name: "Equatable", package: "equatable"),
        "AsyncExtensions",
        .product(name: "Markdown", package: "swift-markdown"),
        .product(name: "HighlightSwift", package: "highlightswift"),
        .product(name: "iosMath", package: "iosMath")
      ],
      path: "Sources/MarkdownText",
      resources: [
        .process("Resources")
      ]
    ),
    .testTarget(
      name: "SwiftStreamingMarkdownTests",
      dependencies: [
        "SwiftStreamingMarkdown",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
      ],
      path: "Tests/MarkdownTextTests")
  ]
)
