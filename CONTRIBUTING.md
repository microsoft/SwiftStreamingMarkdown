# Contributing to SwiftStreamingMarkdown

Thanks for your interest in improving SwiftStreamingMarkdown! This document
covers how to set up the project, run the tests, and propose changes.

## Code of conduct

This project has adopted the
[Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
By participating you agree to abide by its terms.

## Security

Please do not file security vulnerabilities as public issues. See
[`SECURITY.md`](SECURITY.md) for the responsible-disclosure process.

## Requirements

- macOS 14 or later
- Xcode 16 or later (Swift 5.9 toolchain)
- An iOS 16+ simulator (CI uses iPhone 17 on iOS 26.4.1, but any iOS 16+
  simulator works locally)
- [SwiftLint](https://github.com/realm/SwiftLint) for enforcing the project's
  Swift style. Install with Homebrew:

  ```bash
  brew install swiftlint
  ```

  Run it from the repository root before opening a PR:

  ```bash
  swiftlint
  ```

- [`diff-image`](https://github.com/ewanmellor/git-diff-image) for inspecting
  snapshot-test PNG diffs in `git diff`. The tool wraps ImageMagick, so install
  ImageMagick first, then clone and install `diff-image`:

  ```bash
  brew install imagemagick
  git clone https://github.com/ewanmellor/git-diff-image.git
  cd git-diff-image && make install
  ```

  Enable it as a git diff driver for this repository so PNG snapshots render
  side-by-side image diffs instead of binary `Binary files ... differ` lines:

  ```bash
  git config diff.image.command 'diff-image'
  echo '*.png diff=image' >> .git/info/attributes
  ```

## Repository layout

```
.
├── Sources/MarkdownText/         # The SwiftStreamingMarkdown library
│   ├── Block/                    # Block-level converters
│   ├── Citation/                 # Inline citation attachments and coder
│   ├── ContextMenu/              # Text-selection context menu APIs
│   ├── Inline/                   # Inline markup converters
│   ├── Models/                   # Public configuration & data types
│   ├── Parser/                   # Markdown + LaTeX pre-processing
│   ├── Resources/                # Bundled assets (icons, etc.)
│   ├── Style/                    # Typography, colors, fonts
│   ├── TextTransition/           # Streaming fade-in animations
│   ├── UI/                       # SwiftUI + UIKit rendering surfaces
│   └── Utilities/                # Shared helpers
├── Tests/MarkdownTextTests/      # Unit and snapshot tests
├── Examples/
│   └── SwiftStreamingMarkdownSample/   # Sample iOS app
└── docs/                         # Documentation, dependency inventory
```

## Building and testing

The package is checked in CI with `xcodebuild`. From the repository root:

```bash
# Run the full test suite (unit + snapshot)
xcodebuild test \
  -scheme SwiftStreamingMarkdown \
  -destination "platform=iOS Simulator,OS=26.4.1,name=iPhone 17" \
  -skipMacroValidation

# Build the sample app
xcodebuild build \
  -project Examples/SwiftStreamingMarkdownSample/SwiftStreamingMarkdownSample.xcodeproj \
  -scheme SwiftStreamingMarkdownSample \
  -configuration Debug \
  -destination "platform=iOS Simulator,OS=26.4.1,name=iPhone 17" \
  -skipMacroValidation \
  CODE_SIGNING_ALLOWED=NO
```

You can also open `Package.swift` directly in Xcode (`xed Package.swift`) and
use the standard ⌘U / ⌘B keybindings.

### Snapshot tests

UI rendering is verified with [`swift-snapshot-testing`](https://github.com/pointfreeco/swift-snapshot-testing).
The first run on a new device/OS combination will record fresh references and
then fail; re-run the suite to confirm the recorded images are stable. Commit
the generated PNGs in `Tests/MarkdownTextTests/__Snapshots__/` alongside your
code change. Keep the reference simulator the same as CI (`iPhone 17` on iOS
26.4.1) to avoid spurious diffs.

When a snapshot test fails, review the regenerated PNG with `diff-image` (see
[Requirements](#requirements)) — `git diff Tests/MarkdownTextTests/__Snapshots__/`
will render a side-by-side visual diff instead of the default binary marker.

## Coding conventions

- **Linting**: run `swiftlint` from the repository root before opening a PR
  and resolve any warnings introduced by your change.
- **Indentation**: two spaces, no tabs.
- **Access control**: prefer `internal` (the default). Only mark a symbol
  `public` if it must cross the module boundary. When in doubt, leave it
  `internal` and let a follow-up promote it on demand.
- **Doc comments**: every `public` symbol gets a `///` comment that explains
  what it is and any non-obvious behavior. Non-public symbols generally do
  not need them; let the names and call sites speak for themselves.
- **No `print(...)` in library code**: surface diagnostics through
  `MarkdownListener` so consumers can route them.
- **SwiftUI structs use the `@Equatable` macro** instead of hand-rolled
  `==` implementations whenever the property set permits it.
- **Streaming-safety**: the parser is expected to be called repeatedly with
  growing input. New features must preserve partial-render correctness;
  add a streaming fixture or snapshot test where appropriate.

## Branches and pull requests

- Branch off `main`. Use a short, descriptive branch name.
- Keep PRs focused. Mixing unrelated refactors with feature work makes
  review slower and risks blocking the whole change on a single concern.
- Reference an issue (or open one first) and use `Closes #N` in the PR
  description so the issue auto-closes on merge.
- Fill in the [pull request template](.github/pull_request_template.md),
  including the OSS-readiness checklist.
- **Never force-push** to a branch with an open PR; add a follow-up commit
  instead.
- Squash-merge is the default. The PR title becomes the commit title, so
  write it in sentence case (no `[TAG]` prefixes) and keep it descriptive.

### Commit messages

Bodies are optional but encouraged when the change is non-trivial. Wrap at
72 columns. When the PR is authored with assistance from GitHub Copilot,
include the standard co-author trailer:

```
Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

## Adding or upgrading a dependency

1. Update `Package.swift` and run a build to refresh `Package.resolved`.
2. Add or update the entry in [`docs/dependency-inventory.md`](docs/dependency-inventory.md).
3. Add or update the entry in [`NOTICE`](NOTICE).
4. Confirm the dependency is MIT- or Apache-2.0-licensed (or open a
   discussion before adding anything else).

## Filing issues

- Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.yml) for
  rendering or parsing problems. Including the minimal markdown input that
  reproduces the issue is the single biggest accelerator.
- For ideas and feature discussions, open a regular issue and tag it
  `enhancement`.

## Releasing

Releases are tagged from `main` after the changelog's `[Unreleased]` section
has been promoted to a versioned section. SemVer applies; while the package
is pre-1.0, source-breaking changes are allowed in minor releases but must
be called out in `CHANGELOG.md`.
