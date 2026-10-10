I'd like a little full-stack recipe box in Jac. I ran `jac create --kind web-app` in this folder, so you'll see the guestbook template — replace it. (I already took the `endpoints` microservice route out of `jac.toml`, so everything runs in one process.)

**Server (put the walkers in `endpoints.jac`, public walkers, `POST /walker/<name>`):**

- `add_recipe` — `title: str`, `ingredients: list[str]`, `minutes: int = 0`. Ingredients are normalized (trimmed, lower-case, blanks and duplicates dropped) and each ingredient is its **own node shared by every recipe that uses it** — "garlic" should be one node no matter how many recipes have it. Reports the recipe view. Empty title → `{"error": ...}`.
- `list_recipes` — reports one list of all recipe views sorted by title.
- `recipes_with` — `ingredient: str`; reports one list of recipe views that use it (sorted by title), found by walking from the ingredient node.
- `rate_recipe` — `recipe_id: str`, `stars: int` (1–5, otherwise error). Reports the updated recipe view.
- `top_rated` — `limit: int = 3`; reports one list of rated recipes, highest average first, ties by title.

A recipe view is `{"id", "title", "minutes", "ingredients" (sorted list), "rating" (average rounded to 1 decimal, 0.0 if unrated), "ratings" (count)}`; the id is the recipe node's `jid`.

**Client:** a single page served at `/` that lists the recipes, has a form to add one (title + comma-separated ingredients), and a search box that filters by ingredient using `recipes_with`. Nothing fancy.

Add some Jac tests for the server side, and make sure `jac start` serves the app.
