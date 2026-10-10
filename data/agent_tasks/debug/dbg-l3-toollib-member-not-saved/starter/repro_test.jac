import from toollib { RegisterTool, Checkout }

test "third tool for the same card hits the limit" {
    root spawn RegisterTool(code="DR1", name="Drill");
    root spawn RegisterTool(code="SW1", name="Saw");
    root spawn RegisterTool(code="LD1", name="Ladder");
    root spawn Checkout(card="c7", code="DR1", day=1);
    root spawn Checkout(card="c7", code="SW1", day=1);
    r = root spawn Checkout(card="c7", code="LD1", day=1);
    assert r.reports[0].reason == "limit reached";
}
