Hey — `rounds.jac` (greenhouse watering) is still basically a Python script: a single `Greenhouse` node on root holding a list of bed codes and a dict of plant dicts, located with an isinstance loop, and the growth stage is a raw string.

Can you refactor it into a graph model?
- beds and plants as nodes, beds on root, plants attached to their bed via a typed edge that records the day the plant went in
- growth stage as an enum
- watering a bed and the "what's due" sweep done by walkers rather than looping over every plant record
- edge filters for lookups, no isinstance

The seven functions (`add_bed`, `plant`, `promote`, `water_bed`, `due_on`, `uproot`, `age`) are called from the greenhouse controller, so names, parameters and return values must not change.
