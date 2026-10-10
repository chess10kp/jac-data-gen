# ref-l1-recipe-card-items
Smell: list of dict records (`items: list[dict[str, any]]`) with string-key access.
Target: `obj Item { name, qty, unit }`, `items: list[Item]`, attribute access; optional `find` helper method.
Idiom targets: 0 dict-typed fields, >=2 obj archetypes.
Tests only touch RecipeCard constructor (title/servings) and the functions, never `items` directly.
Negatives: rescale shares items (aliasing observed via swap); duplicates allowed; inverted factor; total ignores unit.
