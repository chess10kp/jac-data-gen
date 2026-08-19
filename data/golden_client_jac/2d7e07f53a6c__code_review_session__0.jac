obj Ingredient {
    has name: str;
    has cost: float;
}
sem Ingredient.name = "Name of the grocery item";
sem Ingredient.cost = "Estimated cost in USD";

def plan_shopping(recipe: str) -> list[Ingredient] by llm();
sem plan_shopping = "Generate a shopping list for the given recipe";
sem plan_shopping.recipe = "A description of the meal to prepare";
