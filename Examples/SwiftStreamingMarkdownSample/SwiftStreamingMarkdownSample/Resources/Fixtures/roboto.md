# Roboto + Custom Palette

This demonstration replaces every typeface and color in `MarkdownRenderConfig` with a custom theme built on **Google Roboto** and a vivid teal-on-deep-purple palette.

## Headings ramp

# H1 — Big and tracked tight
## H2 — A touch smaller
### H3 — Section header
#### H4 — Subsection
##### H5 — Tertiary
###### H6 — Smallest

## Paragraphs and inline styles

Roboto Regular sets a relaxed reading rhythm with extra letter spacing and a 24 pt line height. **Bold runs glow amber** to draw the eye, while *italics keep their classic slant*. You can combine ***bold italic*** too.

Inline `code spans` use the system monospaced face on a deep navy chip with a subtle underline, so identifiers like `MarkdownRenderConfig`, `TextFonts`, and `CitationCoder` stand out from the prose without breaking the line.

Links such as [SwiftStreamingMarkdown on GitHub](https://github.com/microsoft/SwiftStreamingMarkdown) inherit the teal accent so they read as interactive without needing an underline.

## Lists

1. Ordered items use the same paragraph font.
2. Numbers stay aligned across multi-line entries that wrap.
3. Nested ordering also works:
   1. Sub-item one
   2. Sub-item two

- Unordered bullets share the body color
- Mix **emphasis**, *italics*, and `code`
- Nested bullets:
  - Indented one level
  - And again

## Block quote

> Theming should be a single struct away. Pass a different `MarkdownRenderConfig`, ship a custom font, and you have a different brand without touching the rendering code.

## Table

| Element | Font | Color |
| --- | --- | --- |
| Heading | Roboto Medium | Teal accent |
| Body | Roboto Regular | Near-white |
| Bold | Roboto Bold | Amber |
| Code | SF Mono | Cream on navy |

## Code block

```swift
let theme = MarkdownRenderConfig(
  paragraphStyle: .init(
    textFonts: robotoTextFonts(size: 16),
    textColor: .white
  ),
  inlineStyle: .init(
    boldTextColor: .orange,
    linkTextFont: roboto(16, weight: .medium),
    linkTextColor: .teal,
    codeTextFont: .monospacedSystemFont(ofSize: 15, weight: .regular),
    codeTextColor: .yellow,
    codeBackgroundColor: .black,
    codeUnderlineColor: .purple
  )
)
```

## Citation pill

Citations render as inline pills tinted with the accent color: see the source [9F742443](https://github.com/googlefonts/roboto-2?citationMarker=9F742443&citationTitle=Roboto%20Sample%20Source&citationA11yValue=Roboto%20Sample%20Source%20citation) for the original quote.
