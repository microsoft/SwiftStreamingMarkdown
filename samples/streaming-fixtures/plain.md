# Plain streaming markdown

Inline sampler: **bold**, _italic_, `inline code`, [link](https://example.com), citation[^inline-sample], and math $x + y = z$.

## Overview

This fixture is intentionally plain, but it is long enough to make streaming visible. It should render correctly as each sentence is appended and should not require the entire document before showing useful text.

## Details

The second paragraph gives the renderer more opportunities to reflow text. It includes **strong text**, _emphasis_, and ordinary punctuation so the final output still feels like a normal answer.

## List

- First item
- Second item
- Third item
- Fourth item that arrives later in the stream
- Fifth item that confirms the list remains stable

## Finish

Final paragraph with enough trailing content to watch the last few chunks arrive before the response settles.
