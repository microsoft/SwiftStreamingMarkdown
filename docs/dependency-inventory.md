# Dependency Inventory

This inventory tracks dependencies expected during the iOS renderer extraction. Legal approval is not implied by this file; final release still needs OSPO/CELA dependency review, Component Governance results, and exact third-party notices.

## iOS

| Dependency | Version / pin | Purpose | Release-prep action |
| --- | --- | --- | --- |
| swift-markdown | 0.7.3 exact | Markdown parsing and AST support | Keep; Apache 2.0 notice. |
| HighlightSwift | 99c431b38a1444a5fd6a4978307fbbefe3a7af53 | Syntax highlighting for code blocks | Keep as default highlighter path with injectable override; MIT notice. |
| iosMath | 066ba2f8353782a644889efe9ceb884ea844180b | Inline and block math rendering | Keep as default iOS math backend; MIT notice. |
| SVGView | Not present in current manifest | SVG/image rendering support | No action unless reintroduced. |
| AsyncExtensions | Not present in current manifest | Async stream utilities | No action unless reintroduced. |
| Internal design system/icons/fonts | Not present in current manifest | Styling and assets | Replaced with public design-system tokens and SF/system fallbacks. |
| Internal logging/analytics/test helpers | Not present in current manifest | Observability and tests | Replaced by host callbacks and XCTest tests. |

## Release inventory tasks

1. Copy required license texts or links into release artifacts for the pinned dependencies above.
2. Re-run dependency review before publishing artifacts.
3. Verify no internal-only dependency remains in public package manifests.
4. Run Component Governance on the final repository state and attach or archive the approved inventory.
5. Resolve every Component Governance security, malware, and legal alert before release.
6. Confirm the release artifacts include the approved NOTICE/BOM.
