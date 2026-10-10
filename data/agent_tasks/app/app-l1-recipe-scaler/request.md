I keep a bunch of recipes and I'm sick of doing the math by hand when I cook for a different number of people. Can you write me a small Jac library in `recipe_scale.jac`? No server or UI, just functions I can import.

What I need:

- An `obj Ingredient` with `name: str`, `qty: float`, `unit: str`.
- `scale_recipe(items: list[Ingredient], from_servings: int, to_servings: int) -> list[Ingredient]` — returns new Ingredient objects with quantities scaled proportionally. Don't mutate the list I pass in. If either servings number is zero or negative, raise `ValueError`.
- `convert(qty: float, from_unit: str, to_unit: str) -> float` — convert between units. Volumes: `tsp` = 5 ml, `tbsp` = 15 ml, `cup` = 240 ml, `ml`, `l` = 1000 ml. Weights: `g`, `kg` = 1000 g, `oz` = 28.35 g. Converting a volume to a weight (or the reverse), or using a unit not on this list, should raise `ValueError`.
- `tidy(item: Ingredient) -> Ingredient` — re-express an ingredient in the largest unit of its family (same volume/weight family, from the list above) where the quantity is still at least 1. So 48 tsp becomes 1 cup, 1500 ml becomes 1.5 l, 2 tsp stays 2 tsp, 900 g stays 900 g. Never switch to `oz` when tidying weights — stick to g/kg. Unknown units come back unchanged.

Quantities don't need rounding, I'll format them myself.
