# Fix Swift 6 Concurrency Warnings and Type Ambiguity

## Summary
This PR resolves Swift 6 language mode warnings related to concurrency safety and fixes ambiguous type lookup errors for `Document`.

## Changes

### 1. Fix Ambiguous `Document` Type Lookup
Qualified `Document` as `Markdown.Document` in public APIs to resolve ambiguity when multiple modules export a `Document` type:
- `RenderableDocument.init(document:config:)`
- `MarkdownParser.parse(text:)` return type
- `MarkdownParseResult.document` property

### 2. Fix Sendable Conformance for Font-Holding Structs
Marked structs containing `MDFont` properties as `@unchecked Sendable` since `UIFont`/`NSFont` are immutable and safe to share across concurrency domains, despite not being marked as `Sendable` in the SDK:
- `TextFonts` (with explanatory documentation)
- `MarkdownInlineTextStyle`
- `CitationConfig`

### 3. Fix Throwing Task Warning in CodeBlockView
Properly handled task cancellation in the copy button reset logic to preserve cancellation semantics while avoiding unstructured throwing task warnings:
```swift
do {
  try await Task.sleep(seconds: 3)
} catch {
  return  // Exit early on cancellation or other errors
}
copied = false
```

### 4. Retained Deprecated `onChange` API
Kept the deprecated `onChange(of:perform:)` API to maintain iOS 16 compatibility. The new two-parameter form `onChange(of:) { _, newValue in }` requires iOS 17+, but the package targets iOS 16+. Deprecation warnings are accepted.

## Testing
- All changes are backward compatible
- No functional behavior changes
- Concurrency safety is preserved

## Related Issues
Fixes Swift 6 language mode warnings and type ambiguity errors.
