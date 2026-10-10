`garage.jac` is the start of the software for our multi-storey car park. Levels are `Level` nodes on `root` (added with the existing `AddLevel` walker); a parked car is a `Car` node attached to its level by a `ParkedOn` edge (level → car). The gate terminals spawn walkers on `root`, one call per event, and the state must live in the graph so that it survives restarts of the `jac run` project.

Please implement:

**`Enter(plate, minute)`** — reports one `Ticket`.
- If a car with that plate is already parked anywhere: `Ticket(ok=False, reason="already inside")`.
- Otherwise park it on the **lowest-numbered** level that still has a free spot (a level is full when its number of parked cars equals its `spots`), recording `entered_at=minute`, and report `Ticket(ok=True, level=<number>)`.
- If every level is full (or there are no levels): `Ticket(ok=False, reason="full")`.

**`Leave(plate, minute)`** — removes the car's node from the graph and reports the fee as an `int`:
- stays of 30 minutes or less are free,
- otherwise 3 per started hour of the whole stay (e.g. 31 min → 3, 60 min → 3, 61 min → 6).
- An unknown plate reports `-1`.

**`Occupancy()`** — reports once a dict mapping each level number to the number of cars parked there (levels with no cars map to 0); also put the overall total in a `total: int` field.

Don't change `Level`, `Car`, `ParkedOn`, `Ticket` or `AddLevel`.
