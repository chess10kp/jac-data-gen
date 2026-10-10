import from apiary { Hive, add_hive, RequeenAudit }

test "no hives means an empty report and zero checked" {
    w = root spawn RequeenAudit();
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
    assert w.checked == 0;
    assert len(w.flagged) == 0;
}

test "add_hive attaches a hive to root with the given fields" {
    h = add_hive("h1", 4, False, 2);
    hives = [root -->[?:Hive]];
    assert len(hives) == 1;
    assert hives[0].tag == "h1";
    assert hives[0].brood_frames == 4;
    assert hives[0].queen_seen == False;
    assert hives[0].temper == 2;
}

test "queenless colony below three frames is flagged" {
    add_hive("two", 2, False, 1);
    add_hive("three", 3, False, 1);
    add_hive("four", 4, False, 1);
    w = root spawn RequeenAudit();
    assert w.reports[0] == ["two"];
    assert w.checked == 3;
}

test "queen seen protects a weak calm colony" {
    add_hive("weak-queened", 0, True, 3);
    w = root spawn RequeenAudit();
    assert len(w.reports[0]) == 0;
    assert w.checked == 1;
}

test "temper threshold is four inclusive" {
    add_hive("t3", 8, True, 3);
    add_hive("t4", 8, True, 4);
    add_hive("t5", 8, True, 5);
    w = root spawn RequeenAudit();
    assert w.reports[0] == ["t4", "t5"];
}

test "aggressive queenless strong colony flagged once" {
    add_hive("angry", 9, False, 4);
    w = root spawn RequeenAudit();
    assert w.reports[0] == ["angry"];
    assert w.flagged == ["angry"];
}

test "report is alphabetical and single" {
    add_hive("charlie", 1, False, 1);
    add_hive("alpha", 7, True, 5);
    add_hive("bravo", 0, False, 2);
    add_hive("delta", 7, True, 1);
    w = root spawn RequeenAudit();
    assert len(w.reports) == 1;
    assert w.reports[0] == ["alpha", "bravo", "charlie"];
    assert w.checked == 4;
}

test "only hives directly on root are audited" {
    parent = add_hive("parent", 5, True, 1);
    parent ++> Hive(tag="nuc", brood_frames=0, queen_seen=False, temper=5);
    w = root spawn RequeenAudit();
    assert w.checked == 1;
    assert len(w.reports[0]) == 0;
}

test "audit leaves hive data untouched" {
    h = add_hive("keep", 1, False, 4);
    root spawn RequeenAudit();
    root spawn RequeenAudit();
    assert h.brood_frames == 1;
    assert h.queen_seen == False;
    assert h.temper == 4;
    assert len([root -->[?:Hive]]) == 1;
}
