"""Recipe box - entry point: server walkers plus the client UI."""

import from endpoints { Recipe, Ingredient, add_recipe, list_recipes, recipes_with, rate_recipe, top_rated }

import from .frontend { app as ClientApp }

def:pub app -> JsxElement {
    <ClientApp/>
}
