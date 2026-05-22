# StreamingMarkdown for iOS

`StreamingMarkdown` is a small, product-neutral Swift Package for rendering markdown that arrives incrementally from a streaming source.

## What is included

- `StreamingMarkdownView`: SwiftUI entry point that reparses as `text` changes.
- String-level partial rewrite hooks for incomplete streamed markdown (`PartialMarkdownRewriter`).
- Default partial strong-emphasis and partial-table rewrites.
- Citation parsing from configurable markdown link URLs, with pill UI and accessibility labels.
- Block and inline math rendering through `iosMath` when available.
- Code block and table actions for copy/export callbacks.
- Link callbacks and theme hooks.
- Design-system presets and custom layout/typography/color tokens.
- Sample fixtures loaded from package resources generated from `samples/streaming-fixtures`, plus a demo app source skeleton under `DemoApp/`.

## Basic usage

```swift
StreamingMarkdownView(
    text: streamedText,
    configuration: .init(designSystem: .humanist),
    onLinkTap: { url in openURL(url) },
    onCitationTap: { citation in showCitation(citation) },
    onCodeCopy: { code, language in print(language ?? "plain", code) },
    onTableExport: { payload, format in print(payload.value(for: format)) }
)
```

## Repository layout

```text
Sources/                    Swift package source
Tests/                      Swift package tests
samples/streaming-fixtures/ Markdown fixtures for demos and tests
DemoApp/                    SwiftUI demo source and XcodeGen project spec
docs/                       iOS package design and release-prep docs
```

Use the local `Makefile` from this directory:

```bash
make build
make test
make run-demo
```

## Design systems

Use `StreamingMarkdownConfiguration(designSystem:)` to apply a renderer-wide visual system. The default preset is named SF Pro and follows Apple's system typography, blue accent, grouped backgrounds, separators, and dynamic light/dark system colors. `.systemDefault` keeps the original generic renderer styling as a separate option. The built-in `.humanist` preset mirrors the extracted Copilot mobile markdown styling with OSS-safe font fallbacks and dynamic light/dark colors. The additional app-target presets are mechanically mapped where this renderer has matching surfaces: `.seriousBusiness` for OCM Fluent/Rocksteady markdown, `.paperwork` for OfficeMobile SharedHub Fluent card tokens, `.tailoredSuit` for Cowork markdown/card surfaces, and `.jazzHands` for OfficeMobile/OCM Bebop markdown/table styling. `.alternativeMan` is ChatGPT-inspired, and `.rationalist` is Claude-inspired. Design systems also expose page, surface, and control background colors for host demo chrome.

```swift
let config = StreamingMarkdownConfiguration(designSystem: .humanist)
```

For custom products, create `StreamingMarkdownDesignSystem(name:theme:layout:)` and provide fonts, colors, backgrounds, spacing, and corner radii without changing parser behavior.

Code and table action controls use public theme tokens (`codeActionForeground` and `tableActionForeground`) so hosts can align copy/export affordances without replacing renderer internals.

## Citations

By default, citations can use footnote-style markers or citation links:

```markdown
[^source-1]
[1](citation://source-1?title=1&fullTitle=Example%20Source)
[1](https://example.com/source?citation=true&title=1)
```

Customize `CitationParsingConfiguration` if your backend uses different marker/query names, a custom URL scheme, or a regex marker with captured ID/label/source groups. Parsed citations preserve `id`, display `title`, optional `source`, URL, full title, and an accessibility label for the pill control.

## Math rendering and fallback

Inline `\(...\)`, block `\[...\]`, and block `$$...$$` LaTeX are preprocessed before markdown parsing so streaming updates can turn complete math delimiters into stable inline or block math runs. The preprocessor also ports the source-app normalization for unsupported syntax such as `\boxed`, `\dfrac`, `\tfrac`, prime marks, vector arrows, implication arrows, harpoons, dots, and bracket-size commands.

Rendering uses `iosMath`. If parsing or rendering cannot produce a math view, the renderer falls back to the original equation text instead of dropping content or breaking layout. During streaming, incomplete math delimiters remain plain text until the closing delimiter arrives.

## Syntax highlighting

The package references `HighlightSwift` but keeps highlighting injectable:

```swift
var config = StreamingMarkdownConfiguration.default
config.syntaxHighlighter = { code, language in
    // Return an AttributedString from your preferred highlighter.
    nil
}
```

## Known gaps for this extraction milestone

- The parser now uses `swift-markdown` AST conversion for primary block parsing, with streaming-safe fallback behavior for incomplete content. Additional production app parser cases should be ported as they are identified.
- Table rendering currently flattens inline content inside cells to text.
- The demo app folder is source skeleton, not a committed `.xcodeproj`; `make run-demo` regenerates the project from `DemoApp/project.yml`.
