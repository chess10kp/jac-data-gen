Can you give the garage code a proper Jac structure? Today it's `store.jac` with a `GarageState` node (found via `isinstance`) that holds three dicts — spots, parked cars, per-level takings keyed by the level number as a string — plus `main.jac` doing everything as loops over those dicts. Spot kinds are bare strings.

What I'm after:
- models module: spot kind as an enum; levels, spots and cars as nodes (levels contain their spots); a parked car hangs off its spot through a typed edge that carries the minute it arrived; each level keeps its own takings. No dict fields.
- the garage sweeps — picking the best free spot of a kind, locating a parked car (and its spot/level) — as walkers in their own module.
- a service module with the operations.
- implementations in `.impl.jac` annexes.

`main.jac` must keep exporting `add_spot`, `park`, `where`, `leave`, `level_free` and `takings` exactly as they are now (signatures, plate normalisation, spot choice, fees in cents, -1 / "" for failures). The gate terminals import them from `main`.
