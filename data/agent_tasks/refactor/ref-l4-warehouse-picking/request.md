`warehouse.jac` → idiomatic Jac please. `Warehouse` is an obj juggling six parallel dicts keyed by bin code (aisle, sku, qty, level, state...), aisles are just a counter, bin state is an "open"/"blocked" string, and pick/aisles_needed share a private `_walk` that fills an out-list and returns a count.

Design I want:
- layout types in their own `layout.jac`: aisles and bins as nodes, aisles chained one-way with a typed edge, bins hung off their aisle with a typed edge that carries the shelf level; bin state as an enum
- `Warehouse` becomes a node owning its aisle chain (warehouses must not see each other's stock)
- walkers instead of the loops: the pick run (dry-run capable, so `aisles_needed` reuses it), bin lookup by code, on-hand totals. Edge filters / edge predicates for the per-level and per-code lookups
- `warehouse.jac` keeps declarations only (walkers with ability signatures, the `Warehouse` node with method signatures); every body goes into `warehouse.impl.jac`

`warehouse` stays the module callers import, `Warehouse(name=...)` stays the constructor, and `add_aisle`, `stock`, `block_bin`, `on_hand`, `pick`, `aisles_needed` keep their signatures, pick-line format and results.
