SHELL := /bin/sh

IOS_DEMO_DIR := DemoApp
IOS_DEMO_PROJECT := StreamingMarkdownDemo.xcodeproj
IOS_DEMO_SCHEME := StreamingMarkdownDemo
IOS_DEMO_SIMULATOR ?= iPhone 17 Pro
IOS_DEMO_DESTINATION ?= platform=iOS Simulator,name=$(IOS_DEMO_SIMULATOR)
IOS_DEMO_DERIVED_DATA := $(IOS_DEMO_DIR)/DerivedData
IOS_DEMO_APP := $(IOS_DEMO_DERIVED_DATA)/Build/Products/Debug-iphonesimulator/$(IOS_DEMO_SCHEME).app
IOS_DEMO_BUNDLE_ID := dev.streamingmarkdown.demo.ios
SHARED_FIXTURES_DIR := samples/streaming-fixtures
IOS_FIXTURES_DIR := Sources/StreamingMarkdown/Resources/StreamingFixtures
XCODEBUILD ?= xcodebuild
XCRUN ?= xcrun
XCODEGEN ?= xcodegen
CLOC ?= cloc

.DEFAULT_GOAL := help

.PHONY: help cloc check-cloc check-xcodebuild check-xcrun check-xcodegen sync-fixtures build test run-demo clean

help: ## Show available make targets.
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_.-]+:.*##/ {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check-cloc:
	@command -v "$(CLOC)" >/dev/null 2>&1 || { \
		echo "cloc is required. Install it with: brew install cloc" >&2; \
		exit 127; \
	}

check-xcodebuild:
	@command -v "$(XCODEBUILD)" >/dev/null 2>&1 || { \
		echo "xcodebuild is required to build the iOS demo. Install Xcode first." >&2; \
		exit 127; \
	}

check-xcrun:
	@command -v "$(XCRUN)" >/dev/null 2>&1 || { \
		echo "xcrun is required to launch the iOS demo. Install Xcode first." >&2; \
		exit 127; \
	}

check-xcodegen:
	@command -v "$(XCODEGEN)" >/dev/null 2>&1 || { \
		echo "xcodegen is required to generate the iOS demo project. Install it with: brew install xcodegen" >&2; \
		exit 127; \
	}

cloc: check-cloc ## Count code in tracked and unignored files.
	@tmp=$$(mktemp); \
	trap 'rm -f "$$tmp"' EXIT; \
	git ls-files --cached --others --exclude-standard > "$$tmp"; \
	"$(CLOC)" --list-file="$$tmp"

sync-fixtures: ## Copy shared markdown fixtures into generated package resources.
	@mkdir -p "$(IOS_FIXTURES_DIR)"
	@rm -f "$(IOS_FIXTURES_DIR)"/*.md
	@cp "$(SHARED_FIXTURES_DIR)"/*.md "$(IOS_FIXTURES_DIR)/"

build: sync-fixtures ## Build the Swift package.
	@swift build

test: sync-fixtures ## Run Swift package tests.
	@swift test

run-demo: sync-fixtures check-xcodegen check-xcodebuild check-xcrun ## Build and launch the iOS demo app in Simulator.
	@cd "$(IOS_DEMO_DIR)" && "$(XCODEGEN)" generate
	@cd "$(IOS_DEMO_DIR)" && "$(XCODEBUILD)" -project "$(IOS_DEMO_PROJECT)" -scheme "$(IOS_DEMO_SCHEME)" -destination "$(IOS_DEMO_DESTINATION)" -derivedDataPath DerivedData build
	@open -a Simulator
	@"$(XCRUN)" simctl boot "$(IOS_DEMO_SIMULATOR)" >/dev/null 2>&1 || true
	@"$(XCRUN)" simctl bootstatus "$(IOS_DEMO_SIMULATOR)" -b
	@"$(XCRUN)" simctl install "$(IOS_DEMO_SIMULATOR)" "$(IOS_DEMO_APP)"
	@"$(XCRUN)" simctl launch "$(IOS_DEMO_SIMULATOR)" "$(IOS_DEMO_BUNDLE_ID)"

clean: ## Remove SwiftPM and demo build outputs.
	@swift package clean
	@rm -rf "$(IOS_DEMO_DERIVED_DATA)"
