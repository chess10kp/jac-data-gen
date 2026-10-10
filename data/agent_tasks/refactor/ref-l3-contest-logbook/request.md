logbook.jac needs a proper model. Right now `Logbook` keeps a dict of call lists per band string plus two dicts keyed by `"band/call"` strings for minute and zone, and every query re-parses that. Bands are free-form strings checked against a list.

Target: `Logbook` as a node owning one band-log node per band and one node per station worked; each QSO is a typed edge from band log to station carrying minute and zone. Make the band an enum. Score / zone / window stats should come from a walker that sweeps the band logs.

API stays put: `Logbook(callsign=...)`, `log`, `score`, `band_counts`, `worked_on`, `busiest_zone`, `in_window` — same args, same return values and strings ("ok", "dupe", "bad band", "20m:3" etc.). Logbooks must stay independent of each other.
