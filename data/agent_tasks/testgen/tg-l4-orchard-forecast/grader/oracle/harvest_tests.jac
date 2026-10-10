import from model.varieties { Variety, MATURE_KG, age_factor }
import from model.orchard { Block, Row, Tree, plant_block }
import from harvest { Forecast, ForecastBlock }

test "honeycrisp variety added with its mature yield" {
    assert Variety.HONEYCRISP.name == "HONEYCRISP";
    assert MATURE_KG["HONEYCRISP"] == 30.0;
    assert MATURE_KG["GALA"] == 40.0;
    assert len([v for v in Variety]) == 4;
}

test "single mature tree" {
    b = plant_block("North", [[("t1", Variety.GALA, 10)]]);
    f = (b spawn ForecastBlock()).reports[0];
    assert f.block == "North";
    assert f.total_kg == 40.0;
    assert f.by_variety == {"GALA": 40.0};
    assert f.trees_counted == 1;
}

test "age curve and several rows" {
    b = plant_block("East", [
        [("a", Variety.FUJI, 4), ("b", Variety.FUJI, 25)],
        [("c", Variety.HONEYCRISP, 8), ("d", Variety.BRAEBURN, 1)]
    ]);
    f = (b spawn ForecastBlock()).reports[0];
    assert f.by_variety == {"FUJI": 62.5, "HONEYCRISP": 30.0, "BRAEBURN": 0.0};
    assert f.total_kg == 92.5;
    assert f.trees_counted == 4;
}

test "diseased trees contribute nothing and are not counted" {
    b = plant_block("West", [[("x", Variety.GALA, 10), ("y", Variety.FUJI, 10)]]);
    for t in [b --> --> [?:Tree]] {
        if t.tag == "y" {
            t.diseased = True;
        }
    }
    f = (b spawn ForecastBlock()).reports[0];
    assert f.by_variety == {"GALA": 40.0};
    assert f.trees_counted == 1;
}

test "forecast is per block" {
    b1 = plant_block("One", [[("p", Variety.GALA, 10)]]);
    b2 = plant_block("Two", [[("q", Variety.FUJI, 10)], [("r", Variety.FUJI, 10)]]);
    f2 = (b2 spawn ForecastBlock()).reports[0];
    assert f2.block == "Two";
    assert f2.total_kg == 100.0;
    assert len((b1 spawn ForecastBlock()).reports) == 1;
}
