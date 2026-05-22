# Partial emphasis

Inline sampler: **bold**, _italic_, `inline code`, [link](https://example.com), citation[^emphasis-sample], and math $e = mc^2$.

## Open marker

The stream may pause after an opening marker such as **strong text that is not finished

## Repair behavior

While the marker is incomplete, the renderer should avoid crashing and should keep the surrounding paragraph visible. This sentence gives the stream time to linger in that partially formatted state.

## Closed marker

Then the final chunk closes it: **strong text that is now complete**.

## Emphasis

The same applies to _emphasis split across chunks_. A final sentence after the emphasis confirms the parser returns to regular text once the marker is closed.
