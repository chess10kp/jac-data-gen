import from vault { SeedLot, bank_lot, RegrowPlan }

test "empty vault gives empty plan" {
    w = root spawn RegrowPlan(year=2030);
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
    assert w.examined == 0;
}

test "healthy lot is examined but not planned" {
    bank_lot("H1", "maize", 2025, 90, 900);
    w = root spawn RegrowPlan(year=2026);
    assert len(w.reports[0]) == 0;
    assert w.examined == 1;
}

test "ten years old triggers regrow, nine does not" {
    bank_lot("old", "rice", 2010, 99, 999);
    bank_lot("young", "rice", 2011, 99, 999);
    w = root spawn RegrowPlan(year=2020);
    assert w.reports[0] == {"rice": ["old"]};
}

test "germination below seventy five triggers" {
    bank_lot("g74", "pea", 2025, 74, 999);
    bank_lot("g75", "pea", 2025, 75, 999);
    bank_lot("g76", "pea", 2025, 76, 999);
    w = root spawn RegrowPlan(year=2026);
    assert w.reports[0] == {"pea": ["g74"]};
}

test "fewer than two hundred seeds triggers" {
    bank_lot("s199", "bean", 2025, 99, 199);
    bank_lot("s200", "bean", 2025, 99, 200);
    w = root spawn RegrowPlan(year=2026);
    assert w.reports[0] == {"bean": ["s199"]};
}

test "any one reason is enough" {
    bank_lot("age", "oat", 2000, 99, 999);
    bank_lot("germ", "oat", 2025, 10, 999);
    bank_lot("stock", "oat", 2025, 99, 5);
    w = root spawn RegrowPlan(year=2026);
    assert w.reports[0] == {"oat": ["age", "germ", "stock"]};
    assert w.examined == 3;
}

test "plan groups by species and sorts accessions" {
    bank_lot("Z9", "kale", 2025, 50, 999);
    bank_lot("A1", "kale", 2025, 50, 999);
    bank_lot("M5", "chard", 2025, 50, 999);
    bank_lot("ok", "chard", 2025, 99, 999);
    w = root spawn RegrowPlan(year=2026);
    assert w.reports[0] == {"kale": ["A1", "Z9"], "chard": ["M5"]};
    assert w.plan["kale"] == ["Z9", "A1"] or w.plan["kale"] == ["A1", "Z9"];
}

test "retired lots are neither counted nor planned" {
    r = bank_lot("R", "flax", 1900, 1, 1);
    r.retired = True;
    w = root spawn RegrowPlan(year=2026);
    assert len(w.reports[0]) == 0;
    assert w.examined == 0;
}

test "bank_lot stores fields on a root lot" {
    bank_lot("B1", "millet", 2021, 88, 450);
    lots = [root -->[?:SeedLot]];
    assert len(lots) == 1;
    assert lots[0].accession == "B1";
    assert lots[0].species == "millet";
    assert lots[0].banked_year == 2021;
    assert lots[0].germination == 88;
    assert lots[0].seeds_left == 450;
    assert lots[0].retired == False;
}
