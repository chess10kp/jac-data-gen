Volunteers in our bird-count programme submit sightings one at a time, and I'd like the tallies in a Jac graph (`survey.jac`, which so far only has the types). `Site` and `Species` nodes both hang off `root`, and a `Sighted` edge from a site to a species carries the running `total` count and the `last_day` it was seen there. Everything must be kept in the graph — the walkers are spawned on `root` by separate `jac run` invocations of the project over the season.

Please write three walkers:

1. **`LogSighting(site, species, count, day)`**
   - Create the `Site` / `Species` nodes the first time a name is used (one node per name — never duplicates).
   - If the site already has a `Sighted` edge to that species, add `count` to its `total` and set `last_day` to the later of the stored day and `day`. Otherwise create the edge with `total=count`, `last_day=day`.
   - Sightings with `count <= 0` are mistakes: ignore them completely (create nothing) and report `False`; otherwise report `True`.

2. **`SiteList(site)`** — report once the species recorded at that site as a list of names ordered by `total` descending, ties broken by name ascending. Unknown site → empty list.

3. **`Scarce(max_sites)`** — report once the sorted names of species that have been recorded at **at most** `max_sites` distinct sites (every species node has at least one site).
