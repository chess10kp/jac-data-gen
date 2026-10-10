In `ferries.jac` the ports are proper nodes and the crossings are already edges, but the crossing time lives off to the side in a `Timetable` node as a `dict` keyed by `"src->dst"` strings. That's two sources of truth for the same connection and the string keys are fragile.

Please make the crossing a typed edge that carries its own `minutes` field, get rid of the timetable dict, and query the edge (edge filters / edge predicates) instead of building keys. `add_port`, `add_crossing`, `crossing_time`, `retime` and `quick_hops` keep their names, signatures and results; crossings stay one-way.
