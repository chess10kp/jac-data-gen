# Lost-property office: restructure

`main.jac` is one long Python-style file. Every found item is a dict in a list on an `Office` node (located with `isinstance`), the per-station tag counters sit in another dict, categories are free strings, and a claim is just two extra keys on the item dict. Each operation walks that list by hand.

Please turn this into an idiomatic Jac project:

1. **Models module** — category as an enum; stations, items and claimants as nodes. Items hang off the station that holds them, and a claim is a typed edge from the item to the claimant that records the day it was collected. Each station keeps its own tag counter. No dict-typed fields.
2. **Walkers module** — the network-wide sweeps (searching for matching unclaimed items, finding items past the keep window) as walkers going station → item.
3. **Service module** — the desk operations.
4. Split declarations from implementations using `.impl.jac` annexes.

`main.jac` remains the public entry point and keeps exporting `log_item`, `search`, `claim`, `claims_of`, `transfer`, `held_at` and `expire` with unchanged signatures and results (tag format, sort orders, status strings and the `"tag@day"` claim strings).
