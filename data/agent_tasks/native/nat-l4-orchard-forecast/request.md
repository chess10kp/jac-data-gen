Our orchard project keeps the graph model in the `model/` package: `model/orchard.jac` (blocks → rows → trees) and `model/varieties.jac` (the `Variety` enum, the mature-yield table and the `age_factor` curve). I'd like two changes:

1. **New variety.** We've planted Honeycrisp. Add `HONEYCRISP` to the `Variety` enum (after the existing ones) with a mature yield of **30.0 kg** in `MATURE_KG`. Nothing else in `varieties.jac` should change.

2. **Harvest forecast.** Create a new top-level module `harvest.jac` with:
   - `obj Forecast` with `block: str`, `total_kg: float`, `by_variety: dict[str, float]` and `trees_counted: int`;
   - a walker `ForecastBlock` that is spawned **on a `Block` node** and walks down its rows to its trees. Each healthy tree contributes `MATURE_KG[variety name] * age_factor(age)` kg; diseased trees contribute nothing and are not counted. `by_variety` maps variety name → kg for every variety that has at least one counted tree (even if its kg is 0, e.g. very young trees), `total_kg` is the sum, `trees_counted` the number of healthy trees. Report a single `Forecast` when done.

Use the existing `MATURE_KG` and `age_factor` rather than duplicating the numbers. Leave `model/orchard.jac` as it is.
