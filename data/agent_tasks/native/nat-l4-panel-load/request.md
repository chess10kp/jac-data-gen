Our home-automation project models the breaker panel as a graph (`panel.jac`): each `Breaker` on `root` `Feeds` some outlets, and appliances are connected to an outlet with a `PluggedInto` edge (appliance → outlet). `reports.jac` has an inventory walker.

Two things:

1. **New module `load.jac`** with a walker `PanelLoad` (`has volts: float = 120.0`) spawned on `root`. For every breaker, compute the current it carries: the sum of `watts` of appliances that are switched **on** and plugged into any outlet fed by that breaker, divided by `volts`. Store these in `loads: dict[str, float]` (breaker label → amps, rounded to 2 decimals; breakers with nothing on still appear with 0.0). A breaker is **overloaded** when its load is strictly greater than 80% of its `amps` rating. Report once the sorted list of overloaded breaker labels.

2. **Update `ListAppliances` in `reports.jac`** so each line also says which breaker it's on: `"<breaker label>/<room>: <appliance name>"` (still sorted). Everything else about that walker stays the same — it lists all plugged-in appliances, on or off.

`panel.jac` must not change.
