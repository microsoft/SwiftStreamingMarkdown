<!-- BEGIN MICROSOFT SECURITY.MD V1.0.0 BLOCK -->

## Security

Microsoft takes the security of our software products and services seriously, which
includes all source code repositories in our GitHub organizations.

**Please do not report security vulnerabilities through public GitHub issues.**

For security reporting information, locations, contact information, and policies,
please review the latest guidance for Microsoft repositories at
[https://aka.ms/SECURITY.md](https://aka.ms/SECURITY.md).

<!-- END MICROSOFT SECURITY.MD BLOCK -->

## Security expectations

- Do not commit secrets, internal URLs, telemetry keys, service endpoints, or private identifiers.
- Treat markdown input as untrusted content.
- Treat raw HTML and Mermaid input as untrusted content. This renderer exposes fallback rendering only; hosts should not execute scripts or fetch remote content on behalf of markdown.
- Route link handling through host-provided callbacks.
- Keep copy/export actions explicit and user initiated.
