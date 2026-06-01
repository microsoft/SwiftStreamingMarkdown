---
name: pr-writer
description: "Prepare and publish SwiftStreamingMarkdown pull requests end-to-end: generate PR description, commit changes, create/push branch, and open a PR when needed."
---

# PR Writer

Prepare pull requests end-to-end by generating the PR description and handling the publish flow (commit -> branch -> push -> PR creation when needed).

## When to Activate

- User asks to write, open, or update a PR
- User asks to commit, push, and open a PR for current branch changes
- User says "ship this", "publish this", "make a PR", or similar

## End-to-End Publish Workflow

1. Check repository and PR state
   - Confirm current branch and dirty working tree using `git status`.
   - Check if branch already has an open PR:
     - `gh pr view --json number,url,headRefName,baseRefName`

2. Generate PR description body
   - Produce the PR body using the template in this skill (mirrors `.github/pull_request_template.md`).
   - Ensure title is a clear, sentence-case description of the change (see conventions below).

3. Commit current changes
   - Treat the current branch working tree as source of truth even if prior session history is unavailable.
   - Include both staged and unstaged tracked code/doc/config changes that are relevant to the PR scope.
   - Exclude obvious temporary artifacts (for example root-level screenshots, ad-hoc logs, dumps, tmp/debug files) unless explicitly requested.
   - Stage relevant files and create a commit with a clear message.
   - Include the standard co-author trailer unless the user opts out:
     - `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`
   - If there are no changes to commit, skip commit creation and continue.

4. Create or switch to a publish branch
   - If current branch is a protected/shared branch (for example `main`), create a feature branch with a hyphenated descriptive name.
   - Otherwise keep using current feature branch.

5. Push branch
   - Push with upstream tracking:
     - `git push -u origin <branch>`
   - **Never force-push to update a PR.** Do not use `git push --force` or `git push --force-with-lease` under any circumstance. To update a PR, always add a new commit on top — never rewrite, amend, or squash already-pushed history. If the push is rejected as non-fast-forward, stop and ask the user; do not "fix" it with force.

6. Create PR only if one does not already exist
   - If no open PR exists for the branch, create one:
     - `gh pr create --title "<title>" --body "<body>" --base main --head <branch>`
   - If PR already exists, update body/title as needed instead of creating duplicates.
   - Update existing PR metadata when work is already partially published:
     - `gh pr edit <PR_NUMBER> --title "<title>" --body "<body>"`
   - If branch and PR already exist and no new commit is needed, run metadata update only.

7. Return publication result
   - Report commit SHA, branch name, push status, and PR URL.

## Partial-State Handling (Some Steps Already Done)

- Existing branch + existing PR + new code changes:
  - Commit/push changes, then update PR body/title with `gh pr edit`.
- Existing branch + existing PR + no code changes:
  - Skip commit/push and update PR description/title only.
- Existing branch + no PR:
  - Push branch if needed, then create PR with generated body.
- No branch/PR yet:
  - Create branch, commit, push, then create PR.
- Session reset/compaction or new-agent context with unknown edit history:
  - Do not rely on prior agent edit memory.
  - Use the current `git status`/diff as the canonical change set, apply temp-file filtering, then proceed with normal commit/push/PR flow.

## Branch Naming Convention

This repo uses hyphenated descriptive branch names (no username prefix):

```text
citation-config
citation-config-followup
configurability-followup
style-configurability
text-fonts-refactor
latex-configurability
```

## PR Title Conventions

Use a clear, sentence-case description of the change. No `[TAG]` prefixes, no ticket IDs, no conventional-commit prefixes are required.

**Examples (from recent merged PRs):**
- `Convert CitationCoder to public Hashable struct on CitationConfig`
- `Clean up InlineCitationConstants and merge citation predicates`
- `Add CitationConfig to MarkdownRenderConfig; remove dead Typography props`
- `Style folder; UIFont inline link/code; optional letterSpacing/lineHeight`
- `Introduce TextFonts struct and decouple style config from Typography enum`

## PR Template

The repo template (`.github/pull_request_template.md`) has three sections plus an OSS-readiness checklist:

```markdown
## Summary

<!-- What changed and why? -->

## Validation

<!-- List the checks you ran, for example: make test && make build -->

## OSS readiness

- [ ] No secrets, internal URLs, private identifiers, or product-only service names were added.
- [ ] Public docs, fixtures, or notices were updated if behavior or dependencies changed.
- [ ] Third-party dependency changes are reflected in `docs/dependency-inventory.md` and `NOTICE`.
- [ ] Streaming/incomplete markdown behavior remains covered by fixtures or tests.
```

## Template Filling Guidelines

### Summary

- Lead with what changed and why (one or two sentences).
- For multi-part changes, use a short bullet list of the concrete pieces (files, types, behaviors).
- **Always reference the related GitHub issue.** Every PR must cite the issue it addresses using a closing keyword on its own line so GitHub auto-links and auto-closes it on merge:
  - `Closes #<issue-number>` for issues this PR fully resolves
  - `Fixes #<issue-number>` for bug-fix PRs
  - `Refs #<issue-number>` when the PR is related but does not close the issue (for stacked work, partial progress, or follow-ups)
  - Use the full `owner/repo#<number>` form when referencing an issue in a different repository.
  - If no issue exists yet, **create one first** with `gh issue create` and reference it. Do not open a PR without a linked issue unless the user explicitly waives this (e.g. for trivial docs/typo fixes).
- For large PRs, note scope and any follow-ups at the top.

### Validation

- List the actual commands you ran and their result. Common ones in this repo:
  - `xcodebuild test -scheme SwiftStreamingMarkdown -destination "platform=iOS Simulator,OS=26.4.1,name=iPhone 17" -skipMacroValidation`
  - `xcodebuild build -project Examples/SwiftStreamingMarkdownSample/SwiftStreamingMarkdownSample.xcodeproj -scheme SwiftStreamingMarkdownSample -destination "platform=iOS Simulator,OS=26.4.1,name=iPhone 17" -skipMacroValidation`
  - `swift build` / `swift test` for SwiftPM-only checks
- Mention snapshot test runs explicitly when relevant (record vs validate; see the `snapshot-tests` skill).
- For UI changes, mention manual verification in the sample app and any VoiceOver/accessibility checks.
- Brief is fine when no new tests apply: "Existing test suite passes locally."

### OSS readiness

- Tick each box honestly. Leave unchecked items visible so the reviewer can see what still needs attention.
- If a row genuinely does not apply (for example no dependency change), tick it and append a short note like `(no dependency changes)`.

### Screenshots (optional)

- Not part of the committed template, but add a `## Screenshots` section when UI/rendering changes warrant it.
- Use GitHub's image upload format with explicit dimensions:
  - `<img width="568" height="1084" alt="..." src="..." />`
- Light and dark variants are valuable for theme-related changes.

## Example PR Body

```markdown
## Summary

Convert `CitationCoder` from an internal helper into a public `Hashable` struct on `CitationConfig`, so external consumers can construct and compare their own coders. Default values are unchanged behaviorally.

- Promote `CitationCoder` to `public struct: Hashable`
- Expose it on `CitationConfig` instead of the typography layer
- Update sample fixtures and tests to construct configs explicitly

Closes #42

## Validation

- `xcodebuild test -scheme SwiftStreamingMarkdown -destination "platform=iOS Simulator,OS=26.4.1,name=iPhone 17" -skipMacroValidation` — all tests pass
- `xcodebuild build` on the sample app — succeeds
- Verified citation rendering visually in the sample app's multi-paragraph demo

## OSS readiness

- [x] No secrets, internal URLs, private identifiers, or product-only service names were added.
- [x] Public docs, fixtures, or notices were updated if behavior or dependencies changed.
- [x] Third-party dependency changes are reflected in `docs/dependency-inventory.md` and `NOTICE`. (no dependency changes)
- [x] Streaming/incomplete markdown behavior remains covered by fixtures or tests.
```

## Output Format

Return two parts:

1) Publication summary:
- Commit created/skipped (+ SHA when created)
- Branch used/created
- Push result
- PR action: created or updated
- PR URL (if available)

2) Complete PR body, following the template exactly:

````markdown
## Summary

<!-- What changed and why? -->

## Validation

<!-- List the checks you ran, for example: make test && make build -->

## OSS readiness

- [ ] No secrets, internal URLs, private identifiers, or product-only service names were added.
- [ ] Public docs, fixtures, or notices were updated if behavior or dependencies changed.
- [ ] Third-party dependency changes are reflected in `docs/dependency-inventory.md` and `NOTICE`.
- [ ] Streaming/incomplete markdown behavior remains covered by fixtures or tests.
````

## Guardrails

- **Every PR must reference its GitHub issue** in the Summary section using a `Closes #N` / `Fixes #N` / `Refs #N` line. If no issue exists, create one first with `gh issue create` before opening the PR. The only allowed exception is when the user explicitly waives this requirement.
- **Never force-push to update a PR.** Do not run `git push --force` or `git push --force-with-lease`, and do not amend, rebase, or squash commits that have already been pushed. To update a PR, always add a new commit on top. If a push is rejected as non-fast-forward, stop and ask the user — do not "resolve" it with force.
- Do not create duplicate PRs for the same head branch.
- Keep commit scope limited to intended changes; avoid unrelated files.
- Do not omit legitimate branch changes only because they were not created in the current agent session.
- Do not commit secrets, internal-only URLs, or product-confidential identifiers — this is a public OSS repo.
