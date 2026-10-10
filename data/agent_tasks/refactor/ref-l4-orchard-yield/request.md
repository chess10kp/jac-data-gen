Can you turn `orchard.jac` into idiomatic Jac? `Orchard` is currently an obj with one flat dict of tree dicts keyed by tag, every method rescans that dict, varieties are strings checked against a module-level kg table, and the block/row/slot structure only exists as dict keys.

Target shape:

- `Orchard` becomes a node that owns its own graph: blocks, rows and trees as nodes (blocks under the orchard, rows under a block, trees under a row). The slot a tree sits in belongs on a typed edge between row and tree. Each orchard's trees stay separate from any other orchard's.
- Variety becomes an enum; callers keep passing lowercase names like "gala".
- Walkers for the traversals: harvest/row tallies for a block, the yearly ageing, and finding a tree by tag across the orchard. Use edge filters for the block/slot lookups.
- Split it into declarations and implementations: `orchard.jac` keeps the enum, node/edge/walker declarations and method signatures; all the method, function and ability bodies move into `orchard.impl.jac`.

Stable surface: module `orchard`, `Orchard(name=...)`, and its methods `add_block`, `plant`, `tree_at`, `mark_diseased`, `next_season`, `forecast`, `variety_totals`, `healthy_rows` with the same arguments and results.
