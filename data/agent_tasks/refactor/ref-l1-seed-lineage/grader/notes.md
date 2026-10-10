# ref-l1-seed-lineage
Smell: node field holding a list of other nodes' names (`regrown_into: list[str]`); parent lookup scans all lots.
Target: typed edge `RegrownAs: SeedLot --> SeedLot`, `p +>:RegrownAs:+> child`, outgoing `[lot ->:RegrownAs:->]`,
incoming `[lot <-:RegrownAs:<-]` for ancestry. Lots remain on root.
Idiom targets: regrown_into removed (field type ""), >=2 connects (starter has 1 via `_make`), >=3 edge refs with filters
(starter has 2 filters). Untyped `p ++> child` + `[lot <--[?:SeedLot]]` also satisfies the targets.
Negatives: family size one level; ancestry one level; duplicate child accession; unsorted offspring.
