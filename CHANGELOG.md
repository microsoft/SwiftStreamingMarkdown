# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

While the package is pre-1.0, minor releases may include source-breaking
changes; they will be called out explicitly in this file.

## [Unreleased]

### Added
- Doc-comments on every public symbol across the Parser, Models, Citation,
  ContextMenu, and public `View` surfaces.
- `MarkdownRenderConfig.defaultBlockQuoteStyle`, `defaultHeadingStyle`,
  `defaultOrderedListStyle`, `defaultParagraphStyle`, `defaultTableStyle`,
  and `defaultInlineStyle` public statics, used as the default values for
  the `MarkdownRenderConfig` initializer.

### Changed
- `MarkdownParseOption.LatexMatching` is now configurable per-parse; the
  default matches the prior all-rules behavior.
- Repository documentation: README, CODE_OF_CONDUCT, NOTICE, and
  `docs/dependency-inventory.md` added for open-source readiness.

### Removed (internal, no public API impact)
- Demoted to `internal` (previously `public` but never used outside the
  module): `Color.Static`, `Color.Theme`, `Typography`, `BlockMathView`,
  `CodeBlockView`, `EdgeBorder` plus `View.border(width:edges:color:)`,
  `MarkdownController` members (init and seven methods; the type itself
  remains public so it can be supplied via the SwiftUI environment),
  `NSAttributedString.splitIntoWords`, `Task.sleep(seconds:)` and
  `sleep(ms:)`, the `View+TrackSize` modifiers,
  `View.font(_:bold:italic:)`, `TextFonts.italicize` and `bold`,
  `ListItem.startsWithBold`, and the entire `FadeInTextTransition` group
  (modifier, config enum, and both transition structs). The companion
  computed properties and helpers on `RenderableDocument`,
  `MarkdownRenderable`, and `MarkdownListItem` were also demoted.
- Deleted dead code: `Sources/MarkdownText/Utilities/NSMutableAttributedString+.swift`,
  the `View.borderRadius` extension, and the `RoundedCorner` shape.

[Unreleased]: https://github.com/microsoft/SwiftStreamingMarkdown/compare/main...HEAD
