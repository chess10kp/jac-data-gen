import from orchard { Orchard }

def sample -> Orchard {
    o = Orchard(name="Ridge");
    o.add_block("north");
    o.add_block("south");
    o.plant("north", 1, 1, "N1", "gala", 8);
    o.plant("north", 1, 2, "N2", "fuji", 4);
    o.plant("north", 2, 1, "N3", "braeburn", 25);
    o.plant("north", 3, 1, "N4", "honeycrisp", 2);
    o.plant("south", 1, 1, "S1", "fuji", 10);
    return o;
}

test "planting validates block, variety, tag and slot" {
    o = Orchard(name="x");
    assert o.add_block("east");
    assert not o.add_block("east");
    assert o.plant("east", 1, 1, "T1", "gala", 5);
    assert not o.plant("west", 1, 1, "T2", "gala", 5);
    assert not o.plant("east", 1, 2, "T3", "cox", 5);
    assert not o.plant("east", 2, 1, "T1", "fuji", 5);
    assert not o.plant("east", 1, 1, "T4", "fuji", 5);
    assert o.plant("east", 2, 1, "T4", "fuji", 5);
    assert o.tree_at("east", 1, 1) == "T1";
    assert o.tree_at("east", 2, 1) == "T4";
    assert o.tree_at("east", 1, 2) == "";
    assert o.tree_at("west", 1, 1) == "";
}

test "forecast weighs variety and age" {
    o = sample();
    assert o.forecast("north") == 91.25;
    assert o.forecast("south") == 50.0;
    assert o.forecast("nowhere") == 0.0;
    assert o.variety_totals("north") == ["braeburn 26.2", "fuji 25.0", "gala 40.0", "honeycrisp 0.0"];
}

test "diseased trees are left out" {
    o = sample();
    assert o.mark_diseased("N1");
    assert not o.mark_diseased("Q9");
    assert o.forecast("north") == 51.25;
    assert o.variety_totals("north") == ["braeburn 26.2", "fuji 25.0", "honeycrisp 0.0"];
    assert o.healthy_rows("north") == [1, 1, 1];
    o.mark_diseased("N4");
    assert o.healthy_rows("north") == [1, 1, 0];
}

test "rows are counted per row number" {
    o = sample();
    o.plant("north", 1, 3, "N5", "gala", 1);
    o.plant("north", 7, 2, "N6", "gala", 1);
    assert o.healthy_rows("north") == [3, 1, 1, 1];
    assert o.healthy_rows("south") == [1];
    assert len(o.healthy_rows("nowhere")) == 0;
}

test "a season ages every tree" {
    o = sample();
    o.next_season();
    assert o.forecast("north") == 106.25;
    o.next_season();
    assert o.forecast("north") == 131.25;
    assert o.variety_totals("south") == ["fuji 50.0"];
}

test "orchards are independent" {
    a = sample();
    b = Orchard(name="Vale");
    b.add_block("north");
    assert b.plant("north", 1, 1, "N1", "gala", 8);
    assert b.forecast("north") == 40.0;
    b.next_season();
    assert a.forecast("north") == 91.25;
    assert b.mark_diseased("N1");
    assert a.forecast("north") == 91.25;
}
