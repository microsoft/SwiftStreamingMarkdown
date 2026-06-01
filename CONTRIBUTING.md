# Contributing to SwiftStreamingMarkdown

Thanks for taking the time to look at how you can help out. SwiftStreamingMarkdown stays useful because people like you file bugs, sharpen the documentation, sketch out sample snippets, and occasionally send code. Whatever you're up for, it's appreciated — there is no "too small" contribution.

If you are new to open source and want a gentle on-ramp, the [GitHub guide to contributing](https://opensource.guide/how-to-contribute/) is a solid first read. After that, browsing the open issues and pull requests on this repo is the fastest way to see what the project is currently chewing on and where help is welcome.

A few ground rules to keep things moving for everyone:

## Join the existing discussions

Before opening something new, scan the open issues and pull requests. If your idea or bug is already being talked about, chiming in there — even with a "I hit this too on iOS X" — is more useful than a fresh thread, because it helps us see which problems hit the most people. If you have already worked around a problem, sharing the workaround is gold.

## Help the documentation along

The README, the DocC comments in `Sources/`, and the sample app under `Examples/` are all fair game. If something tripped you up while integrating the package, that is a strong signal the docs can be clearer. Small PRs that fix a confusing sentence, add a missing snippet, or expand on an edge case are very welcome and are usually the easiest contributions to get merged.

## Where to ask questions

GitHub Issues on this repo are for bugs and concrete feature proposals, not a general support channel. If you are stuck on "how do I use SwiftStreamingMarkdown to do X", the best first stop is the README and the sample app. If you still need help and the question is generic enough that other developers might hit it, [Stack Overflow](https://stackoverflow.com/) is a better venue than an issue — your answer will then be discoverable by everyone else with the same problem.

We may close issues that are really support requests and point back here. That is not a brush-off; it is just to keep the issue tracker focused on things the maintainers can actually act on.

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

1. Run `scripts/dev-setup.sh` once on your machine so you have the same tools CI uses (SwiftLint, ImageMagick, `diff-image`).
2. Fork the repo and branch from the most recent `main` to minimize merge conflicts.
3. Keep the change focused — one logical change per PR is much easier to review than a grab-bag.
4. If you are adding behavior, add a test. The package uses XCTest under `Tests/`; many UI surfaces are covered by snapshot tests.
5. If you change a public API, update the DocC comments and the README where it shows up.
6. If you touch rendered output, update the snapshot fixtures and review the `diff-image` output yourself before pushing.
7. Make sure `swiftlint --strict` passes (CI runs this).
8. Make sure `xcodebuild test -scheme SwiftStreamingMarkdown` passes locally on an iOS simulator.

If you are unsure whether a feature is in scope, open an issue first to talk through the design. It is much less frustrating to align on the approach before you have spent an afternoon implementing it.

Thanks again for contributing — see you in the PR queue.
