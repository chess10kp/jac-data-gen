# ref-l3-greenhouse-rounds
Smell: bucket node on root (list of bed codes + dict[str, dict[str, any]] plant records), isinstance scan, string stage, manual filter loops.
Target: Bed nodes on root, Plant nodes attached by typed Grows edge (planted_on), Stage enum with a gap() method on Plant, WaterRound walker spawned on a Bed, DueScan walker spawned from root, node deletion for uproot, incoming edge object for age.
Idiom targets: >=2 nodes, >=1 edge, >=1 walker, >=1 visit, >=1 enum, 0 dict fields, 0 isinstance, >=2 edge filters.
Root-backed functions; each test block gets a fresh root. jac.toml pins default_codespace = "server" (0.36.1 native seam crashes jac test).
