# ref-l5-kennel-runs
Smell: monolithic main.jac; one `Kennel` bucket node (isinstance scan) holding `runs: dict[str, dict]` and `stays: list[dict]`; size strings ranked via a lookup list; every operation a manual loop.
Target: models.jac (enum Size, nodes Run/Stay, typed edge `Hosts: Run --> Stay { has nightly: int; }` locking the price) + models.impl.jac; rounds.jac walkers (PickRun, NightList, Departure, Billing) + rounds.impl.jac; desk.jac service decls + desk.impl.jac; main.jac facade re-exporting via `import from desk { ... }`.
Idiom targets: modules>=3, annex_impls>=8, walkers>=2, edge>=1, enum>=1, dict_fields==0, isinstance==0, spawns>=2.
Behaviour pinned by tests: smallest fitting run (rank, then code), overlap semantics, price locked at booking (reprice after booking), check-out removes all of a dog's stays only.
Inspiration: data/agent_tasks/native/nat-l5-dog-boarding (sizes/runs/stays); API, pricing, billing and reprice are new.
