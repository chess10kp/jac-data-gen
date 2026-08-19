"""Generate a shopping list from a meal description."""
def:pub generate_list(meal: str) -> list[ShoppingItem] {
    # Clear old items
    for item in [root-->][?:ShoppingItem] {
        del item;
    }
    # Generate new ones
    ingredients = generate_shopping_list(meal);
    for ing in ingredients {
        root ++> ShoppingItem(
            name=ing.name, quantity=ing.quantity,
            unit=str(ing.unit).split(".")[-1].lower(),
            cost=ing.cost, carby=ing.carby
        );
    }
    return [root-->][?:ShoppingItem];
}

"""Get the current shopping list."""
def:pub get_shopping_list -> list[ShoppingItem] {
    return [root-->][?:ShoppingItem];
}

"""Clear the shopping list."""
def:pub clear_shopping_list -> dict[str, bool] {
    for item in [root-->][?:ShoppingItem] {
        del item;
    }
    return {"cleared": True};
}
