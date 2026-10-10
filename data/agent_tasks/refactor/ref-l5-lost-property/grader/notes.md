# ref-l5-lost-property
Smell: monolithic main.jac; `Office` bucket node (isinstance scan) with `items: list[dict]` and `issued: dict[str,int]`; category strings; claim stored as dict keys.
Target: models.jac (enum Category; nodes Station{issued}/Item/Claimant; edges `Holds: Station --> Item`, `ClaimedBy: Item --> Claimant { day: int }`) + models.impl.jac; sweeps.jac walkers Search/Expiry (root→station→item) + sweeps.impl.jac; office.jac service decls + office.impl.jac; main.jac facade.
Idiom targets: modules>=3, annex_impls>=8, walkers>=2, edges>=2, enum>=1, dict_fields==0, isinstance==0, visits>=2.
Quirks: a function param named `station` would shadow a helper named `station`, so the helper is `station_named`. Tag counters survive expiry (park-3 after park-1 is disposed). transfer re-points Holds (`del [edge it <-:Holds:<-]`).
Inspiration: data/agent_tasks/native/nat-l5-lost-and-found; adds stations, per-station tags, transfer, claim days and claims_of.
