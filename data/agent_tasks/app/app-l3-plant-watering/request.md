I have way too many houseplants and keep forgetting which ones need water. I started a Jac project here (it's just the `jac create` CLI template right now). Can you turn it into a little watering tracker?

How I want to use it from the terminal (state has to stick around between runs — it's my only record):

```
jac run main.jac add fern 3 2026-01-01      # name, water every N days, date I last watered it
jac run main.jac water fern 2026-01-04      # I watered it on this date
jac run main.jac due 2026-01-05             # which plants need water on this date?
```

- `due` prints the names of plants that need water (one per line, alphabetical), or `nothing due` if none. A plant is due when `last watered + every N days` is on or before the date asked about.
- `water` for a plant I never added should print `no such plant` (don't crash).
- Adding a plant that already exists should update it (new interval, new last-watered date) rather than create a duplicate.

Please store the plants as nodes hanging off `root`, and do the work with walkers so I can reuse them from other code later. I'd like these walkers in `main.jac` with these names and fields:

- `AddPlant` — `name: str`, `every_days: int`, `date: str`
- `WaterPlant` — `name: str`, `date: str`
- `DuePlants` — `date: str`; reports the list of due plant names (sorted) once

Dates are ISO `YYYY-MM-DD`.
