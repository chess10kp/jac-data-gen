I run a small greenhouse and want to keep the watering schedule in a Jac graph (`greenhouse.jac`). The node and edge types are already there: a `Bed` (identified by `code`) `Grows` any number of `Plant`s. Each plant has a species, how many days it can go between waterings (`interval_days`), and the day it was last watered.

Each operation is a separate walker spawned on `root` — I run them from little scripts throughout the week, so all state must be kept in the graph attached to `root` (it has to survive between separate `jac run` invocations of the project).

1. **`PlantIn(bed, species, interval_days, day)`** — add a new plant to bed `bed`, creating the `Bed` on `root` the first time that code is used (never create two beds with the same code). A freshly planted plant counts as watered on `day`. Report the number of plants now in that bed.
2. **`WaterBed(bed, day)`** — mark every plant in that bed as watered on `day`. Report how many plants were watered (0 for an unknown bed — don't create it).
3. **`DueOn(day)`** — report, once, the plants that need water on `day`: a plant is due when `day - last_watered >= interval_days`. Report them as `"<bed>/<species>"` strings sorted alphabetically (if a bed has two plants of the same species that are both due, list it twice).
4. **`Uproot(bed, species)`** — remove every plant of that species from that bed (delete the plant nodes; the bed stays). Report how many were removed.
