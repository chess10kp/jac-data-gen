import from cookbook { add_recipe, WhatCanICook }

test "optional ingredient does not block a recipe" {
    add_recipe("pancakes", ["flour", "milk"], ["blueberries"]);
    w = root spawn WhatCanICook(pantry=["flour", "milk"]);
    assert [p.title for p in w.reports[0]] == ["pancakes"];
}
