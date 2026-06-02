# Agent Instructions for SwiftStreamingMarkdown

> **Trust these instructions first.** Only search the repository if information here is incomplete or wrong.

## Project Overview

SwiftStreamingMarkdown is a Swift Package that renders **Markdown** in SwiftUI. It is consumed by Apple-platform apps that need to display Markdown content, either bespoke or incrementally produced by an LLM or other streaming source. The package is iOS-first, distributed via **Swift Package Manager only**, and ships with a sample app under `Examples/`.

**Key technologies:**

| Topic | Value |
|---|---|
| Language | Swift |
| UI | SwiftUI (some UIKit interop under `Sources/MarkdownText/UI/UIKit/`) |
| swift-tools-version | 5.9 |
| Minimum Xcode | **16.0** (the package contains `@available(iOS 18.0, *)` annotations that require the iOS 18 SDK) |
| Minimum iOS deployment | iOS 16 |
| Build system | Swift Package Manager (no Bazel, no CocoaPods) |
| Linter | SwiftLint (config: `.swiftlint.yml`, run via `swiftlint --strict`) |

## Directory Structure

```
SwiftStreamingMarkdown/
├── Makefile                                 # Common local development commands
├── Package.swift                            # SPM manifest — single library target
├── Sources/
│   └── MarkdownText/                        # The library target
│       ├── Block/                           # Block-level Markdown rendering
│       ├── Inline/                          # Inline-level Markdown rendering
│       ├── Citation/                        # Inline citation handling
│       ├── Style/                           # Colors, fonts, typography
│       ├── TextTransition/                  # iOS 18+ FadeInTextTransition
│       ├── UI/                              # SwiftUI views (CodeBlockView, TableView, etc.)
│       │   └── UIKit/                       # UIKit interop (ParagraphUIView, etc.)
│       ├── Utilities/                       # Bundle, URL, String helpers
│       └── Resources/                       # Assets.xcassets, Media.xcassets (Bundle.module)
├── Tests/
│   └── MarkdownTextTests/                   # XCTest + swift-snapshot-testing
├── Examples/
│   └── SwiftStreamingMarkdownSample/        # Sample iOS app + XcodeGen project.yml
├── .agents/skills/                          # Repo-scoped Copilot skills (pr-writer, snapshot-tests)
├── scripts/
│   └── dev-setup.sh                         # One-time local tooling check
├── .github/workflows/ci.yml                 # SwiftLint + SPM unit tests + sample-app build
├── .swiftlint.yml                           # Lint rules
├── .xcode-version                           # Minimum Xcode version, read by dev-setup.sh
└── CONTRIBUTING.md                          # Contributor guide
```

## Architecture

The major components of this library are parsing and rendering. They are highly isolated to make sure code is executed on the right threads and is easy to contribute to.

### Preprocess

Perform text-level processing before sending it to the markdown parser, if needed. The library uses it to recognize math syntax and convert it to a format the markdown parser understands. This works in most cases but is not ideal — it's on the roadmap to include math parsing as part of the markdown parsing itself.

### Parse

This is based on Apple's open-source parser from [swift-markdown](https://github.com/swiftlang/swift-markdown), which is backed by [cmark-gfm](https://github.com/swiftlang/swift-cmark).

### Rewrite

Perform markdown AST-level manipulation before passing the result to the UI layer. The library uses this to speculatively close half-typed emphasis — for example, a streaming chunk `Yeah, this is *cool` gets rewritten to render as if it were `Yeah, this is **cool**`, so the text doesn't jitter back and forth as the rest of the token streams in.

### Pre-Render

This step converts the markdown AST (`Document`) into a `RenderableDocument` for rendering. It translates markdown styles into Apple's language, mainly around `NSAttributedString`, `NSTextAttachment`, etc.

### Render

The `RenderableDocument` is then passed to the SwiftUI/UIKit layer to render on iOS devices. Most of the UI components are written in SwiftUI except for paragraphs. We chose UIKit's `UITextView` to render paragraphs to ensure the library can support streamed markdown with fine-grained animation control and high performance.

---

## Working Principles

Behavioral guidelines for agents (and humans) working in this repo. These bias toward caution over speed; for trivial tasks, use judgment.

### 1. Think before coding

Don't assume. Don't hide confusion. Surface tradeoffs.

- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop, name what's confusing, and ask.

### 2. Simplicity first

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical changes

Touch only what you must. Clean up only your own mess.

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that *your* changes made unused; don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

### 4. Goal-driven execution

Define success criteria. Loop until verified.

- "Add validation" → "Write tests for invalid inputs, then make them pass."
- "Fix the bug" → "Write a test that reproduces it, then make it pass."
- "Refactor X" → "Ensure tests pass before and after."

For multi-step tasks, state a brief plan with a verification step per item.

---

## Coding Standards

### Naming Conventions

Names should be grammatical, concise, and accurate. Avoid abbreviations and Boolean-naming mistakes (`isFooEnabled`, not `isEnableFoo`).

```swift
// ❌ Not preferred
var data: String
func process() -> Void
var usrNm: String
var isEnableFoo: Bool

// ✅ Preferred
var userName: String
var profileImageURL: URL
func processLoginCredentials() -> Void
var isFooEnabled: Bool
```

### Swift Concurrency

- Prefer `async/await` and `Task`. Avoid `DispatchQueue` / `OperationQueue` except when bridging legacy callbacks.
- Use `actor` for shared mutable state owned by the library.
- Do not sweep `@MainActor` isolation across non-UI types. Only views and types that mutate observable view state need to be main-actor isolated.
- This package's streaming pipeline runs on a background task and pushes rendered output to the main actor at the boundary; do not move that boundary inward without measuring.

### Main Thread and Rendering Performance

- Code must not block the main thread with sleeps, semaphore waits, busy polling etc.
- Do not perform heavy operations inside SwiftUI view bodies — precompute upstream of the view.

### Data Flow

Streaming input is modeled as `AsyncSequence`. The package depends on [`AsyncExtensions`](https://github.com/sideeffect-io/AsyncExtensions) for helpful operators (channels, debouncing, multicasting, etc.). Use those over bridging to Combine.

For new async subscriptions inside view-scoped code, bind the Task lifecycle to the owning type rather than creating an orphan `Task`. If a background loop must outlive a single render, factor it into a type with deterministic teardown.

### Swift Code Organization

- One primary type per source file. Nested helper types (`enum State`, `struct Configuration`) belong inside the parent type when they are only meaningful in that context.
- Group related extensions in `Type+Feature.swift` files (e.g. `Colors+Theme.swift`, `String+.swift`).

```swift
// ✅ Preferred — State is meaningful only inside the view model
final class FooViewModel: ObservableObject {
    enum State { case loading, ready, error(Error) }
    @Published var state: State = .loading
}
```

---

## Testing

- The unit-test target is `SwiftStreamingMarkdownTests` at `Tests/MarkdownTextTests`, built on **XCTest**.
- Snapshot tests use [`pointfreeco/swift-snapshot-testing`](https://github.com/pointfreeco/swift-snapshot-testing). See the **`.agents/skills/snapshot-tests/SKILL.md`** skill for how to record, validate, and visually diff snapshots (`diff-image` from ImageMagick).

---

## Build, Test, and Local Setup

### One-time setup

```bash
make dev-setup
```

This verifies Homebrew, Xcode ≥ `.xcode-version`, SwiftLint, XcodeGen, `cloc`, ImageMagick, and `diff-image` are present and installs the missing optional tools where it can.

### Common commands

```bash
# Show all Make targets
make help

# Resolve Swift package dependencies and open the package in Xcode
make project

# Generate the sample app project
make generate-sample-project

# Generate and open the sample app project in Xcode
make sample-project

# Count code using cloc's Git file discovery
make cloc
```

### Authoritative commands (mirrors CI)

```bash
# Lint
make lint

# Run the package unit tests
make test

# Build the sample app
make build-sample
```
