import from cookbook { add_recipe, allow_swap, missing, swaps_needed, cookable, used_in }

def stock_kitchen {
    add_recipe("pancakes", ["flour", "milk", "egg"], ["syrup"]);
    add_recipe("omelette", ["egg", "butter"], ["chives"]);
    add_recipe("flatbread", ["flour", "water"], []);
    allow_swap("milk", "oat milk");
    allow_swap("butter", "oil");
    allow_swap("butter", "ghee");
}

test "recipes are unique and swaps are deduplicated" {
    assert add_recipe("toast", ["bread"], ["butter"]);
    assert not add_recipe("toast", ["bread"], []);
    assert allow_swap("butter", "oil");
    assert not allow_swap("butter", "oil");
    assert not allow_swap("oil", "oil");
    assert allow_swap("oil", "butter");
}

test "missing ingredients ignore optional ones and count swaps" {
    stock_kitchen();
    assert len(missing("pancakes", ["flour", "milk", "egg"])) == 0;
    assert missing("pancakes", ["flour"]) == ["egg", "milk"];
    assert missing("pancakes", ["flour", "oat milk"]) == ["egg"];
    assert len(missing("omelette", ["egg", "oil"])) == 0;
    assert len(missing("omelette", ["egg", "ghee"])) == 0;
    assert missing("omelette", ["chives"]) == ["butter", "egg"];
    assert len(missing("waffles", [])) == 0;
}

test "swaps are one-way and the first alphabetical option is used" {
    stock_kitchen();
    assert swaps_needed("omelette", ["egg", "oil", "ghee"]) == ["butter->ghee"];
    assert swaps_needed("omelette", ["egg", "oil"]) == ["butter->oil"];
    assert len(swaps_needed("omelette", ["egg", "butter", "oil"])) == 0;
    assert swaps_needed("pancakes", ["flour", "oat milk", "egg"]) == ["milk->oat milk"];
    assert missing("pancakes", ["flour", "egg", "oil"]) == ["milk"];
    add_recipe("granola", ["oat milk", "oats"], []);
    assert missing("granola", ["milk", "oats"]) == ["oat milk"];
    assert len(swaps_needed("granola", ["milk", "oats"])) == 0;
}

test "what can be cooked from a stock list" {
    stock_kitchen();
    assert cookable(["flour", "water", "egg", "oil"]) == ["flatbread", "omelette"];
    assert cookable(["flour", "egg", "oat milk", "water"]) == ["flatbread", "pancakes"];
    assert len(cookable(["syrup", "chives"])) == 0;
}

test "where an ingredient is used, optional included" {
    stock_kitchen();
    assert used_in("egg") == ["omelette", "pancakes"];
    assert used_in("flour") == ["flatbread", "pancakes"];
    assert used_in("chives") == ["omelette"];
    assert used_in("syrup") == ["pancakes"];
    assert len(used_in("saffron")) == 0;
    assert len(used_in("oil")) == 0;
}
