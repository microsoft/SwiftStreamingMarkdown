# Contributing

Thanks for helping prepare StreamingMarkdown for iOS for open source use.

## Before you start

- Keep APIs product-neutral and platform-appropriate.
- Do not introduce internal service names, private URLs, telemetry IDs, aliases, or issue links.
- Prefer configuration and callbacks over app-specific behavior.
- Keep source fixtures in `samples/streaming-fixtures/` and regenerate package resources with `make sync-fixtures`.
- Do not add or change third-party dependencies without updating `docs/dependency-inventory.md` and `NOTICE`.

## Pull request checklist

- Update docs or fixtures when behavior changes.
- Preserve third-party notices for dependencies and bundled assets.
- Add tests or demo coverage for streaming edge cases.
- Verify incomplete markdown remains stable while chunks are appended.
- Run available checks before requesting review.
- Note any dependency, license, security, or package-publishing impact in the PR.

## Style

Use concise names that describe markdown behavior rather than product concepts. Keep comments focused on non-obvious streaming, accessibility, or parsing decisions.
