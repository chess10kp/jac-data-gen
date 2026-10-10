import from recipe_scale { Ingredient, scale_recipe, convert, tidy }

def close(a: float, b: float) -> bool {
    return abs(a - b) < 1e-6;
}

test "scale doubles and leaves input alone" {
    items = [Ingredient(name="flour", qty=200.0, unit="g"), Ingredient(name="milk", qty=1.5, unit="cup")];
    out = scale_recipe(items, 2, 4);
    assert len(out) == 2;
    assert out[0].name == "flour" and close(out[0].qty, 400.0) and out[0].unit == "g";
    assert close(out[1].qty, 3.0) and out[1].unit == "cup";
    assert close(items[0].qty, 200.0), "input list was mutated";
}

test "scale down to fraction" {
    out = scale_recipe([Ingredient(name="egg", qty=3.0, unit="pc")], 6, 4);
    assert close(out[0].qty, 2.0);
}

test "scale rejects bad servings" {
    try {
        scale_recipe([Ingredient(name="x", qty=1.0, unit="g")], 0, 4);
        assert False, "expected ValueError";
    } except ValueError {
        assert True;
    }
    try {
        scale_recipe([Ingredient(name="x", qty=1.0, unit="g")], 4, -1);
        assert False, "expected ValueError";
    } except ValueError {
        assert True;
    }
}

test "convert volumes and weights" {
    assert close(convert(1.0, "cup", "tbsp"), 16.0);
    assert close(convert(3.0, "tsp", "tbsp"), 1.0);
    assert close(convert(2.0, "l", "ml"), 2000.0);
    assert close(convert(1.0, "kg", "g"), 1000.0);
    assert close(convert(56.7, "g", "oz"), 2.0);
    assert close(convert(5.0, "ml", "ml"), 5.0);
}

test "convert rejects mixed families and unknown units" {
    try {
        convert(1.0, "cup", "g");
        assert False, "expected ValueError";
    } except ValueError {
        assert True;
    }
    try {
        convert(1.0, "pinch", "tsp");
        assert False, "expected ValueError";
    } except ValueError {
        assert True;
    }
}

test "tidy picks largest sensible unit" {
    a = tidy(Ingredient(name="sugar", qty=48.0, unit="tsp"));
    assert a.unit == "cup" and close(a.qty, 1.0);
    b = tidy(Ingredient(name="water", qty=1500.0, unit="ml"));
    assert b.unit == "l" and close(b.qty, 1.5);
    c = tidy(Ingredient(name="salt", qty=2.0, unit="tsp"));
    assert c.unit == "tsp" and close(c.qty, 2.0);
    d = tidy(Ingredient(name="rice", qty=900.0, unit="g"));
    assert d.unit == "g" and close(d.qty, 900.0);
    e = tidy(Ingredient(name="rice", qty=2500.0, unit="g"));
    assert e.unit == "kg" and close(e.qty, 2.5);
    f = tidy(Ingredient(name="oil", qty=6.0, unit="tsp"));
    assert f.unit == "tbsp" and close(f.qty, 2.0);
    g = tidy(Ingredient(name="egg", qty=3.0, unit="pc"));
    assert g.unit == "pc" and close(g.qty, 3.0) and g.name == "egg";
}
