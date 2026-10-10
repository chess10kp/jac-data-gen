`journal.jac` keeps every set as a dict in `Journal.sets` (exercise -> list of dicts), the set kind is a plain string, and each stat re-scans every record. I'd like it remodelled as a graph:

`Journal` should become a node owning exercise nodes and session (date) nodes. Put what an exercise did in a session on a typed edge between them — keep running per-session stats there (volume, top estimated max, failed sets) rather than storing raw set dicts. Set kind ("warmup" / "work" / "fail") becomes an enum. The per-exercise stats (`best`, `best_date`, `volume`, `failures`) should come from a walker that walks that exercise's sessions.

Don't change the API: `Journal(athlete=...)`, `log_set`, `exercises`, `best`, `best_date`, `volume`, `failures`, `trained_on` keep their parameters and results, and separate journals stay separate.
