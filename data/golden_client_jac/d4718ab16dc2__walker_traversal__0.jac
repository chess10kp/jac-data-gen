walker GenerateShoppingList {
    has meal_description: str,
        reports: list[list[ShoppingItem]] = [];

    can generate with Root entry {
        # Queue connected nodes for traversal after this ability completes
        visit [-->];
        # Generate new ingredients (runs before queued visits)
        ingredients = generate_shopping_list(self.meal_description);
        for ing in ingredients {
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
