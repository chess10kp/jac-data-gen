# ref-l4-warehouse-picking
Smell: `obj Warehouse` with six parallel dicts keyed by bin code + an aisle counter, "open"/"blocked" strings, `_walk` filling an out-list and returning the aisle count; inline bodies.
Starter quirk: a first draft (`dict[str, dict[str, any]]` + `list[list[str]]` fields, `list[any]` return) SIGSEGVed under native lowering; parallel dicts are fine.
Target: layout.jac (enum BinState; nodes Aisle/Bin; edges NextAisle, Holds{level}) + warehouse.jac (walkers PickRun{commit} / FindBin (stops at the hit) / OnHand; facade node Warehouse with method decls; pick_order decl) + warehouse.impl.jac (14 impl blocks). Warehouse is a transient subgraph (no root).
Idiom targets: modules>=2, node>=3, edge>=2, walker>=2, enum>=1, edge_filters>=1, dict_fields==0 (walker dict fields excluded), annex_impls>=7 (6 public methods + walker abilities).
Pick order: aisles 1..n; within an aisle by shelf level ascending, then stocking order (edge predicate `[a ->:Holds:level == lv:->]` keeps insertion order); the walk stops after the aisle that fills the order; short orders take what exists.
Quirk: W1051 warning on the loop var inside the edge predicate (harmless).
Negatives: high_shelves_first, picks_blocked, dry_run_commits, never_stops, on_hand_counts_blocked, duplicate_codes.
Quirk (0.36.1): `disengage` inside an annex `impl Walker.ability` is rejected (E2083), so FindBin simply does not visit further once it has a hit.
