import from byllm.lib { Model }

glob llm = Model(model_name="local:gemma-4-e4b");

obj Ingredient {
    has name: str,
        quantity: float,
        unit: str,
        cost: float,
        carby: bool;
}

node ShoppingItem {
    has name: str,
        quantity: float,
        unit: str,
        cost: float,
        carby: bool,
        purchased: bool = False;
}

"""Use AI to break a meal description into a list of ingredients."""
def generate_shopping_list(meal: str) -> list[Ingredient] by llm();

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
            unit=ing.unit, cost=ing.cost, carby=ing.carby
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

"""Toggle whether an item has been purchased."""
def:pub toggle_purchased(id: str) -> ShoppingItem | None {
    for item in [root-->][?:ShoppingItem] {
        if jid(item) == id {
            item.purchased = not item.purchased;
            return item;
        }
    }
    return None;
}

"""Total cost of the items still left to buy."""
def:pub remaining_cost -> float {
    total = 0.0;
    for item in [root-->][?:ShoppingItem] {
        if not item.purchased {
            total += item.cost;
        }
    }
    return total;
}
