import from kiln { Firing, ConeStat, log_firing, ConeYield }

test "no firings gives one empty list" {
    w = root spawn ConeYield();
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
}

test "single cone totals and floor yield" {
    log_firing("b1", 6, 10, 1, 1);
    log_firing("b2", 6, 5, 0, 0);
    w = root spawn ConeYield();
    stats = w.reports[0];
    assert len(stats) == 1;
    assert stats[0].cone == 6;
    assert stats[0].pieces == 15;
    assert stats[0].losses == 2;
    assert stats[0].yield_pct == 86;
}

test "cones sorted ascending" {
    log_firing("b1", 10, 4, 0, 0);
    log_firing("b2", 4, 4, 1, 0);
    log_firing("b3", 6, 4, 2, 2);
    w = root spawn ConeYield();
    assert [s.cone for s in w.reports[0]] == [4, 6, 10];
    assert [s.yield_pct for s in w.reports[0]] == [75, 0, 100];
}

test "glaze faults count as losses" {
    log_firing("g", 5, 3, 0, 1);
    w = root spawn ConeYield();
    assert w.reports[0][0].losses == 1;
    assert w.reports[0][0].yield_pct == 66;
}

test "aborted and empty firings are ignored" {
    f = log_firing("x", 8, 20, 20, 0);
    f.aborted = True;
    log_firing("t", 8, 0, 0, 0);
    log_firing("t2", 9, 0, 0, 0);
    log_firing("ok", 8, 2, 0, 0);
    w = root spawn ConeYield();
    stats = w.reports[0];
    assert len(stats) == 1;
    assert stats[0].pieces == 2;
    assert stats[0].yield_pct == 100;
}
