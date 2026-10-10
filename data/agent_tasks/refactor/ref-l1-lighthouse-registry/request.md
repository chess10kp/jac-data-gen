Small cleanup in `lighthouses.jac`: every function walks `[root -->]` (or `[lamp -->]`) and then does `isinstance` checks plus `if` conditions by hand to find the lamps/keepers it wants. Jac can do that in the edge reference itself — please rewrite those scans as typed edge filters (type plus field conditions inside the `[...]`) and drop the `isinstance` calls.

Don't change the graph shape or the public functions (`add_lamp`, `assign_keeper`, `douse`, `log_night`, `due_for_bulb`, `keepers_at`): same names, signatures and return values.
