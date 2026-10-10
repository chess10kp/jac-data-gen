import from vault { bank_lot, RegrowPlan }

test "lot banked exactly ten years ago is due" {
    bank_lot("W-2016", "wheat", 2016, 95, 800);
    w = root spawn RegrowPlan(year=2026);
    assert w.reports[0] == {"wheat": ["W-2016"]};
}
