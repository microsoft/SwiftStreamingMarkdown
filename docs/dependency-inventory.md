# Dependency inventory

This document lists the third-party Swift packages that ship as part of
SwiftStreamingMarkdown, what they are used for, and their licenses. Whenever a
dependency is added, removed, or upgraded, update both this file and `NOTICE`
in the repository root.

The pinned versions are authoritative in `Package.swift` and reflected in
`Package.resolved`; the values below are kept current on a best-effort basis
for human consumption.

## Runtime dependencies

| Package | Purpose | Pinned version | License | Upstream |
| --- | --- | --- | --- | --- |
| AsyncExtensions | Structured-concurrency helpers used by the streaming parser. | `0.5.5` | MIT | https://github.com/sideeffect-io/AsyncExtensions |
| equatable (`Equatable` macro) | Compile-time `Equatable` synthesis for SwiftUI view structs to avoid hand-rolled `==`. | `1.0.10` | Apache 2.0 | https://github.com/ordo-one/equatable |
| HighlightSwift | Syntax highlighting for fenced code blocks. | `99c431b` (revision) | MIT | https://github.com/appstefan/highlightswift |
| iosMath | LaTeX math rendering for `$...$` and `$$...$$` blocks. | `066ba2f` (revision) | MIT | https://github.com/maitbayev/iosMath |
| SVGView | Renders inline SVG attachments in rendered markdown. | `1.0.6` | MIT | https://github.com/exyte/SVGView |
| swift-markdown | CommonMark parsing primitives the package builds on. | `0.7.3` | Apache 2.0 | https://github.com/swiftlang/swift-markdown |

## Test-only dependencies

| Package | Purpose | Pinned version | License | Upstream |
| --- | --- | --- | --- | --- |
| swift-snapshot-testing | Snapshot tests for the UIKit/SwiftUI rendering pipeline. | `1.18.1` | MIT | https://github.com/pointfreeco/swift-snapshot-testing |

## License compatibility

All shipped dependencies are MIT- or Apache-2.0-licensed. Both are compatible
with this project's MIT license; the Apache-2.0 dependencies do not require
relicensing, only attribution (already captured in `NOTICE`).
