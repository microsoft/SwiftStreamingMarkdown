# OSS Release Checklist

This checklist tracks remaining work before publishing the iOS package as Microsoft-owned open source.

## Policy gates

- [x] Confirm whether the iOS package qualifies for the small-tool exception when counted as tracked iOS code/config; current `cloc` count is 4,607 code lines, and SwiftPM consumer-installed dependencies are not third-party distributions under the release policy.
- [ ] Release under MIT unless OSPO/CELA approves another OSI-approved license.
- [ ] Confirm the repository is created or transferred under an approved Microsoft-managed GitHub organization through the Open Source Management Portal.
- [ ] Complete OSPO/CELA review for third-party dependencies, package publishing, naming, and any privacy/trademark/open-data/responsible-AI considerations that apply.
- [ ] Run Component Governance on the final SwiftPM manifest and resolve security, malware, and legal alerts before release.
- [ ] Run formal secret scanning before public visibility changes.
- [ ] Configure the GitHub security baseline for the final repo: classification, two durable direct owners, secret scanning, CodeQL where applicable, Dependabot, JIT-only admin, and branch protection.
- [ ] Confirm CLA automation is active.

## Legal and attribution

- [ ] Replace `NOTICE` summary rows with exact required upstream copyright notices, license references, and attribution text from final approved dependencies.
- [ ] Add copyright headers if required by CELA.
- [ ] Ensure third-party IP is handled in a way acceptable under the Third Party IP Policy.

## Source hygiene

- [x] Remove Android/Java/Kotlin/Compose/JVM references from the iOS demo and sample fixtures.
- [ ] Re-run scans for internal URLs, issue links, aliases, tenant IDs, private package feeds, telemetry IDs, secrets, and product-only service names.
- [ ] Verify all external dependencies come from public package sources.
- [ ] Verify generated demo assets and build outputs are ignored or reproducible.
- [ ] Confirm source history is fresh/public-safe if the release uses a new public repository.

## Community and operations

- [x] Add `LICENSE`, `NOTICE`, `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, and `CODE_OF_CONDUCT.md`.
- [x] Add CI and Dependabot configuration.
- [x] Add PR and issue templates.
- [x] Add `CHANGELOG.md` and `SUPPORT.md` placeholders.
- [ ] Add final CODEOWNERS once the GitHub team or maintainer handles are known.
- [ ] Add screenshots or short demo GIFs.

## Small tool exception check

The release policy's small tool exception applies only when all of these are true. The current assessment is based on the policy at `https://docs.opensource.microsoft.com/legal/policies/release/#small-tool-exception`.

- [x] MIT license.
- [x] Under 5,000 lines of code, including generated code. `cloc` reports 4,607 code lines for tracked iOS Swift/YAML/Makefile files.
- [x] No third-party code or content distribution. Runtime dependencies are SwiftPM package-manager dependencies installed by consumers, which the release policy does not treat as distributions.
- [x] No telemetry or other privacy requirements in the renderer.
- [x] No cryptography.
- [x] No data release.
- [x] No AI/ML models, components, or weights.

## Package publishing

- [ ] Decide whether iOS is SwiftPM-only for the first release or also needs CocoaPods.
- [ ] Confirm package name, module name, and repository URL.
- [ ] Tag the first release with a semver version and update package manifests from `0.1.0-SNAPSHOT` if needed.
- [ ] Include final compliance artifacts with packages where required: NOTICE/BOM, license file, and source/artifact metadata.

## Final validation

- [ ] `make test`
- [ ] `make build`
- [ ] `make run-demo`
- [ ] Public dry-run: clone in a clean environment and build without internal credentials, feeds, or VPN-only services.
