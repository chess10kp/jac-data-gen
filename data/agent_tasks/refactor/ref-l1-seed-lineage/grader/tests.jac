import from lineage { bank_lot, regrow, offspring, ancestry, family_size }

test "banking and regrowing" {
    assert bank_lot("K-1", "kale");
    assert not bank_lot("K-1", "kale");
    assert regrow("K-1", "K-2");
    assert not regrow("K-1", "K-2");
    assert not regrow("X-9", "X-10");
    assert not bank_lot("K-2", "kale");
    assert offspring("K-1") == ["K-2"];
    assert len(offspring("K-2")) == 0;
    assert len(offspring("missing")) == 0;
}

test "siblings are sorted" {
    bank_lot("B-1", "bean");
    regrow("B-1", "B-c");
    regrow("B-1", "B-a");
    regrow("B-1", "B-b");
    assert offspring("B-1") == ["B-a", "B-b", "B-c"];
}

test "ancestry nearest first" {
    bank_lot("W-0", "wheat");
    bank_lot("R-0", "rye");
    regrow("W-0", "W-1");
    regrow("W-1", "W-2");
    regrow("W-2", "W-3");
    regrow("R-0", "R-1");
    assert ancestry("W-3") == ["W-2", "W-1", "W-0"];
    assert ancestry("R-1") == ["R-0"];
    assert len(ancestry("W-0")) == 0;
    assert len(ancestry("nope")) == 0;
}

test "family size counts all descendants" {
    bank_lot("T", "tomato");
    bank_lot("U", "tomato");
    regrow("T", "T1");
    regrow("T", "T2");
    regrow("T1", "T1a");
    regrow("T1", "T1b");
    regrow("T1a", "T1a-x");
    regrow("U", "U1");
    assert family_size("T") == 5;
    assert family_size("T1") == 3;
    assert family_size("T2") == 0;
    assert family_size("U") == 1;
    assert family_size("ghost") == 0;
}
