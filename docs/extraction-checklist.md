# Extraction Checklist

Use this checklist while preparing the iOS streaming markdown renderer for a public repository.

## Shared release work

- [x] Use fresh public history and product-neutral package names for the extracted package surface.
- [x] Remove internal URLs, issue IDs, aliases, telemetry keys, and service names from package source.
- [x] Replace telemetry with opt-in callbacks.
- [x] Keep link, citation, copy, and export behavior behind host callbacks.
- [x] Preserve third-party notice inventory in `NOTICE`.
- [ ] Run formal secret scanning and dependency review before release.
- [ ] Complete OSPO/CELA review for MIT license confirmation, NOTICE content, dependencies, and package publishing.
- [ ] Enable GitHub security baseline: repo classification, two durable direct owners, JIT-only admin, security advisories, secret scanning, CodeQL where applicable, Dependabot, branch protection, and required CI checks.
- [ ] Run Component Governance and resolve security, malware, and legal alerts.
- [ ] Add final CODEOWNERS when maintainer handles are known.
- [x] Validate all fixtures in `samples/streaming-fixtures` with parser tests.
- [x] Validate all fixtures at chunked streaming boundaries with parser tests.
- [x] Document fixture coverage as the regression floor and production parser/render behavior as the parity target.

## iOS

- [x] Extract the SwiftUI renderer into `Sources/StreamingMarkdown`.
- [x] Replace internal design tokens with default styles and configuration.
- [x] Replace internal logging with host callbacks and no renderer-owned telemetry.
- [x] Keep `iosMath` as the math backend.
- [x] Make citation marker parsing configurable.
- [x] Add tests for partial tables, incomplete emphasis, code fences, math, and citations.
- [x] Preserve malformed math source text instead of rendering an empty math view.
