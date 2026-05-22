# Partial table

Inline sampler: **bold table note**, _italic table note_, `cell`, [table link](https://example.com/table), citation[^table-sample], and math $r = c$.

## Setup

The renderer should preserve a partially streamed table until enough rows have arrived to form a useful layout.

## Feature matrix

| Feature | Status | Notes |
| --- | --- | --- |
| Streaming updates | Ready | Re-render as chunks arrive |
| Partial tables | In progress | Promote rows once separators are complete |
| CSV export | Planned | Host handles the export action |
| Copy action | Ready | Host receives the table model |
| Horizontal scroll | Ready | Wide tables stay usable |
| Accessibility labels | Planned | Host can provide richer labels |

## After the table

Trailing text after the table should not be included in table copy/export. This extra paragraph also makes the fixture stream long enough to observe the transition out of table layout.
