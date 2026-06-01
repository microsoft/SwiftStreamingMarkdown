# SwiftStreamingMarkdown

[![CI](https://github.com/microsoft/SwiftStreamingMarkdown/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/microsoft/SwiftStreamingMarkdown/actions/workflows/ci.yml)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS 16+](https://img.shields.io/badge/iOS-16%2B-blue.svg)](https://developer.apple.com/ios/)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A high-performance streaming Markdown renderer for iOS, designed for chat-style
UIs where the source text grows token-by-token. SwiftStreamingMarkdown re-parses
and re-renders incremental input on every chunk without flickering, while still
supporting the formatting you expect from a static Markdown renderer:

- Paragraphs, headings, ordered and unordered lists, tables, block quotes
- Fenced code blocks with syntax highlighting via
  [HighlightSwift](https://github.com/appstefan/highlightswift)
- Inline and block LaTeX math via
  [iosMath](https://github.com/maitbayev/iosMath)
- Inline images and SVG attachments
- Configurable inline citations with custom view providers
- Streaming-friendly fade-in transitions for newly arrived glyphs
- Built-in `MarkdownListener` hooks for analytics and interaction tracking

## Requirements

| Requirement | Minimum |
| --- | --- |
| iOS | 16.0 |
| Swift | 5.9 |
| Xcode | 16.0 |

LaTeX rendering and code-block syntax highlighting work on all supported
versions; the streaming fade-in transition uses APIs that require iOS 18+ and
falls back to a simple opacity transition on earlier versions.

## Installation

SwiftStreamingMarkdown is distributed exclusively as a Swift Package.

### Xcode

1. Choose **File ▸ Add Package Dependencies…**
2. Enter `https://github.com/microsoft/SwiftStreamingMarkdown`
3. Select the version rule you want (e.g. *Up to next minor*) and add the
   `SwiftStreamingMarkdown` product to your app target.

### `Package.swift`

```swift
.package(url: "https://github.com/microsoft/SwiftStreamingMarkdown", from: "0.1.0"),
```

```swift
.target(
  name: "MyApp",
  dependencies: [
    .product(name: "SwiftStreamingMarkdown", package: "SwiftStreamingMarkdown")
  ]
)
```

## Quick start

The simplest entry point is `MarkdownView`, which parses and renders a static
string of Markdown using the default theme:

```swift
import SwiftUI
import SwiftStreamingMarkdown

struct ContentView: View {
  var body: some View {
    ScrollView {
      MarkdownView(text: """
      # Hello, **world!**

      SwiftStreamingMarkdown supports tables, lists, code blocks, and
      inline `code`.

      ```swift
      print("Hello, world!")
      ```
      """)
      .padding()
    }
  }
}
```

## Streaming usage

For chat-style UIs that grow the Markdown source over time, parse each new
chunk into a `RenderableDocument` and feed it to `DocumentView`. Re-rendering
an existing `RenderableDocument` is cheap; the expensive step is the parse.

```swift
import SwiftUI
import SwiftStreamingMarkdown

@MainActor
final class StreamingViewModel: ObservableObject {
  @Published private(set) var document: RenderableDocument = .empty
  private let parser = MarkdownParserImpl()
  private let config: MarkdownRenderConfig = .default

  func append(chunk: String, to buffer: inout String) async {
    buffer += chunk
    let parsed = await parser.parse(text: buffer)
    document = await RenderableDocument(document: parsed, config: config)
  }
}

struct ChatBubble: View {
  @StateObject var model = StreamingViewModel()

  var body: some View {
    DocumentView(renderableDocument: model.document, config: .default)
  }
}
```

The bundled [sample app](Examples/SwiftStreamingMarkdownSample) demonstrates
chunked streaming end-to-end with adjustable chunk size and interval.

## Customizing the theme

`MarkdownRenderConfig` is the single source of truth for styling. Build one
by composing the `withXxx` helpers on `.default`:

```swift
let config = MarkdownRenderConfig.default
  .withShouldAnimateText(value: true)
  .withHeadingStyle(value: MarkdownRenderConfig.defaultHeadingStyle)
  .withParagraphStyle(value: MarkdownRenderConfig.defaultParagraphStyle)
```

For finer control, construct `MarkdownRenderConfig` directly to override the
inline, paragraph, heading, list, table, and citation styles in one place.

## Listening for events

Conform to `MarkdownListener` to receive notifications whenever the renderer
draws or the user interacts with rendered content (table copy/download taps,
context-menu lifecycle, etc.):

```swift
final class AnalyticsListener: MarkdownListener {
  func onRender(markdown: RenderableDocument) async { /* ... */ }
  func onTableCopyTap(content: String) async { /* ... */ }
  func onTableDownloadTap(content: String) async { /* ... */ }
  func onContextMenuAppear(id: String, selectedContent: String) async { /* ... */ }
  func onContextMenuTap(id: String, selectedContent: String) async { /* ... */ }
}

MarkdownView(text: source, listener: AnalyticsListener())
```

The listener is propagated through the SwiftUI environment, so deeply nested
rendered subviews observe the same hooks.

## Sample app

A SwiftUI sample app lives in
[`Examples/SwiftStreamingMarkdownSample`](Examples/SwiftStreamingMarkdownSample).
It includes a streaming demonstration with adjustable chunk size and interval,
a settings screen, and a logging `MarkdownListener` implementation. Open
`Examples/SwiftStreamingMarkdownSample/SwiftStreamingMarkdownSample.xcodeproj`
in Xcode to run it on a simulator or device.

## Documentation

API reference is currently generated from in-source doc-comments. A DocC
catalog with curated articles (getting started, streaming, theming,
citations, math) is on the near-term roadmap; see
[CHANGELOG.md](CHANGELOG.md) for tracked work.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for
local setup, code style, and the pull-request process. Bug reports and
feature requests go through the
[issue templates](.github/ISSUE_TEMPLATE).

This project follows the
[Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

## Security

Please follow the responsible-disclosure process described in
[SECURITY.md](SECURITY.md). Do not file security issues publicly.

## License

SwiftStreamingMarkdown is released under the [MIT License](LICENSE). Bundled
third-party software and their licenses are listed in [NOTICE](NOTICE) and
[`docs/dependency-inventory.md`](docs/dependency-inventory.md).

## Trademarks

This project may contain trademarks or logos for projects, products, or
services. Authorized use of Microsoft trademarks or logos is subject to and
must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must
not cause confusion or imply Microsoft sponsorship. Any use of third-party
trademarks or logos is subject to those third parties' policies.
