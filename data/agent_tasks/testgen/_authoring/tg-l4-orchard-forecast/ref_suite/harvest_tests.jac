import from model.varieties { Variety, MATURE_KG, age_factor }
import from model.orchard { Block, Row, Tree, HasRow, HasTree, plant_block }
import from harvest { Forecast, ForecastBlock }

def forecast(b: Block) -> Forecast {
    w = b spawn ForecastBlock();
    assert len(w.reports) == 1;
    return w.reports[0];
}

test "age factor boundaries" {
    assert age_factor(0) == 0.0;
    assert age_factor(2) == 0.0;
    assert age_factor(3) == 0.5;
    assert age_factor(5) == 0.5;
    assert age_factor(6) == 1.0;
    assert age_factor(20) == 1.0;
    assert age_factor(21) == 0.75;
    assert age_factor(60) == 0.75;
}

test "mature yields per variety" {
    assert MATURE_KG["GALA"] == 40.0;
    assert MATURE_KG["FUJI"] == 50.0;
    assert MATURE_KG["BRAEBURN"] == 35.0;
    assert MATURE_KG["HONEYCRISP"] == 30.0;
}

test "plant_block builds rows and trees in order" {
    b = plant_block("B", [[("a", Variety.GALA, 4)], [("b", Variety.FUJI, 7), ("c", Variety.FUJI, 9)]]);
    rows = [b ->:HasRow:->];
    assert sorted([r.index for r in rows]) == [0, 1];
    assert len([b ->:HasRow:-> ->:HasTree:->]) == 3;
    assert len([root -->[?:Block]]) == 1;
}

test "one mature tree of each variety" {
    b = plant_block("All", [[("g", Variety.GALA, 10), ("f", Variety.FUJI, 10), ("br", Variety.BRAEBURN, 10), ("h", Variety.HONEYCRISP, 10)]]);
    f = forecast(b);
    assert f.block == "All";
    assert f.by_variety == {"GALA": 40.0, "FUJI": 50.0, "BRAEBURN": 35.0, "HONEYCRISP": 30.0};
    assert f.total_kg == 155.0;
    assert f.trees_counted == 4;
}

test "young, prime and old trees across rows" {
    b = plant_block("Mix", [
        [("y", Variety.GALA, 4), ("o", Variety.GALA, 30)],
        [("s", Variety.BRAEBURN, 2), ("p", Variety.HONEYCRISP, 12)]
    ]);
    f = forecast(b);
    assert f.by_variety == {"GALA": 50.0, "BRAEBURN": 0.0, "HONEYCRISP": 30.0};
    assert f.total_kg == 80.0;
    assert f.trees_counted == 4;
}

test "diseased trees are skipped and not counted" {
    b = plant_block("Sick", [[("a", Variety.FUJI, 10), ("b", Variety.FUJI, 10), ("c", Variety.GALA, 10)]]);
    for t in [b ->:HasRow:-> ->:HasTree:->] {
        if t.tag != "a" {
            t.diseased = True;
        }
    }
    f = forecast(b);
    assert f.by_variety == {"FUJI": 50.0};
    assert f.total_kg == 50.0;
    assert f.trees_counted == 1;
}

test "empty block forecasts zero" {
    b = plant_block("Bare", []);
    f = forecast(b);
    assert f.block == "Bare";
    assert f.total_kg == 0.0;
    assert len(f.by_variety) == 0;
    assert f.trees_counted == 0;
}

test "forecast covers only its own block" {
    one = plant_block("One", [[("x", Variety.GALA, 10)]]);
    two = plant_block("Two", [[("y", Variety.FUJI, 10)], [("z", Variety.HONEYCRISP, 4)]]);
    f1 = forecast(one);
    f2 = forecast(two);
    assert f1.total_kg == 40.0;
    assert f1.trees_counted == 1;
    assert f2.block == "Two";
    assert f2.by_variety == {"FUJI": 50.0, "HONEYCRISP": 15.0};
    assert f2.total_kg == 65.0;
}
