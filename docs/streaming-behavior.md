# Streaming Behavior

Streaming Markdown renders text repeatedly as chunks arrive. The renderer should keep partial content readable, then converge to normal markdown output when the final chunk arrives.

## Principles

- Never crash on incomplete markdown.
- Preserve user-visible text even if syntax is not complete yet.
- Avoid large layout jumps when a partial construct becomes complete.
- Reparse or incrementally update only as much as needed for platform performance.
- Keep copy/export actions based on the latest stable rendered block.

## Important partial states

| Case | Expected behavior while streaming |
| --- | --- |
| Unclosed emphasis or strong markers | Show text plainly or with best-effort styling; finalize when closed. |
| Unclosed code fence | Render as a code block once the fence is recognized; update language when known. |
| Partial table header or separator | Keep rows readable; promote to table when a valid structure appears. |
| Inline math without closing delimiter | Show source text or pending math state; render math after delimiter arrives. |
| Math render failure | Preserve the equation as text; never drop the streamed content or replace it with an empty view. |
| Citation token split across chunks | Avoid broken controls; create citation pill after parser returns a complete citation. |
| Link missing closing text or URL | Show readable text and enable link only after complete. |

## Demo controls

The demo should support pause, resume, restart, jump-to-final, fixture selection, light/dark previews, and an event log for link, citation, copy, and table actions.

## Host events and exports

The renderer exposes product-neutral event hooks for hosts that want analytics, diagnostics, or logging without baking a telemetry pipeline into the library. Events cover parsing, speculative rewrites, first block display, link/citation activation, code copy, and table copy/export. Hosts are responsible for fan-out, sampling, persistence, and privacy policy decisions.

Table export payloads include Markdown, CSV, HTML, and plain-text/TSV-style strings. Markdown table output normalizes row width and flattens cell newlines because pipe tables cannot represent multiline cells directly; CSV and HTML preserve multiline cell content, with HTML escaping cell text before inserting `<br>` line breaks.

Citation presentation is configurable. The default keeps individual inline citation pills. Hosts can choose collapsed citation groups for dense citation runs, and iOS also exposes a UIKit-backed pill option for integrations that need UIKit view interoperability while retaining the product-neutral citation callback model.

## Motion and accessibility

- iOS defaults to `.automatic`, which follows the platform `accessibilityReduceMotion` environment value. Hosts can force animations on or off with `StreamingMarkdownAnimationPolicy`.
- Headings are marked as headings, code blocks expose code-oriented labels and copy controls, citation pills use stable labels, and table cells include row/column context where practical.

## Parser scope

This package is optimized for streamed app responses while tracking the production mobile app renderer as the functional target. Fixture coverage is the regression floor: the parser covers every fixture in `samples/streaming-fixtures/` at final and chunked streaming boundaries, preserves readable fallback text for incomplete syntax, and covers targeted app-parity cases for citations, math, tables, lists, block quotes, links, code fences, and raw HTML fallback.

iOS uses `swift-markdown` AST traversal as its primary block parser, matching the production parser direction while retaining streaming repair/fallback behavior.

## Manual accessibility smoke test

Before release, run each demo with the mixed, code, table, citations, and math fixtures. Verify that heading navigation reaches headings, code copy controls announce Copy/Copied feedback, citation pills announce stable labels and activate callbacks, table cells announce row/header context, and reduce-motion/remove-animation settings disable streaming fades.
