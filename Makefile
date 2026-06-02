SHELL := /bin/bash

.DEFAULT_GOAL := help

IOS_DESTINATION ?= $(shell scripts/default-ios-destination.sh)
PACKAGE_SCHEME := SwiftStreamingMarkdown
SAMPLE_DIR := Examples/SwiftStreamingMarkdownSample
SAMPLE_SPEC := $(SAMPLE_DIR)/project.yml
SAMPLE_PROJECT := $(SAMPLE_DIR)/SwiftStreamingMarkdownSample.xcodeproj
SAMPLE_SCHEME := SwiftStreamingMarkdownSample
XCODEGEN ?= xcodegen
SWIFTPM_GIT_ENV := GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all

.PHONY: help
help: ## Show available targets.
	@color=0; \
	if [ -t 1 ] && [ -z "$${NO_COLOR:-}" ] && [ "$${TERM:-}" != "dumb" ]; then color=1; fi; \
	COLOR="$$color" awk 'BEGIN { \
		FS = ":.*## "; \
		if (ENVIRON["COLOR"] == "1") { bold = "\033[1m"; cyan = "\033[36m"; reset = "\033[0m" } \
		printf "%sAvailable targets:%s\n", bold, reset \
	} /^[a-zA-Z0-9_.-]+:.*## / {printf "  %s%-24s%s %s\n", cyan, $$1, reset, $$2}' $(MAKEFILE_LIST)

.PHONY: setup
setup: dev-setup ## Alias for dev-setup.

.PHONY: dev-setup
dev-setup: ## Verify local development tools.
	@bash scripts/dev-setup.sh

.PHONY: resolve
resolve: ## Resolve Swift package dependencies.
	@$(SWIFTPM_GIT_ENV) swift package resolve

.PHONY: project
project: resolve ## Open the Swift Package in Xcode.
	@xed .

.PHONY: generate-sample-project
generate-sample-project: ## Generate the sample app Xcode project.
	@command -v "$(XCODEGEN)" >/dev/null || { echo "error: xcodegen not found. Install it with 'brew install xcodegen' or run 'make dev-setup'."; exit 1; }
	@"$(XCODEGEN)" generate --spec "$(SAMPLE_SPEC)" --project "$(SAMPLE_DIR)"

.PHONY: sample-project
sample-project: generate-sample-project ## Generate and open the sample app Xcode project.
	@xed "$(SAMPLE_PROJECT)"

.PHONY: lint
lint: ## Run SwiftLint in strict mode.
	@swiftlint --strict

.PHONY: test
test: ## Run package unit tests.
	@$(SWIFTPM_GIT_ENV) xcodebuild test \
		-scheme "$(PACKAGE_SCHEME)" \
		-destination "$(IOS_DESTINATION)" \
		-skipMacroValidation

.PHONY: build-sample
build-sample: generate-sample-project ## Generate and build the sample app.
	@$(SWIFTPM_GIT_ENV) xcodebuild build \
		-project "$(SAMPLE_PROJECT)" \
		-scheme "$(SAMPLE_SCHEME)" \
		-configuration Debug \
		-destination "$(IOS_DESTINATION)" \
		-skipMacroValidation \
		CODE_SIGNING_ALLOWED=NO

.PHONY: ci
ci: lint test build-sample ## Run the same checks as CI.

.PHONY: cloc
cloc: ## Count code for Git-tracked files.
	@command -v cloc >/dev/null || { echo "error: cloc not found. Install it with 'brew install cloc'."; exit 1; }
	@cloc --vcs=git

.PHONY: clean
clean: ## Remove local SwiftPM build products.
	@rm -rf .build
	@rm -rf "$(SAMPLE_PROJECT)"
