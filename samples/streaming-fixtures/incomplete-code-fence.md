# Incomplete code fence

Inline sampler: **bold before fence**, _italic before fence_, `partial`, [fence link](https://example.com/fence), citation[^fence-sample], and math $q = 1$.

## Opening fence

```swift
let partial = "This code fence may arrive before the closing marker"

The renderer should treat the content as pending code while streaming, then finalize once the closing fence arrives.

struct DelayedFence {
    let reason = "give the streaming demo time to show repair behavior"
}

The closing marker intentionally appears late.
```

## After the fence

After the code fence closes, regular markdown should resume and this paragraph should render outside the code block.
