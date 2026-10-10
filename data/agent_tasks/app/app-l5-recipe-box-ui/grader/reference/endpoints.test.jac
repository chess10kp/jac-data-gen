test "ingredients are shared nodes" {
    a = (root spawn add_recipe(title="Unit Pesto", ingredients=["Basil", " garlic ", ""])).reports[0];
    b = (root spawn add_recipe(title="Unit Aioli", ingredients=["GARLIC", "egg"])).reports[0];
    assert list(a["ingredients"]) == ["basil", "garlic"];
    assert len([i for i in [root -->[?:Ingredient]] if i.name == "garlic"]) == 1;
    hits = [v["title"] for v in (root spawn recipes_with(ingredient="garlic")).reports[0]];
    assert "Unit Pesto" in hits and "Unit Aioli" in hits;
    assert b["rating"] == 0.0;
}

test "rating validation" {
    r = (root spawn add_recipe(title="Unit Toast", ingredients=["bread"])).reports[0];
    assert "error" in (root spawn rate_recipe(recipe_id=r["id"], stars=6)).reports[0];
    v = (root spawn rate_recipe(recipe_id=r["id"], stars=4)).reports[0];
    assert v["ratings"] == 1 and v["rating"] == 4.0;
}
