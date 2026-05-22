# Agent Guide

Use the local `Makefile` for setup, validation, and demo commands. Run `make help` to see the current target list. Test user-visible renderer changes with the simulator demo when practical.

## Requirements

- Xcode command line tools with `swift`, `xcodebuild`, and `xcrun`.
- XcodeGen for the demo project: `brew install xcodegen`.

If SwiftPM package resolution fails with `safe.bareRepository is 'explicit'`, rerun with a scoped Git override:

```sh
GIT_CONFIG_COUNT=1 \
GIT_CONFIG_KEY_0=safe.bareRepository \
GIT_CONFIG_VALUE_0=all \
make test
```

## Build and test

```sh
make build      # Build the Swift package
make test       # Run Swift package tests
make run-demo   # Build, install, and launch the iOS Simulator demo
```

## Implementation direction

This project is an extraction/port of the production mobile markdown renderer, not a simplified rewrite. Preserve the full behavior of the source app code wherever possible.

- Treat current simplified parser/renderer code as temporary scaffolding unless it has been proven equivalent to the production implementation.
- Prefer porting/adapting code and tests from the source app over inventing smaller approximations.
- Only change what is needed for OSS boundaries: product-neutral names, package structure, public APIs, dependency replacement, design-system hooks, telemetry/logging removal, build wiring, and license/notice hygiene.
- When replacing an internal dependency, preserve the observable renderer behavior and add parity tests or fixtures that prove the replacement.
- Do not mark a feature complete because the demo works; mark it complete when it matches the source app behavior or the plan explicitly documents an accepted divergence.

## Run demo app

The demo target uses the simulator configured in `Makefile` (`IOS_DEMO_SIMULATOR`, default `iPhone 17 Pro`). Override it when needed:

```sh
make run-demo IOS_DEMO_SIMULATOR="iPhone 16"
```
