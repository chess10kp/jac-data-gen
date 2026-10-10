# ref-l5-ferry-deck
Smell: two Python-style modules (fleet.jac bucket node `Fleet` with `sailings`/`bookings` dicts + isinstance scan; main.jac loops), vehicle strings.
Target: models.jac (enum Vehicle, nodes Sailing/Booking, typed edge `Holds: Sailing --> Booking { lanes, seats }`) + models.impl.jac; sweeps.jac walkers LocateBooking/DayCount + sweeps.impl.jac; bookings.jac service decls + bookings.impl.jac; main.jac facade `import from bookings { ... }`.
Idiom targets: modules>=3, annex_impls>=10, walkers>=1, edge>=1, enum>=1, dict_fields==0, isinstance==0, edge_filters>=2.
`move` re-points the Holds edge (`del [edge b <-:Holds:<-]` then a new typed connect).
Inspiration: data/agent_tasks/native/nat-l5-ferry-booking; API reshaped (status strings, move, free_space, day_passengers; lanes/seats instead of slots).
