import from cookbook { Recipe, Ingredient, Needs, SubstitutesFor, CookPlan, add_recipe, allow_substitute, WhatCanICook }

test "empty cookbook reports empty list" {
    w = root spawn WhatCanICook(pantry=["eggs"]);
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
}

test "all required present means cookable with no swaps" {
    add_recipe("omelette", ["eggs", "salt"], []);
    add_recipe("bread", ["flour", "yeast"], []);
    w = root spawn WhatCanICook(pantry=["eggs", "salt", "flour"]);
    plans = w.reports[0];
    assert len(plans) == 1;
    assert plans[0].title == "omelette";
    assert len(plans[0].swaps) == 0;
}

test "optional ingredients never block" {
    add_recipe("pancakes", ["flour", "milk"], ["blueberries"]);
    w = root spawn WhatCanICook(pantry=["flour", "milk"]);
    assert [p.title for p in w.reports[0]] == ["pancakes"];
    assert len(w.reports[0][0].swaps) == 0;
}

test "one hop substitute is used and recorded" {
    add_recipe("shortbread", ["flour", "butter", "sugar"], []);
    allow_substitute("butter", "margarine");
    w = root spawn WhatCanICook(pantry=["flour", "sugar", "margarine"]);
    assert w.reports[0][0].title == "shortbread";
    assert w.reports[0][0].swaps == ["butter->margarine"];
}

test "substitution is one directional" {
    add_recipe("spread", ["margarine"], []);
    allow_substitute("butter", "margarine");
    w = root spawn WhatCanICook(pantry=["butter"]);
    assert len(w.reports[0]) == 0;
}

test "no chained substitutes" {
    add_recipe("cake", ["buttermilk"], []);
    allow_substitute("buttermilk", "yogurt");
    allow_substitute("yogurt", "sour cream");
    w = root spawn WhatCanICook(pantry=["sour cream"]);
    assert len(w.reports[0]) == 0;
}

test "alphabetically first substitute and sorted swaps and titles" {
    add_recipe("zucchini fritters", ["zucchini", "eggs", "breadcrumbs"], []);
    add_recipe("apple crumble", ["apples", "oats"], []);
    allow_substitute("eggs", "flax gel");
    allow_substitute("eggs", "aquafaba");
    allow_substitute("breadcrumbs", "panko");
    allow_substitute("oats", "granola");
    w = root spawn WhatCanICook(pantry=["zucchini", "flax gel", "aquafaba", "panko", "apples", "granola"]);
    plans = w.reports[0];
    assert [p.title for p in plans] == ["apple crumble", "zucchini fritters"];
    assert plans[0].swaps == ["oats->granola"];
    assert plans[1].swaps == ["breadcrumbs->panko", "eggs->aquafaba"];
}

test "ingredient in pantry is not swapped even if a substitute is also there" {
    add_recipe("toast", ["butter"], []);
    allow_substitute("butter", "margarine");
    w = root spawn WhatCanICook(pantry=["butter", "margarine"]);
    assert len(w.reports[0][0].swaps) == 0;
}
