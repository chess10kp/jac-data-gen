# ref-l4-orchard-yield
Smell: `obj Orchard` with `trees: dict[str, dict[str, any]]` (tag -> block/row/slot/variety/age/sick), variety strings checked against a glob kg dict, block list; inline methods.
Target: orchard.jac = interface (enum Variety; nodes Block/Row/Tree + facade node Orchard with method decls; edges HasRow, Planted{slot}; walkers Harvest / NextSeason / Locate); orchard.impl.jac = 25 impl blocks. Orchard is a transient subgraph (no root) so two orchards stay separate.
Idiom targets: node>=3, edge>=1, walker>=2, enum>=1, edge_filters>=1, spawns>=2, dict_fields==0 (walker dict fields excluded), annex_impls>=8 (8 public methods alone).
Quirk (native lowering, module has no root): iterating an enum yields nothing and `Variety("gala")` returns 0 -> parse strings with a `match` returning `Variety | None`. Enum `.value`/`.name`, enum match and `==` work.
Floats: all yields are multiples of 0.25, so sums are exact regardless of traversal order.
Negatives: counts_diseased, age_factor_boundary, duplicate_tags, season_ages_twice, slot_ignored.
Quirk (0.36.1): `disengage` inside an annex `impl Walker.ability` is rejected (E2083 "only valid inside a walker ability"), so Locate stops via a found-guard instead.
jac 0.36.1: starter/ and reference/ carry jac.toml `[build] default_codespace = "server"` (native-lowered modules can SIGSEGV/SIGABRT under `jac test`). No lambdas: at 0.36.1 a typed block lambda used as a sort key failed at test time (`NameError: __jac_lambda_1`), so sorts use plain keys / str.lower.
