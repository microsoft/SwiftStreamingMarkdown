# Citation Format

The renderer supports inline citation markers that can be converted into tappable citation pills. The public API should not assume a product-specific marker format.

## Goals

- Preserve inline citation rendering during streaming.
- Keep citation parsing configurable.
- Make citation taps accessible and host-controlled.
- Avoid embedding service-specific IDs in UI components.

## Recommended model

```text
Citation(
  id: String,
  title: String?,
  url: URL?,
  range: source text range or token metadata
)
```

Hosts provide a parser that maps source markdown tokens to citation models. Renderers display citations and call `onCitationTap(citation)` when selected.

The default mobile configuration recognizes two product-neutral forms:

```markdown
Footnote-style marker [^source-1]
Citation link [1](citation://source-1?title=1&fullTitle=Example%20Source)
Marked URL [1](https://example.com/source?citation=true&title=1)
```

iOS also exposes `CitationMarkerPattern` so hosts can provide a custom regex, captured ID/title/source groups, citation-link query names, and the accessibility label prefix without changing renderer code.

## Accessibility

Citation pills should expose a readable label such as `Citation: <title>` or `Citation <number>` and should be keyboard/screen-reader reachable where the platform supports it.

## Fixture coverage

Use `samples/streaming-fixtures/citations.md` and `mixed-long-response.md` to test adjacent citations, citations near punctuation, and citations that arrive before their visible label is complete.
