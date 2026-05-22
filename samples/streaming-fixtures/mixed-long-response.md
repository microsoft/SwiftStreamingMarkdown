# Mixed long response

Inline sampler: **bold mixed text**, _italic mixed text_, `mixedCode`, [mixed link](https://example.com/mixed), citation[^mixed-sample], and math $a + b$.

## Intro

The renderer should handle prose, lists, tables, code, math, links, and citations in one streamed response.

This sample is long enough to observe the renderer moving through several markdown states. It starts with plain text, then introduces structure, then finishes with actions and references.

## Steps

1. Parse markdown as chunks arrive.
   1. Preserve nested ordered-list details while the parent item is still streaming.
      Continue the nested ordered-list explanation on an indented line.
2. Preserve incomplete structures.
   - Keep nested bullet details attached to their parent item.
     Continue the nested bullet explanation on an indented line.
3. Expose actions through callbacks.
4. Keep the transcript readable while the response is incomplete.
5. Render the final result as ordinary markdown.

## Quoted guidance

> Keep streamed text visible while structure is still arriving.
> Multi-line block quotes should remain one quoted block instead of splitting into separate paragraphs.

## Platform table

| Platform | UI | Math |
| --- | --- | --- |
| iOS | SwiftUI | iosMath |
| Demo | SwiftUI | Simulated chunks |

## Code stream

```swift
struct MarkdownStream {
    private(set) var text = ""

    mutating func append(_ fragment: String) {
        text += fragment
    }
}
```

## Math

Inline math: $x = y + z$.

Block math:

$$
f(x) = x^2 + 2x + 1
$$

## References

Read more in [the public docs](https://example.com/streaming-markdown). This claim includes citations [^alpha][^beta].

The final paragraph adds a little more prose after the citations so the streaming demo does not end immediately after the last special element.

[^alpha]: First representative source
[^beta]: Second representative source
