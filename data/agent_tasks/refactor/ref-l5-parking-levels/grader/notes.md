# ref-l5-parking-levels
Smell: two Python-style modules: store.jac `GarageState` bucket node (isinstance scan) with `spots`, `parked` dict-of-dicts and `takings: dict[str,int]` keyed by str(level); main.jac loops; spot kind strings.
Target: models.jac (enum SpotKind; nodes Level{number,takings}/Spot/Car; edges `Contains: Level --> Spot`, `Occupied: Spot --> Car { since: int }`; fee_for) + models.impl.jac; patrol.jac walkers SpotFinder/LocateCar + patrol.impl.jac; garage.jac service decls + garage.impl.jac; main.jac facade.
Idiom targets: modules>=3, annex_impls>=8, walkers>=2, edges>=2, enum>=1, dict_fields==0, isinstance==0, spawns>=2.
Spot choice: lowest level then code; EV drivers try EV spots then standard; non-EV never take EV spots. Fee: <=30 min free else 200 per started hour.
Inspiration: data/agent_tasks/app/app-l5-parking-garage (plates, fee rule); levels, EV spots, takings are new; HTTP layer dropped.
