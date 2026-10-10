Tram network planner in Jac, file `tram.jac`.

- `node Stop` — `name: str`
- `edge Track` — `minutes: int`, one-way from one stop to the next (two-way service is just two edges)

Walkers, spawned on the starting `Stop`, each reporting once:

- `FastestTime` with `has target: str` — fewest total minutes to reach the stop with that name following tracks in their direction. Report `-1` if unreachable, `0` if it's the start itself.
- `ReachableWithin` with `has budget: int` — the names of all stops (not the start) whose fastest travel time is ≤ budget, sorted alphabetically.

Graphs can have cycles and multiple routes between the same stops; the cheapest route wins. Do it with walkers moving over the graph rather than exporting everything into a dict and running a textbook algorithm on the side.
