"""GenerateShoppingList walker with an optional budget cap."""

enum Unit { PIECE, LB, OZ, CUP, TBSP, TSP, BUNCH }

obj Ingredient {
    has name: str, quantity: float, unit: Unit, cost: float, carby: bool;
}

def generate_shopping_list(meal_description: str) -> list[Ingredient] by llm();
sem generate_shopping_list = "Generate a shopping list for a described meal";

node ShoppingItem {
    has name: str, quantity: float, unit: str, cost: float, carby: bool;
}

walker GenerateShoppingList {
    has meal_description: str,
        max_budget: float = 0.0,
        reports: list[list[ShoppingItem]] = [];

    can generate with Root entry {
        # Queue connected nodes for traversal after this ability completes
        visit [-->];
        ingredients = generate_shopping_list(self.meal_description);
        running = 0.0;
        for ing in ingredients {
            # Skip items that would push us over the budget (0.0 = no cap).
            if self.max_budget > 0.0 and running + ing.cost > self.max_budget {
                continue;
            }
            running += ing.cost;
            here ++> ShoppingItem(
                name=ing.name, quantity=ing.quantity,
                unit=str(ing.unit).split(".")[-1].lower(),
                cost=ing.cost, carby=ing.carby
            );
        }
        report [here-->][?:ShoppingItem];
    }

    can clear_old with ShoppingItem entry {
        del here;
    }
}
