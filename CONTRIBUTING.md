# Contributing to SwiftStreamingMarkdown

First of all, thank you for your interest in this project.
Every contribution matters — bug reports, documentation fixes, sample
fixtures, and code changes are all welcome and equally appreciated.
We are all owners, from the people who started the project to the people
who use it and pitch in on a conversation, improve the docs, share an
example, or send a patch.

If you'd like to help but don't know where to begin, start small:

- read [opensource.guide/how-to-contribute](https://opensource.guide/how-to-contribute/)
- skim the open issues and pull requests to see what's in flight
- jump into a discussion if you have something to add — questions,
  experience reports, and alternative approaches are all useful

We want to make contributing as easy and transparent as possible. The
guidelines below are meant to keep the process light while making sure
changes can be reviewed and shipped quickly.

## Code of conduct

This project has adopted the
[Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
By participating you agree to abide by its terms.

## Security

Please do not file security vulnerabilities as public issues. See
[`SECURITY.md`](SECURITY.md) for the responsible-disclosure process.

## Contribute to ongoing conversations

If you have a valid opinion about something we're discussing, share it.
If you also ran into the issue someone else described, pitch in. Better
yet, if you already worked around it or have a fix in mind, share that.

## Improving documentation

A project's documentation is something you can always improve on. If
something in the README, header docs, or sample app is unclear or out of
date, opening a PR with a fix is one of the most valuable contributions
you can make. Examples and sample snippets are equally welcome.

## Asking questions

We don't use GitHub issues as a support forum. For general usage
questions please open a
[Discussion](https://github.com/microsoft/SwiftStreamingMarkdown/discussions)
or ask on Stack Overflow. By doing so you'll be more likely to quickly
solve your problem, and you'll allow anyone else with the same question
to find the answer. This also lets maintainers focus on improving the
project for everyone.

## Reporting issues

A great way to contribute is to send a detailed issue when you hit a
problem. Before opening a new issue, please check the existing ones — if
you find a match, just add a small comment there. Doing this helps
prioritize the most common problems and requests.

When reporting an issue, please include:

- The iOS version and device/simulator you're running on
- The SwiftStreamingMarkdown version (or commit SHA)
- The integration method (Swift Package Manager URL + version)
- The Xcode version you're using
- A minimal markdown sample — and, where relevant, the streaming chunk
  boundaries — that reproduces the problem
- The actual vs. expected rendering, ideally with screenshots
- Any console output, stack trace, or compiler error

A small demo project that replicates the issue is the single biggest
accelerator for getting a fix landed.

Please don't be offended if we close your issue and reference this
document. If you believe the issue is truly a fault in the project's
codebase, re-open it.

## Pull requests

We gladly accept PRs that are focused, well described, and — when
behavior changes — accompanied by tests. If you're unsure whether a new
feature will be accepted, please open an issue or discussion first so we
can talk through the design before you spend time on a patch.

Checklist:

- Fork the repo and create your branch from the latest `main` (to
  minimize conflicts).
- If you've added code that should be tested, add tests (unit and/or
  snapshot).
- If you've changed APIs, update the doc-comments and README.
- Ensure the test suite passes.
- Make sure your code lints (`swiftlint` from the repository root).

## Tooling

You will need the following installed locally to build, test, and review
changes:

- macOS 14+ with Xcode 16+ (Swift 5.9 toolchain) and any iOS 16+
  simulator. CI runs against iPhone 17 on iOS 26.4.1; matching that
  combo locally avoids spurious snapshot diffs.
- [SwiftLint](https://github.com/realm/SwiftLint) for enforcing Swift
  style:

  ```bash
  brew install swiftlint
  ```

- [`diff-image`](https://github.com/ewanmellor/git-diff-image) for
  reviewing snapshot-test PNG diffs in `git diff`:

  ```bash
  brew install imagemagick
  git clone https://github.com/ewanmellor/git-diff-image.git
  cd git-diff-image && make install
  git config diff.image.command 'diff-image'
  echo '*.png diff=image' >> .git/info/attributes
  ```
