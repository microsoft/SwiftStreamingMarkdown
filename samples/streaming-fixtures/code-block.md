# Code block

Inline sampler: **bold before code**, _italic before code_, `inlineCode()`, [code link](https://example.com/code), citation[^code-sample], and math $n = 1$.

## Swift example

```swift
struct MessageChunk: Identifiable, Equatable {
    let id: UUID
    var markdown: String
    var isFinal: Bool
}

@MainActor
final class TranscriptModel: ObservableObject {
    @Published private(set) var renderedMarkdown = ""

    func receive(_ chunk: MessageChunk) {
        renderedMarkdown += chunk.markdown
        if chunk.isFinal {
            renderedMarkdown = renderedMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
```

## JSON example

```json
{
  "id": "chunk-1",
  "markdown": "**Hello** from a streamed markdown fragment.",
  "isFinal": false
}
```

## TypeScript example

```typescript
type MessageChunk = {
  id: string;
  markdown: string;
  final?: boolean;
};

export function reduceChunks(chunks: MessageChunk[]): string {
  return chunks
    .map((chunk) => chunk.markdown)
    .join("")
    .trimEnd();
}
```

## Copy behavior

Copy actions should return only the code content for the selected block. The prose after the code blocks verifies that the renderer leaves fenced-code mode once the closing fence streams in.
