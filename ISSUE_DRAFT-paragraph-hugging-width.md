# Draft: paragraph/heading blocks always report full offered width, breaking width-hugging containers

Status: **draft, not yet filed upstream.** Written on branch `fix-paragraph-hugging-width` (based on
`main` @ `a4187829013c4588556d82dbf1ab65ed768a0262`) to open as an issue + PR in a future session -
not filed yet.

## Environment

- iOS 18 Simulator (iPhone 17 Pro), also affects iOS 16/17 (same code path)
- SwiftStreamingMarkdown @ `main` (`a4187829013c4588556d82dbf1ab65ed768a0262`)
- Xcode 26.6 (Build 17F113)
- Integrated via SPM, `.package(url: "https://github.com/microsoft/SwiftStreamingMarkdown", branch: "main")`
- Downstream consumer: [Threadwire](https://github.com/ramonfsk/threadwire) - a chat SDK rendering
  `MarkdownView` inside chat bubbles that hug their content width, capped at 80% of screen width.

## The bug

`SingleBlockView` (`Sources/MarkdownText/UI/BlockView.swift`) renders every `.paragraph` and
`.heading` block as:

```swift
case .paragraph(_, let contents):
  HStack(spacing: 0) {
    ParagraphView(contents: contents, lineSpacing: 5)
      .fixedSize(horizontal: false, vertical: true)
      .transition(.opacity)
    Spacer()
  }
```

The trailing `Spacer()` has no `minLength`, which means it is maximally flexible: in SwiftUI's
`HStack` space-negotiation, non-flexible children (here, `ParagraphView`) get asked for and are
given their actually-needed width first, and the `Spacer()` - having no upper bound on how much
space it will take - absorbs *all* of whatever width remains from the `HStack`'s own **proposed**
width. Concretely: if this `HStack` is proposed 286pt (e.g. by an ancestor that wants to cap a chat
bubble at 80% of a ~360pt-wide phone), and the paragraph text only needs 60pt to render on one
line, the `HStack` still reports **286pt** as its own resolved width - the remaining 226pt is
invisible `Spacer` filler, but it's still real width that gets handed back up the view tree.

Any ancestor that tries to make a container *hug* this content (i.e. size itself to the text's
actual width, up to some cap - the standard SwiftUI pattern for that is exactly "propose a bounded
max width, let the child report back its true smaller size if it has one") gets lied to: it always
receives "the full proposed width," never the paragraph's real size. The bubble's background then
paints the full cap width for every message, even a one-word reply.

Confirmed the same behavior in both the git-checkout source and the version SPM actually resolves
into a real project's `DerivedData/.../SourcePackages/checkouts/SwiftStreamingMarkdown/...` - not
an artifact of a stale local checkout.

## Why this matters beyond "the bubble looks wide"

This is *the* standard SwiftUI pattern for chat bubbles / any hug-and-cap layout: a trailing
`Spacer(minLength: reserved)` on the far side lets non-flexible content report its true ideal size
while still capping how wide it's allowed to grow. `SingleBlockView`'s own unconditional `Spacer()`
defeats that pattern for any consumer embedding `MarkdownView`/`DocumentView` this way - which is
presumably a common integration shape for a "streaming markdown for chat" library.

## Proposed fix

Remove the `HStack { ParagraphView(); Spacer() }` wrapper entirely for `.paragraph` and `.heading`;
render `ParagraphView` directly:

```swift
case .heading(_, _, let contents):
  ParagraphView(contents: contents)
    .transition(.opacity)
    .accessibilityAddTraits(.isHeader)
case .paragraph(_, let contents):
  ParagraphView(contents: contents, lineSpacing: 5)
    .fixedSize(horizontal: false, vertical: true)
    .transition(.opacity)
```

This is safe because:

- `ParagraphView` is backed by a `UITextView` with `textAlignment = .left` (`ParagraphUIView.setupView()`),
  so left-alignment doesn't depend on the `HStack`/`Spacer` at all.
- `BlockView`'s outer `VStack` is already `alignment: .leading`, so a narrower-than-proposed
  paragraph still lands flush left, not centered.
- A consumer that *wants* the old full-bleed-fill behavior (e.g. embedding `MarkdownView` in a
  layout that should always stretch edge-to-edge) can still get it themselves by wrapping the
  whole `MarkdownView`/`DocumentView` in `.frame(maxWidth: .infinity, alignment: .leading)` from
  the outside - that's a caller-level decision, not something the library needs to force by
  default.

Full diff is on this branch (`fix-paragraph-hugging-width`), in
`Sources/MarkdownText/UI/BlockView.swift`.

## Validated

Applied this branch as a local SPM package override (`.package(path:)`) in Threadwire's `ui-ios`
target, rebuilt, and confirmed in the iOS Simulator:

- A short AI reply ("Hi there! How can I help you today?") now hugs to its actual text width
  instead of filling to the bubble's 80%-of-screen cap.
- A long, multi-paragraph streaming reply (including a heading and a bulleted list) still wraps
  and fills the cap width exactly as before - no regression to wrapping behavior for content that
  genuinely needs the full width.

## Not yet covered

- Did not audit `.latex`'s `ScrollView(.horizontal) { HStack { BlockMathView(); Spacer() } }` for
  the same class of bug - out of scope for this specific fix, but worth checking separately since
  it's the same pattern.
- No new snapshot tests added yet on this branch - the project's `make test` snapshot suite should
  be run and any affected fixtures reviewed before this goes up as a real PR (per `CONTRIBUTING.md`).
- Downstream (Threadwire) hit a *second*, related issue after adopting this fix: because hugging is
  now genuinely content-driven, a bubble's width - not just its height - changes on every
  incremental streaming chunk, which reflows line breaks non-monotonically mid-stream. That broke
  Threadwire's own chat-scroll auto-follow/jump-to-latest-button logic (a consumer-side concern,
  not a bug in this library) - still being investigated on the Threadwire side as of this writing,
  unrelated to whether this fix itself is correct.
