# ref-l3-bird-tally
Smell: bucket node on root with dict[str, dict[str, dict[str, int]]] (site -> species -> total/last_day), isinstance scan, manual counting loops.
Target: Site/Species nodes on root, typed Sighted edge (Site --> Species) with total + last_day, Census walker spawned from root for sites_for/last_seen, incoming edge refs for scarce.
Idiom targets: >=2 nodes, >=1 edge, >=1 walker, >=1 spawn, 0 dict fields, 0 isinstance, >=2 edge filters.
Root-backed functions: each test block has a fresh root. No enum (no natural status here).
