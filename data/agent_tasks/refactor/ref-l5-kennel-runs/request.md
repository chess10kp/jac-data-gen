The kennel desk code has grown into one big `main.jac` that is really Python with braces: a single `Kennel` node found by an `isinstance` scan, holding a dict of runs and a list of stay dicts, sizes as bare strings ranked through a lookup list, and every operation a hand-written loop over those structures.

I'd like it turned into a proper Jac project, split over several modules:

- a models module with the run size as an enum, runs and stays as nodes, and the stay hanging off its run through a typed edge that carries the nightly price locked in at booking (no dict-typed fields anywhere);
- the sweeps over the runs (choosing a run for a booking, the night list, checking a dog out, billing) done as walkers in their own module;
- the public operations in a service module;
- declarations kept separate from bodies: put the implementations in `.impl.jac` annexes next to the modules they belong to.

`main.jac` has to keep exporting the same API — `add_run`, `reprice`, `book`, `check_out`, `occupancy`, `free_runs` and `bill`, same signatures, same results (including which run `book` picks and the `"RUN:dog"` strings) — the booking screen imports them from `main`. Re-exporting them from the new modules is fine.
