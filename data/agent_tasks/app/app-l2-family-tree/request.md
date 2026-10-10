For a genealogy hobby project I want the family tree stored as a Jac graph. Create `family.jac`:

- `node Person` with `name: str` and `born: int` (year)
- `edge ParentOf` from a parent to their child (a child usually has two parents, so two incoming edges)

Then three walkers, spawned on a `Person`, each reporting one list of names:

- `Descendants` — children, grandchildren, and so on. Sorted by birth year, then name. No duplicates.
- `Ancestors` — parents, grandparents, ... sorted alphabetically, no duplicates.
- `FirstCousins` — children of the person's aunts and uncles (the other children of their grandparents), excluding the person's own siblings and half-siblings and the person themselves. Sorted alphabetically.

Names are unique in my data, so you can rely on them for dedup and sorting.
