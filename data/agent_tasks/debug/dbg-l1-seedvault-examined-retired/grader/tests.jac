import from vault { SeedLot, bank_lot, RegrowPlan }

test "nothing banked gives an empty plan" {
    w = root spawn RegrowPlan(year=2026);
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
    assert w.examined == 0;
}

test "age boundary at ten years" {
    bank_lot("A-10", "wheat", 2016, 90, 500);
    bank_lot("A-09", "wheat", 2017, 90, 500);
    w = root spawn RegrowPlan(year=2026);
    assert w.reports[0] == {"wheat": ["A-10"]};
    assert w.examined == 2;
}

test "germination boundary at seventy five" {
    bank_lot("G74", "barley", 2024, 74, 500);
    bank_lot("G75", "barley", 2024, 75, 500);
    w = root spawn RegrowPlan(year=2026);
    assert w.reports[0] == {"barley": ["G74"]};
}

test "stock boundary at two hundred seeds" {
    bank_lot("S199", "lentil", 2024, 95, 199);
    bank_lot("S200", "lentil", 2024, 95, 200);
    w = root spawn RegrowPlan(year=2026);
    assert w.reports[0] == {"lentil": ["S199"]};
}

test "grouped by species with sorted accessions" {
    bank_lot("W-3", "wheat", 2000, 90, 500);
    bank_lot("R-1", "rye", 2025, 50, 500);
    bank_lot("W-1", "wheat", 2025, 60, 500);
    bank_lot("W-2", "wheat", 2025, 99, 900);
    bank_lot("O-1", "oat", 2025, 99, 900);
    w = root spawn RegrowPlan(year=2026);
    plan = w.reports[0];
    assert plan == {"wheat": ["W-1", "W-3"], "rye": ["R-1"]};
    assert "oat" not in plan;
    assert w.examined == 5;
}

test "retired lots are skipped and not counted" {
    lot = bank_lot("X-1", "flax", 1990, 10, 5);
    lot.retired = True;
    bank_lot("X-2", "flax", 1990, 10, 5);
    w = root spawn RegrowPlan(year=2026);
    assert w.reports[0] == {"flax": ["X-2"]};
    assert w.examined == 1;
}
