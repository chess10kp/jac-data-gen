"""Implementations for the recipe box UI."""

impl app.loadAll -> None {
    result = root spawn list_recipes();
    recipes = result.reports[0] if result.reports else [];
}

impl app.addRecipe(e: FormEvent) -> None {
    e.preventDefault();
    if not title.strip() {
        return;
    }
    parts = [p.strip() for p in ingredients.split(",")];
    root spawn add_recipe(title=title, ingredients=parts);
    title = "";
    ingredients = "";
    result = root spawn list_recipes();
    recipes = result.reports[0] if result.reports else [];
}

impl app.search(e: FormEvent) -> None {
    e.preventDefault();
    if not query.strip() {
        everything = root spawn list_recipes();
        recipes = everything.reports[0] if everything.reports else [];
    } else {
        hits = root spawn recipes_with(ingredient=query);
        recipes = hits.reports[0] if hits.reports else [];
    }
}
