# ref-l3-contest-logbook
Smell: obj with dict[str, list[str]] calls-per-band + parallel dicts keyed "band/call"; band as string checked against a list field; nested counting loops for busiest zone.
Target: Logbook node facade owning BandLog nodes (band: Band enum) and Station nodes; Worked edge (BandLog --> Station) with minute + zone; Tally walker spawned from the logbook reading edge objects; incoming edge refs for worked_on.
Idiom targets: >=2 nodes, >=1 edge, >=1 walker, >=1 spawn, >=1 enum, 0 dict fields, >=2 edge filters.
Quirks: enum values can't go in an edge-filter predicate, so BandLog lookup is a comprehension over [self -->[?:BandLog]]. jac.toml pins default_codespace = "server" (0.36.1 native seam crashes jac test).
