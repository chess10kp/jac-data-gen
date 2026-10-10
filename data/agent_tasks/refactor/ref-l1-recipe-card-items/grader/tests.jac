import from recipe_card { RecipeCard, add_item, rescale, total_in, item_names, swap_item }

test "adding items keeps order and rejects duplicates" {
    c = RecipeCard(title="pancakes", servings=4);
    assert add_item(c, "flour", 200.0, "g");
    assert add_item(c, "milk", 300.0, "ml");
    assert add_item(c, "sugar", 25.0, "g");
    assert not add_item(c, "flour", 50.0, "g");
    assert item_names(c) == ["flour", "milk", "sugar"];
    assert total_in(c, "g") == 225.0;
    assert total_in(c, "ml") == 300.0;
    assert total_in(c, "cup") == 0.0;
}

test "rescale makes a new card" {
    c = RecipeCard(title="stew", servings=4);
    add_item(c, "beef", 800.0, "g");
    add_item(c, "stock", 1000.0, "ml");
    add_item(c, "salt", 10.0, "g");
    d = rescale(c, 6);
    assert item_names(d) == ["beef", "stock", "salt"];
    assert total_in(d, "g") == 1215.0;
    assert total_in(d, "ml") == 1500.0;
    assert total_in(c, "g") == 810.0;
    h = rescale(c, 2);
    assert total_in(h, "ml") == 500.0;
}

test "rescaled cards are independent" {
    c = RecipeCard(title="bread", servings=1);
    add_item(c, "flour", 500.0, "g");
    d = rescale(c, 1);
    assert swap_item(d, "flour", "rye flour");
    assert add_item(d, "seeds", 20.0, "g");
    assert item_names(c) == ["flour"];
    assert item_names(d) == ["rye flour", "seeds"];
    assert total_in(c, "g") == 500.0;
}

test "swap renames only the first match" {
    c = RecipeCard(title="salad", servings=2);
    add_item(c, "lettuce", 1.0, "head");
    add_item(c, "oil", 30.0, "ml");
    assert swap_item(c, "oil", "olive oil");
    assert not swap_item(c, "oil", "x");
    assert not add_item(c, "olive oil", 5.0, "ml");
    assert add_item(c, "oil", 5.0, "ml");
    assert item_names(c) == ["lettuce", "olive oil", "oil"];
    assert total_in(c, "ml") == 35.0;
}
