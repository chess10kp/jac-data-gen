gym log cli in jac pls. project's already scaffolded (jac create).

- graph: an `Exercise` node per exercise name under root, each set I log is its own node attached to that exercise (date, weight kg, reps). must persist across runs
- walkers in main.jac:
  - `LogSet(exercise: str, date: str, weight: float, reps: int)` — creates the exercise node if new
  - `PersonalBest(exercise: str)` — reports a dict `{"e1rm": float, "date": str}` for the set with the highest estimated 1-rep max, e1rm = weight * (1 + reps / 30) rounded to 1 decimal. earliest date wins ties. if the exercise has no sets report `{"e1rm": 0.0, "date": ""}`
  - `Volume(exercise: str, since: str)` — reports total weight×reps (float) of sets dated on/after `since`
- cli:
  - `jac run main.jac log bench 2026-03-01 60 5`
  - `jac run main.jac best bench` → prints e.g. `bench 70.0 on 2026-03-01` (or `no sets for bench`)
  - `jac run main.jac volume bench 2026-03-01` → prints the number

exercise names are case-insensitive (Bench == bench).
