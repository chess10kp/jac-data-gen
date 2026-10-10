import from recipe_scale { Ingredient, scale_recipe, family, convert, tidy }

def near(a: float, b: float) -> bool {
    return abs(a - b) < 1e-6;
}

test "scaling up multiplies every quantity" {
    out = scale_recipe([Ingredient(name="rice", qty=100.0, unit="g"), Ingredient(name="water", qty=2.0, unit="cup")], 2, 6);
    assert len(out) == 2;
    assert out[0].name == "rice";
    assert out[0].unit == "g";
    assert near(out[0].qty, 300.0);
    assert near(out[1].qty, 6.0);
    assert out[1].unit == "cup";
}

test "scaling down and input untouched" {
    items = [Ingredient(name="sugar", qty=90.0, unit="g")];
    out = scale_recipe(items, 3, 2);
    assert near(out[0].qty, 60.0);
    assert near(items[0].qty, 90.0);
    assert out[0] is not items[0];
}

test "same servings keeps quantities" {
    out = scale_recipe([Ingredient(name="salt", qty=1.5, unit="tsp")], 4, 4);
    assert near(out[0].qty, 1.5);
}

test "non-positive servings rejected" {
    with testraises(ValueError) {
        scale_recipe([], 0, 2);
    }
    with testraises(ValueError) {
        scale_recipe([], 2, 0);
    }
    with testraises(ValueError) {
        scale_recipe([], -1, 2);
    }
}

test "volume conversions" {
    assert near(convert(1.0, "cup", "ml"), 240.0);
    assert near(convert(3.0, "tsp", "tbsp"), 1.0);
    assert near(convert(2.0, "l", "cup"), 2000.0 / 240.0);
    assert near(convert(15.0, "ml", "tbsp"), 1.0);
}

test "weight conversions" {
    assert near(convert(2.0, "kg", "g"), 2000.0);
    assert near(convert(1.0, "oz", "g"), 28.35);
    assert near(convert(500.0, "g", "kg"), 0.5);
}

test "cross-family and unknown units are rejected" {
    with testraises(ValueError) {
        convert(1.0, "cup", "g");
    }
    with testraises(ValueError) {
        convert(1.0, "kg", "ml");
    }
    with testraises(ValueError) {
        convert(1.0, "pinch", "g");
    }
    with testraises(ValueError) {
        convert(1.0, "g", "pinch");
    }
}

test "family lookup" {
    assert family("tbsp") is not None;
    assert family("oz") is not None;
    assert family("tbsp") is not family("oz");
    assert family("pc") is None;
}

test "tidy picks the largest unit with quantity at least one" {
    t = tidy(Ingredient(name="milk", qty=1500.0, unit="ml"));
    assert t.unit == "l";
    assert near(t.qty, 1.5);
    t2 = tidy(Ingredient(name="milk", qty=480.0, unit="ml"));
    assert t2.unit == "cup";
    assert near(t2.qty, 2.0);
    t3 = tidy(Ingredient(name="oil", qty=6.0, unit="tsp"));
    assert t3.unit == "tbsp";
    assert near(t3.qty, 2.0);
    t4 = tidy(Ingredient(name="vanilla", qty=1.0, unit="tsp"));
    assert t4.unit == "tsp";
    assert near(t4.qty, 1.0);
    t5 = tidy(Ingredient(name="drop", qty=2.0, unit="ml"));
    assert t5.unit == "ml";
    assert near(t5.qty, 2.0);
}

test "tidy weights and exact boundary" {
    t = tidy(Ingredient(name="flour", qty=1000.0, unit="g"));
    assert t.unit == "kg";
    assert near(t.qty, 1.0);
    t2 = tidy(Ingredient(name="flour", qty=999.0, unit="g"));
    assert t2.unit == "g";
    t3 = tidy(Ingredient(name="cheese", qty=8.0, unit="oz"));
    assert t3.unit == "g";
    assert near(t3.qty, 226.8);
    t4 = tidy(Ingredient(name="yeast", qty=0.5, unit="g"));
    assert t4.unit == "g";
    assert near(t4.qty, 0.5);
}

test "tidy leaves unknown units alone" {
    t = tidy(Ingredient(name="egg", qty=3.0, unit="pc"));
    assert t.name == "egg";
    assert t.unit == "pc";
    assert near(t.qty, 3.0);
}
