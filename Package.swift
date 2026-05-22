// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "StreamingMarkdown",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "StreamingMarkdown",
            targets: ["StreamingMarkdown"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.7.3"),
        .package(url: "https://github.com/appstefan/highlightswift", revision: "99c431b38a1444a5fd6a4978307fbbefe3a7af53"),
        .package(url: "https://github.com/maitbayev/iosMath", revision: "066ba2f8353782a644889efe9ceb884ea844180b")
    ],
    targets: [
        .target(
            name: "StreamingMarkdown",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "HighlightSwift", package: "highlightswift"),
                .product(name: "iosMath", package: "iosMath")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "StreamingMarkdownTests",
            dependencies: ["StreamingMarkdown"]
        )
    ]
)
