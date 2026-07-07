# Snapshot Tests Skill

Workflow for recording and validating swift-snapshot-testing snapshots in
the SwiftStreamingMarkdown package.

## When to use this skill

Trigger when the user asks anything that resolves to one of:

- **Record** — "record snapshots", "re-record the snapshots", "update
  snapshots", "regenerate references" → use [Mode 1](#mode-1-record-snapshots).
- **Validate** — "validate snapshots", "run snapshot tests", "check
  snapshots for regressions", "diff the failed snapshots" → use
  [Mode 2](#mode-2-validate-snapshots).

If the request is ambiguous (e.g. "fix the snapshot tests"), validate
first (Mode 2) and only re-record after the user confirms the visual
changes are intentional.

## Repo context

| Thing | Location |
|---|---|
| Base class for every snapshot test | `Tests/MarkdownTextTests/SnapshotTestFoundation/SnapshotTestCase.swift` |
| Recording toggle (committed commented out) | line 18 of that file: `// isRecording = true` |
| Diff-tool configuration | `SnapshotTesting.diffTool = "diff-image"` in `setUp()` (line 17) |
| Reference PNGs | `Tests/MarkdownTextTests/__Snapshots__/<TestClass>/` |
| Failed PNGs (written by the test run) | DerivedData; their absolute paths show up in failure messages |

Because `diffTool` is the string `"diff-image"`, swift-snapshot-testing
formats every failure message with a literal line shaped exactly like:

```
diff-image <reference-png-path> <failed-png-path>
```

That is the hook this skill keys off of.

## Build command

```bash
xcodebuild test \
  -scheme SwiftStreamingMarkdown \
  -destination "platform=iOS Simulator,OS=26.4.1,name=iPhone 17" \
  -skipMacroValidation 2>&1 | tee /tmp/snapshot-tests.log
```

Always `tee` to a log file — the Mode 2 grep below depends on it.

If the iPhone 17 / iOS 26.4.1 destination is unavailable on the
developer's machine, list installed simulators with
`xcrun simctl list devices available | head -30` and substitute an
equivalent iOS Simulator destination.

## Mode 1: record snapshots

1. **Uncomment** the recording flag:
   ```bash
   sed -i '' 's|// isRecording = true|isRecording = true|' \
     Tests/MarkdownTextTests/SnapshotTestFoundation/SnapshotTestCase.swift
   ```
2. **Verify** the toggle:
   ```bash
   grep -n "isRecording" Tests/MarkdownTextTests/SnapshotTestFoundation/SnapshotTestCase.swift
   ```
   Expect a single hit with `isRecording = true` and **no** leading `//`.
3. **Run the tests** using the build command above. Every snapshot test
   will fail — recording mode always emits a failure after it writes
   the new reference PNG. This is expected; do not treat it as an error.
4. **Restore** the comment — *always*, even if step 3 errored out:
   ```bash
   sed -i '' 's|^\([[:space:]]*\)isRecording = true|\1// isRecording = true|' \
     Tests/MarkdownTextTests/SnapshotTestFoundation/SnapshotTestCase.swift
   ```
5. **Re-verify**:
   ```bash
   grep -n "isRecording" Tests/MarkdownTextTests/SnapshotTestFoundation/SnapshotTestCase.swift
   ```
   Should once again show `// isRecording = true`.
6. **Report** to the user:
   ```bash
   git status Tests/MarkdownTextTests/__Snapshots__/
   ```
   Summarise which reference PNGs were added or changed, and remind the
   user to eyeball the diff before committing — recording overwrites
   references blindly, including wrong renders.

### Platform coverage: iOS records locally, macOS does not

A local `xcodebuild ... -destination "platform=iOS Simulator,..."` run only
regenerates the **iOS** variants (`iPhone16-*`, `iPadPro11-*`,
`iPadPro11Landscape-*`). The **macOS** variants (`macOS-standard-light`,
`macOS-standard-dark`) are *not* produced by that run.

**Do not record macOS references on a developer machine.** The macOS
variants use a strict `perceptualPrecision: 1.0`, so even a one-off
subpixel/font-rendering difference between a local macOS version and the CI
runner's macOS version fails validation. Locally-recorded macOS PNGs will
almost always mismatch CI.

macOS references are recorded by the dedicated **`Record macOS Snapshots`**
workflow (`.github/workflows/record-macos-snapshots.yml`), a
`workflow_dispatch` job on `runs-on: macos-26`. It flips `isRecording` on,
deletes the existing `*macOS*.png` references, re-records them with
`-destination "platform=macOS"`, and uploads the fresh PNGs as the
**`macos-snapshots`** artifact. (The record step's `continue-on-error: true`
means the run reports success even though `xcodebuild test` exits non-zero in
record mode.)

Note the workflow re-records the **entire** macOS suite, so the artifact
contains every `*.macOS-standard-*.png` — copy back **only** the files your
change actually affects, so you don't churn unrelated references against a
possibly-different runner rendering.

#### When the branch lives in `microsoft/SwiftStreamingMarkdown`

1. Push your branch (with re-recorded iOS references) to `origin`.
2. Run the workflow against it:
   ```bash
   gh workflow run "Record macOS Snapshots" --ref <branch>
   gh run watch "$(gh run list --workflow 'Record macOS Snapshots' \
     --branch <branch> --limit 1 --json databaseId -q '.[0].databaseId')" \
     --exit-status
   ```
3. Download the artifact and copy only the affected PNGs into place:
   ```bash
   gh run download <run-id> -n macos-snapshots -D /tmp/macos-snaps
   cp /tmp/macos-snaps/<TestMethod>.macOS-standard-*.png \
     Tests/MarkdownTextTests/__Snapshots__/<TestClass>/
   ```
4. Eyeball the PNGs, commit, and push.

#### When the branch lives on a fork (cross-repo PR)

`workflow_dispatch` only lists branches that exist in
`microsoft/SwiftStreamingMarkdown`; a fork PR's head branch is **not**
selectable, and the base repo cannot dispatch a workflow against a fork
branch. Mirror the branch onto `origin` first (requires write access to the
base repo — e.g. a maintainer updating a contributor's PR):

1. Check out the PR branch locally (`gh pr checkout <pr-number>`) and push a
   temporary mirror to `origin`:
   ```bash
   git push origin <local-branch>:pr-<n>-macos-record
   ```
2. Run `Record macOS Snapshots` against `pr-<n>-macos-record` (same
   `gh workflow run` / `gh run watch` as above). The mirror carries the same
   code state, so the recorded PNGs match the PR's rendering.
3. Download the `macos-snapshots` artifact and copy only the affected PNGs
   over the references in your local PR-branch working tree.
4. Eyeball, commit, and `git push` to the **fork** PR branch (the local
   branch already tracks the fork via `gh pr checkout`).
5. Delete the temporary mirror:
   ```bash
   git push origin --delete pr-<n>-macos-record
   ```

So the normal flow for a rendering change is: record iOS locally, push, then
backfill the affected macOS references from the `Record macOS Snapshots`
workflow artifact in a follow-up commit.

## Mode 2: validate snapshots

1. **Run** the test suite using the build command above (with the
   `| tee /tmp/snapshot-tests.log`).
2. If the log ends with `** TEST SUCCEEDED **`, report success and stop.
3. Otherwise, **extract every diff command** from the log:
   ```bash
   grep -E "^diff-image " /tmp/snapshot-tests.log | sort -u
   ```
   Each line is `diff-image <reference-png> <failed-png>`. Reference
   paths sit under `…/__Snapshots__/<TestClass>/<testMethod>.<variant>.png`;
   failed paths sit under DerivedData.
4. **Identify failing tests** — also grep the log for test method names
   so the report links each diff back to its source test:
   ```bash
   grep -E "Test Case .* failed" /tmp/snapshot-tests.log | sort -u
   ```
5. **Present each pair to the user**:
   - Use the `view` tool to open both PNGs inline so the user sees them
     in the chat.
   - Print the literal `diff-image …` command verbatim so the user can
     reproduce the side-by-side comparison locally.
6. After showing all diffs, **ask** whether to:
   - re-record (switch to Mode 1), or
   - investigate the rendering regression in source.

## Safety rules

- **Never commit `SnapshotTestCase.swift` with `isRecording = true`
  uncommented.** Make the post-Mode-1 grep mandatory; if the working
  tree contains the uncommented form, restore it before any commit.
- **`xcodebuild test` exits non-zero in recording mode.** That is not a
  build failure; do not retry or escalate.
- The diff-image line emitted by swift-snapshot-testing does **not**
  quote its paths. Paths in this repo never contain spaces, so a simple
  `grep` / shell tokenisation is safe; do not introduce paths with
  spaces in `Tests/MarkdownTextTests/__Snapshots__/`.
- Reference PNGs are binary — never edit them by hand; always regenerate
  via Mode 1.
