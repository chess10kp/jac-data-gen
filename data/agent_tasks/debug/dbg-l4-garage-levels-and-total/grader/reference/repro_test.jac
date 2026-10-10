import from garage { AddLevel, Enter, Occupancy }

test "lowest level first and total across levels" {
    root spawn AddLevel(number=3, spots=5);
    root spawn AddLevel(number=1, spots=2);
    root spawn AddLevel(number=2, spots=2);
    for p in ["a", "b", "c"] {
        root spawn Enter(plate=p, minute=0);
    }
    w = root spawn Occupancy();
    assert w.reports[0] == {3: 0, 1: 2, 2: 1};
    assert w.total == 3;
}
