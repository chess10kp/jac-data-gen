import from cookbook { Recipe, Ingredient, Needs, SubstitutesFor, CookPlan, ingredient, add_recipe, allow_substitute, WhatCanICook }

test "no recipes reports an empty list once" {
    w = root spawn WhatCanICook(pantry=[]);
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
}

test "ingredients are shared nodes" {
    add_recipe("a", ["salt"], []);
    add_recipe("b", ["salt", "pepper"], []);
    assert len([root -->[?:Ingredient]]) == 2;
    assert ingredient("salt").name == "salt";
    assert len([root -->[?:Ingredient]]) == 2;
}

test "missing required ingredient without substitute blocks the recipe" {
    add_recipe("soup", ["leek", "potato"], []);
    w = root spawn WhatCanICook(pantry=["leek"]);
    assert len(w.reports[0]) == 0;
    assert len(w.plans) == 0;
}

test "fully stocked recipe needs no swaps" {
    add_recipe("salad", ["lettuce", "oil"], []);
    plans = (root spawn WhatCanICook(pantry=["oil", "lettuce", "extra"])).reports[0];
    assert len(plans) == 1;
    assert plans[0].title == "salad";
    assert len(plans[0].swaps) == 0;
}

test "optional ingredients are ignored" {
    add_recipe("rice", ["rice"], ["saffron", "peas"]);
    plans = (root spawn WhatCanICook(pantry=["rice"])).reports[0];
    assert [p.title for p in plans] == ["rice"];
    assert len(plans[0].swaps) == 0;
}

test "direct substitute is used and recorded" {
    add_recipe("muffins", ["milk", "flour"], []);
    allow_substitute("milk", "oat milk");
    plans = (root spawn WhatCanICook(pantry=["flour", "oat milk"])).reports[0];
    assert plans[0].swaps == ["milk->oat milk"];
}

test "substitutes only work in the declared direction" {
    add_recipe("latte", ["oat milk"], []);
    allow_substitute("milk", "oat milk");
    assert len((root spawn WhatCanICook(pantry=["milk"])).reports[0]) == 0;
}

test "substitutes do not chain" {
    add_recipe("dip", ["cream"], []);
    allow_substitute("cream", "yogurt");
    allow_substitute("yogurt", "kefir");
    assert len((root spawn WhatCanICook(pantry=["kefir"])).reports[0]) == 0;
}

test "alphabetically first available substitute wins" {
    add_recipe("stew", ["beef"], []);
    allow_substitute("beef", "tofu");
    allow_substitute("beef", "lentils");
    allow_substitute("beef", "chicken");
    plans = (root spawn WhatCanICook(pantry=["tofu", "lentils"])).reports[0];
    assert plans[0].swaps == ["beef->lentils"];
}

test "swaps sorted and recipes reported by title" {
    add_recipe("waffles", ["milk", "eggs", "flour"], []);
    add_recipe("crepes", ["flour", "milk"], []);
    add_recipe("mousse", ["chocolate"], []);
    allow_substitute("milk", "soy milk");
    allow_substitute("eggs", "banana");
    w = root spawn WhatCanICook(pantry=["flour", "soy milk", "banana"]);
    plans = w.reports[0];
    assert [p.title for p in plans] == ["crepes", "waffles"];
    assert plans[0].swaps == ["milk->soy milk"];
    assert plans[1].swaps == ["eggs->banana", "milk->soy milk"];
}

test "pantry item preferred over substitute" {
    add_recipe("eggs on toast", ["eggs"], []);
    allow_substitute("eggs", "tofu");
    plans = (root spawn WhatCanICook(pantry=["tofu", "eggs"])).reports[0];
    assert len(plans[0].swaps) == 0;
}
