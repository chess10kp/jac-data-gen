`keepers.jac` models the lamps along our stretch of coast: one `Lamp` node per lighthouse, attached to `root`, each with a `Lens` enum. I need a `NightShift` walker added to it.

After each night the keeper runs `root spawn NightShift(hours=<hours the lamps burned>)`. It should:

1. Visit every `Lamp` on `root`.
2. For each lamp that is **lit**, add the night's hours to its `burn_hours` — but first-order lenses run their bulbs hot, so a `Lens.FIRST_ORDER` lamp accumulates **1.5×** the hours. Unlit lamps don't accumulate anything.
3. After updating, a lit lamp is *due for a bulb change* once its `burn_hours` reaches **90% or more** of its `rated_hours`. Unlit lamps are never reported as due.
4. Collect the due lamps' station names in a `due: list[str]` field on the walker and, at the end, `report` that list once, sorted by station name.

The burn hours have to stay on the nodes — we run `NightShift` every night and the totals should keep adding up. Please leave `Lamp`, `Lens`, and `add_lamp` as they are.
