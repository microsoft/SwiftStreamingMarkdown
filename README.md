# SwiftStreamingMarkdown

[![CI](https://github.com/microsoft/SwiftStreamingMarkdown/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/microsoft/SwiftStreamingMarkdown/actions/workflows/ci.yml)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS 16+](https://img.shields.io/badge/iOS-16%2B-blue.svg)](https://developer.apple.com/ios/)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A high-performance Markdown renderer for iOS, designed for both static markdown texts and LLM stream style where the source text grows token-by-token. 

- Native inline and block LaTeX math rendering backed by
  [iosMath](https://github.com/maitbayev/iosMath)
- Support configurable inline citations UIs commonly seen from LLM outputs
- Highly configurable text styles and iOS context menus
- Streaming-friendly fade-in transitions for newly arrived glyphs
- Built-in `MarkdownListener` hooks for analytics and interaction tracking

## Demos

Here are a few demos to help you quickly understand this library's capabilities. More can be found in the sample app.

<table>
  <tr>
    <td>
      <h3>Table</h3>
      <video src="https://github.com/user-attachments/assets/bdfc448f-069a-413f-a9d8-221fe1a1e303" width="400" controls></video>
    </td>
    <td>
      <h3>Inline and Block LaTeX</h3>
      <video src="https://github.com/user-attachments/assets/590d7757-4ad6-46e1-9e59-9b2a13355087" width="400" controls></video>
    </td>
    <td>
      <h3>Customized Theme</h3>
      <video src="https://github.com/user-attachments/assets/bec02fc2-8b8d-4bc3-9145-0a6f2012ffc6" width="400" controls></video>
    </td>
  </tr>
</table>

<table>
  <tr>
    <td>
      <img width="361" height="156" alt="Inline Citation" src="https://github.com/user-attachments/assets/f35fa1af-0d9a-48b2-81f2-b3228d1b7322" />
    </td>
    <td>
      <img width="375" height="453" alt="code-block" src="https://github.com/user-attachments/assets/d6e3a266-e00b-442b-82f4-f9f395629547" />
    </td>
  </tr>
</table>

## Markdown support

The renderer targets the subset of CommonMark + GitHub-flavored Markdown that LLM responses actually emit. Unsupported syntax degrades to readable text so streamed responses never break.

### Supported

- [x] Headings (`#` … `######`)
- [x] Paragraphs with soft and hard line breaks
- [x] **Bold**, *italic*, ***bold-italic***, ~~strikethrough~~
- [x] `Inline code`
- [x] Inline links
- [x] Fenced code blocks with language tag
- [x] Block quotes (with nested inlines, lists, and citations)
- [x] Ordered lists
- [x] Unordered lists (with nesting)
- [x] Thematic breaks (`---`)
- [x] Tables with `:---`, `:---:`, `---:` column alignment
- [x] Inline LaTeX math via `\( … \)`
- [x] Display LaTeX math via `$$ … $$`
- [x] Inline citation pills

### Not yet supported

- [ ] Images (`![alt](url)`) — alt text only
- [ ] Task lists (`- [ ]` / `- [x]`)
- [ ] Footnotes (`[^1]`)
- [ ] Highlight (`==text==`), superscript (`^x^`), subscript (`~x~`)
- [ ] Raw HTML (`<details>`, `<kbd>`, `<aside>`, …) — kept inline as text
- [ ] GitHub alerts (`> [!NOTE]`) — rendered as plain block quotes
- [ ] Container directives (`::: warning … :::`) and admonitions (`!!! note`)
- [ ] Mermaid / PlantUML diagrams — rendered as fenced code

The bundled `Kitchen Sink` demonstration in the sample app exercises every item above so you can verify the fallback behavior on-device.

## Requirements

| Requirement | Minimum |
| --- | --- |
| iOS | 16.0 |
| Swift | 5.9 |
| Xcode | 16.0 |

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

For chat-style UIs that grow the Markdown source over time, use
`StreamedMarkdownView`. It takes a `StreamedMarkdownSource` whose `text`
property yields progressively larger snapshots of the Markdown source (each
emission is the full source so far, not a delta) and incrementally parses
and renders them as they arrive.

```swift
import SwiftUI
import AsyncExtensions
import SwiftStreamingMarkdown

class ChatResponseSource: ObservableObject, StreamedMarkdownSource {
  let text: AnyAsyncSequence<String> { ... }
}

struct ChatBubble: View {
  @EnvironmentObject var source: ChatResponseSource

  var body: some View {
    StreamedMarkdownView(source: source)
  }
}
```

If you'd rather drive `DocumentView` directly, parse each snapshot with
`MarkdownParser.parse(text:config:)` and feed the resulting
`RenderableDocument` into your view yourself.

The bundled [sample app](Examples/SwiftStreamingMarkdownSample) demonstrates
chunked streaming end-to-end with adjustable chunk size and interval, plus
auto-scroll wired through a `MarkdownListener`.

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

## Contributing

Contributions are welcome! Bug reports and feature requests go through the
[issue templates](.github/ISSUE_TEMPLATE). A dedicated `CONTRIBUTING.md`
with local setup, code style, and the pull-request process is in progress
and will land in a follow-up change.

This project follows the
[Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

## Security

Please follow the responsible-disclosure process described in
[SECURITY.md](SECURITY.md). Do not file security issues publicly.

## License

SwiftStreamingMarkdown is released under the [MIT License](LICENSE). Dependencies
are declared in [`Package.swift`](Package.swift); each upstream ships its own
license terms via Swift Package Manager.
