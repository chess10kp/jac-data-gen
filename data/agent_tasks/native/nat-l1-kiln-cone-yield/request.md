Our ceramics studio logs every kiln load as a `Firing` node on `root` (see `kiln.jac`). There's already a `ConeStat` obj declared for the summary I want, but nothing produces it yet.

Please write a `ConeYield` walker. `root spawn ConeYield()` should go over all `Firing` nodes on `root` and report **one list** of `ConeStat` objects — one per cone number that appears — sorted by cone ascending, where for each cone:

- `pieces` = total pieces loaded across that cone's firings,
- `losses` = total pieces cracked **plus** pieces with glaze faults,
- `yield_pct` = whole-number percentage of good pieces, rounded **down** (`(pieces - losses) * 100 // pieces`).

Firings that were `aborted` don't count at all, and firings with 0 pieces should be ignored too (they're test fires). If nothing qualifies, report an empty list.

Keep `Firing`, `ConeStat`, and `log_firing` unchanged.
