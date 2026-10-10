My cookbook is a graph (`cookbook.jac`): `Recipe` nodes on `root`, each linked to `Ingredient` nodes via `Needs` edges (with an `optional` flag), and ingredients linked to acceptable replacements via `SubstitutesFor` edges (`original --SubstitutesFor--> replacement`; one-directional: butter→margarine does not mean margarine→butter).

Please add a walker `WhatCanICook` that takes what I have in the pantry:

```
w = root spawn WhatCanICook(pantry=["eggs", "flour", "margarine"]);
```

A recipe is cookable if every **non-optional** ingredient it needs is either in the pantry itself, or has a direct substitute (one `SubstitutesFor` hop, no chains) that is in the pantry. Optional ingredients never block a recipe and never produce a swap.

Report once, at the end, a list of `CookPlan` objects (already declared) for the cookable recipes, sorted by recipe title. `swaps` lists `"<original>-><replacement>"` for each required ingredient that has to be replaced, sorted. If an ingredient has several substitutes in the pantry, use the alphabetically first one. If the ingredient itself is in the pantry, don't swap it.

Pantry names match `Ingredient.name` exactly. Leave the existing declarations and helpers as they are.
