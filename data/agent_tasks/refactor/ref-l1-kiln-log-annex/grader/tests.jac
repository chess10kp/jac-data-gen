import from kiln_log { Firing, firing_line, cone_yield, worst_batch }

test "single firing yield and line" {
    f = Firing(batch="mugs-7", cone=6, pieces=20, cracked=2, glaze_faults=1);
    assert f.losses() == 3;
    assert f.yield_pct() == 85;
    assert firing_line(f) == "mugs-7 (cone 6): 85% of 20";
}

test "abort once" {
    f = Firing(batch="tiles", cone=10, pieces=40, cracked=1);
    assert f.abort();
    assert not f.abort();
    assert f.yield_pct() == 0;
    assert firing_line(f) == "tiles (cone 10): aborted";
    empty = Firing(batch="none", cone=6, pieces=0);
    assert empty.yield_pct() == 0;
}

test "cone yield pools non-aborted firings" {
    a = Firing(batch="a", cone=6, pieces=10, cracked=1);
    b = Firing(batch="b", cone=6, pieces=30, glaze_faults=5);
    c = Firing(batch="c", cone=10, pieces=10, cracked=10);
    d = Firing(batch="d", cone=6, pieces=50, cracked=50);
    d.abort();
    assert cone_yield([a, b, c, d], 6) == 85;
    assert cone_yield([a, b, c, d], 10) == 0;
    assert cone_yield([a, b, c, d], 4) == 0;
    assert cone_yield([a, b], 6) == 85;
}

test "worst batch skips aborted and empty" {
    good = Firing(batch="good", cone=6, pieces=10);
    meh = Firing(batch="meh", cone=6, pieces=10, cracked=3);
    bad = Firing(batch="bad", cone=6, pieces=10, cracked=9);
    bad.abort();
    empty = Firing(batch="empty", cone=6, pieces=0);
    meh2 = Firing(batch="meh2", cone=10, pieces=10, glaze_faults=3);
    assert worst_batch([good, meh, bad, empty, meh2]) == "meh";
    assert worst_batch([good]) == "good";
    assert worst_batch([bad, empty]) == "";
}
