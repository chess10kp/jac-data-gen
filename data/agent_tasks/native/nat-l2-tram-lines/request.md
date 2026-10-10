I'm building a small tram planner in `tramway.jac`. Stops are `Stop` nodes on `root`; each scheduled hop between consecutive stops is a `Track` edge (from → to) tagged with the `line` it belongs to and the travel `minutes`. Several lines can share the same physical stops.

Two walkers, please:

**`RunLine(line)`** — spawned on the stop where a run starts. It rides that line only: from the current stop it follows the `Track` edge whose `line` matches (each stop has at most one outgoing hop per line) until there is no further hop for that line. Some lines are loops that come back to the starting stop — the ride stops as soon as it would arrive at a stop it has already visited. Record the stops in riding order (starting stop included) and report that list of stop names once; also accumulate the minutes actually ridden in a `minutes: int` field (a loop's closing hop back to an already visited stop is not ridden).

**`Interchanges()`** — spawned on `root`. A stop is an interchange if `Track` edges of **two or more different lines** touch it (arriving or departing). Report once the sorted list of interchange stop names.

Keep `Stop`, `Track` and `add_hop` as they are.
