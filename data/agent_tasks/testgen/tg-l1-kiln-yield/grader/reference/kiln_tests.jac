import from kiln { Firing, ConeStat, log_firing, ConeYield }

test "empty kiln log reports one empty list" {
    w = root spawn ConeYield();
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
}

test "log_firing stores the load on root" {
    f = log_firing("b1", 6, 12, 1, 2);
    loads = [root -->[?:Firing]];
    assert len(loads) == 1;
    assert loads[0].batch == "b1";
    assert loads[0].cone == 6;
    assert loads[0].pieces == 12;
    assert loads[0].cracked == 1;
    assert loads[0].glaze_faults == 2;
    assert loads[0].aborted == False;
}

test "perfect firing yields one hundred" {
    log_firing("p", 5, 8, 0, 0);
    s = (root spawn ConeYield()).reports[0][0];
    assert s.cone == 5;
    assert s.pieces == 8;
    assert s.losses == 0;
    assert s.yield_pct == 100;
}

test "losses add cracked and glaze faults and yield floors" {
    log_firing("a", 6, 7, 1, 1);
    s = (root spawn ConeYield()).reports[0][0];
    assert s.losses == 2;
    assert s.yield_pct == 71;
}

test "same cone loads are merged" {
    log_firing("a", 10, 10, 2, 0);
    log_firing("b", 10, 30, 0, 3);
    stats = (root spawn ConeYield()).reports[0];
    assert len(stats) == 1;
    assert stats[0].pieces == 40;
    assert stats[0].losses == 5;
    assert stats[0].yield_pct == 87;
}

test "cones are reported in ascending order" {
    log_firing("x", 9, 1, 0, 0);
    log_firing("y", 1, 2, 1, 0);
    log_firing("z", 4, 3, 0, 3);
    stats = (root spawn ConeYield()).reports[0];
    assert [s.cone for s in stats] == [1, 4, 9];
    assert [s.yield_pct for s in stats] == [50, 0, 100];
}

test "aborted loads are skipped" {
    f = log_firing("bad", 6, 10, 10, 0);
    f.aborted = True;
    log_firing("good", 6, 4, 1, 0);
    stats = (root spawn ConeYield()).reports[0];
    assert len(stats) == 1;
    assert stats[0].pieces == 4;
    assert stats[0].yield_pct == 75;
}

test "zero piece loads are skipped entirely" {
    log_firing("empty", 3, 0, 0, 0);
    w = root spawn ConeYield();
    assert len(w.reports[0]) == 0;
    assert len(w.totals) == 0;
}
