import from warehouse { Warehouse }

def sample -> Warehouse {
    w = Warehouse(name="Depot");
    w.add_aisle();
    w.add_aisle();
    w.add_aisle();
    w.stock(1, "A1-hi", "bolt", 40, 3);
    w.stock(1, "A1-lo", "nut", 10, 1);
    w.stock(1, "A1-mid", "bolt", 5, 2);
    w.stock(2, "A2-a", "nut", 25, 1);
    w.stock(2, "A2-b", "washer", 5, 1);
    w.stock(3, "A3-a", "bolt", 15, 1);
    return w;
}

test "aisles and bins validate" {
    w = Warehouse(name="x");
    assert w.add_aisle() == 1;
    assert w.add_aisle() == 2;
    assert w.stock(2, "B1", "bolt", 3, 1);
    assert not w.stock(3, "B2", "bolt", 3, 1);
    assert not w.stock(0, "B2", "bolt", 3, 1);
    assert not w.stock(1, "B1", "nut", 3, 1);
    assert w.on_hand("bolt") == 3;
    assert w.on_hand("nut") == 0;
}

test "picks go aisle by aisle, low shelves first" {
    w = sample();
    lines = w.pick({"bolt": 50, "nut": 12});
    assert lines == ["A1/A1-lo nut x10", "A1/A1-mid bolt x5", "A1/A1-hi bolt x40", "A2/A2-a nut x2", "A3/A3-a bolt x5"];
    assert w.on_hand("bolt") == 10;
    assert w.on_hand("nut") == 23;
}

test "the walk stops once the order is filled" {
    w = sample();
    assert w.aisles_needed({"nut": 4}) == 1;
    assert w.aisles_needed({"washer": 1}) == 2;
    assert w.aisles_needed({"bolt": 46}) == 3;
    assert w.aisles_needed({"bolt": 999}) == 3;
    assert w.on_hand("bolt") == 60;
    assert w.pick({"washer": 2}) == ["A2/A2-b washer x2"];
    assert w.on_hand("washer") == 3;
}

test "short orders take what there is" {
    w = sample();
    assert w.pick({"washer": 9, "gear": 2}) == ["A2/A2-b washer x5"];
    assert w.on_hand("washer") == 0;
    assert len(w.pick({"washer": 1})) == 0;
}

test "blocked bins are skipped and not counted" {
    w = sample();
    assert w.block_bin("A1-mid");
    assert not w.block_bin("A1-mid");
    assert not w.block_bin("ZZ");
    assert w.on_hand("bolt") == 55;
    assert w.pick({"bolt": 42}) == ["A1/A1-hi bolt x40", "A3/A3-a bolt x2"];
    assert w.aisles_needed({"bolt": 1}) == 3;
}

test "warehouses are independent" {
    a = sample();
    b = Warehouse(name="Annex");
    assert b.add_aisle() == 1;
    assert b.stock(1, "A1-hi", "bolt", 1, 1);
    b.pick({"bolt": 1});
    assert b.on_hand("bolt") == 0;
    assert a.on_hand("bolt") == 60;
}
