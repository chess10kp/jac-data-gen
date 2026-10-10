In `vault.jac` every seed accession we hold is a `SeedLot` node attached to `root`. I'd like a walker called `RegrowPlan` that tells the curators which lots to pull for a regrow (germination) test this season.

Usage: `root spawn RegrowPlan(year=2026)`.

A lot needs a regrow test when **any** of these is true:
- it was banked 10 or more years before `year` (`year - banked_year >= 10`),
- its last measured `germination` percentage is below 75,
- it has fewer than 200 `seeds_left`.

Lots marked `retired` are never included.

The walker should `report` exactly once, at the end, a dictionary mapping each **species** that has at least one lot to test to the list of that species' accession codes, sorted alphabetically. Species with nothing to test should not appear at all. Also keep a running `examined: int` count of the non-retired lots it looked at.

Don't change `SeedLot` or `bank_lot`.
