# Design systems

The renderers separate visual tokens from markdown behavior. A design system supplies typography, colors, page/surface backgrounds, layout spacing, and component shape while parsing, citation callbacks, math rendering, and copy/export actions remain configured separately.

## Built-in presets

- `SF Pro`: the default iOS preset, following Apple's system typography, blue accent, grouped backgrounds, separators, and dynamic light/dark system colors.
- `System Default`: the original generic renderer styling, kept as a separate option for comparing against the platform-specific defaults.
- `Humanist`: the first exported product-style preset, based on the extracted Copilot mobile markdown renderer tokens with OSS-safe font fallbacks.
- `Humanist`: uses dynamic colors for light and dark appearance.
- `Serious Business`: mechanically mapped from the OCM Fluent/Rocksteady markdown renderer: Fluent neutral aliases, M365 brand links, OCM markdown heading/body/code typography, quote spacing, and table/code spacing.
- `Paperwork`: mechanically mapped from OfficeMobile SharedHub Fluent card tokens where this renderer has matching surfaces: brand foreground/tint/stroke colors over the same Fluent markdown typography and layout.
- `Tailored Suit`: mechanically mapped from Cowork markdown/card surfaces: shared OCM markdown typography with Cowork card/table foregrounds, background tokens, radius, and padding.
- `Jazz Hands`: mechanically mapped from the OfficeMobile/OCM Bebop markdown/table path: Bebop neutral aliases, foreground-colored links, transparent table header/cells, horizontal-border-style table approximations, and Bebop content typography where available.
- `Alternative Man`: inspired by ChatGPT's public web UI: clean neutral surfaces, rounded cards, green accents, subtle gray table/code treatments, and restrained sans-serif typography.
- `Rationalist`: inspired by Claude's public web UI: warm parchment surfaces, auburn accents, serif-forward reading typography, and softer document-like spacing.

The demo app includes selectors for fixture, design system, and appearance mode (`System`, `Light`, `Dark`). The selected design system drives the app page background, renderer surface background, control/event-log backgrounds, and markdown internals.

Motion policy is separate from visual design tokens. iOS uses `StreamingMarkdownAnimationPolicy.automatic` by default so reduce-motion settings disable streaming fades.

Action styling is part of the renderer design system. Code copy controls, table action buttons, and citation focus affordances use public action/focus color tokens instead of product icon or internal UI-foundation colors.

## iOS

```swift
let config = StreamingMarkdownConfiguration(designSystem: .humanist)

StreamingMarkdownView(
    text: streamedText,
    configuration: config
)
```

Custom styling:

```swift
let theme = StreamingMarkdownTheme(
    pageBackground: .white,
    surfaceBackground: .white.opacity(0.8),
    textFont: .body,
    linkColor: .purple,
    tableHeaderBackground: .purple.opacity(0.12)
)

let designSystem = StreamingMarkdownDesignSystem(
    name: "Acme",
    theme: theme,
    layout: .default
)
```
