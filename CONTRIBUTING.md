# Contributing to SwiftStreamingMarkdown

We welcome everyone to contribute and make this library better!

## Join the existing discussions

Before opening something new, scan the open issues and pull requests. If your idea or bug is already being talked about, chiming in there — even with a "I hit this too on iOS X" — is more useful than a fresh thread, because it helps us see which problems hit the most people. If you have already worked around a problem, sharing the workaround is gold.

## Filing a bug

When you do file a bug, the more context you give us, the faster we can help. Please include:

- The iOS version (and Mac Catalyst / visionOS / etc. if relevant) where you saw the issue
- The version of SwiftStreamingMarkdown you are on (commit SHA or tag)
- The Xcode version you built with
- How you integrated the package (Swift Package Manager via Xcode, SPM via `Package.swift`, etc.)
- The full text of any stack traces, compiler errors, or SwiftUI runtime warnings
- A minimal sample — ideally a small Xcode project or a snippet against the bundled `SwiftStreamingMarkdownSample` app — that reproduces the problem
- Anything else that you think is relevant: streaming source, markdown input, custom theme, etc.

If we close an issue and link back to this section, it usually means one of these pieces was missing. Re-open the issue once you have the missing info — we are not trying to wave you off.

## Sending a pull request

PRs are very welcome. To keep the review loop short, please follow these steps before opening one:

1. Run `make dev-setup` once on your machine so you have the tools used by CI and local helper targets (SwiftLint, XcodeGen, `cloc`, ImageMagick, `diff-image`).
2. Fork the repo and branch from the most recent `main` to minimize merge conflicts.
3. Keep the change focused — one logical change per PR is much easier to review than a grab-bag.
4. If you are adding behavior, add a test. The package uses XCTest under `Tests/`; many UI surfaces are covered by snapshot tests.
5. If you change a public API, update the DocC comments and the README where it shows up.
6. If you touch rendered output, update the snapshot fixtures and review the `diff-image` output yourself before pushing.
7. Run `make ci` before pushing. Use `make lint`, `make test`, or `make build-sample` for targeted checks while iterating.
8. Use `make project` to open the Swift package in Xcode or `make sample-project` to generate and open the sample app. Use `make cloc` when you need a Git-backed line-count report.

If you are unsure whether a feature is in scope, open an issue first to talk through the design. It is much less frustrating to align on the approach before you have spent an afternoon implementing it.

Thanks again for contributing — see you in the PR queue.
