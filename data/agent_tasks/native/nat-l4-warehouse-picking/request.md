This is our little warehouse project (`jac run` from the project directory runs `main.jac`). `layout.jac` has the graph model — aisles chained from `root` with `NextAisle` edges, each aisle `Holds` its bins in shelf order — and `seed.jac` builds a warehouse from a spec.

I need the picking logic, in a **new module `picking.jac`**:

- An `obj PickLine` with `aisle: int`, `bin: str`, `sku: str`, `qty: int`.
- A walker `PickRun` with `has order: dict[str, int]` (sku → quantity wanted). It is spawned on `root`, enters the first aisle and walks the aisles **in chain order** (follow `NextAisle`), and in each aisle goes through the bins in shelf order. Whenever a bin holds a sku that still has outstanding quantity, it takes as much as it can (`min(outstanding, bin.qty)`), **decrements the bin's `qty` in the graph**, and records a `PickLine`. Bins with 0 quantity are skipped (no 0-qty lines).
- It stops walking further aisles as soon as the whole order is satisfied.
- At the end it reports the list of `PickLine`s (in the order they were picked) once, and leaves whatever couldn't be found in a `short: dict[str, int]` field (sku → missing quantity; only skus that are actually short). The caller's `order` dict must not be modified.

Then wire it into `main.jac`: after building the demo warehouse, run a `PickRun` for the demo order in the TODO comment and print exactly one line of the form

```
picked <number of pick lines> lines, short <sum of missing quantities> units
```

Don't change `layout.jac` or `seed.jac`.
