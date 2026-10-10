import from kiln { log_firing, ConeYield }

test "yield percentage is rounded down" {
    log_firing("b1", 6, 10, 1, 1);
    log_firing("b2", 6, 5, 0, 0);
    stats = (root spawn ConeYield()).reports[0];
    assert stats[0].yield_pct == 86;
}
