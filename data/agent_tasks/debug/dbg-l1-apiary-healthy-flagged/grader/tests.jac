import from apiary { Hive, add_hive, RequeenAudit }

test "empty apiary reports one empty list" {
    w = root spawn RequeenAudit();
    assert len(w.reports) == 1;
    assert len(w.reports[0]) == 0;
    assert w.checked == 0;
}

test "queenless weak colony is flagged, boundary at three frames" {
    add_hive("h-weak", 2, False, 1);
    add_hive("h-three", 3, False, 1);
    w = root spawn RequeenAudit();
    assert w.reports[0] == ["h-weak"];
    assert w.checked == 2;
}

test "queen seen keeps a weak colony off the list" {
    add_hive("h-ok", 0, True, 2);
    add_hive("h-weak", 1, False, 2);
    w = root spawn RequeenAudit();
    assert w.reports[0] == ["h-weak"];
}

test "temper four or more flags regardless of queen" {
    add_hive("t3", 9, True, 3);
    add_hive("t4", 9, True, 4);
    add_hive("t5", 9, False, 5);
    w = root spawn RequeenAudit();
    assert w.reports[0] == ["t4", "t5"];
    assert sorted(w.flagged) == ["t4", "t5"];
}

test "flagged tags reported sorted and only once" {
    add_hive("zulu", 0, False, 1);
    add_hive("alpha", 0, False, 1);
    add_hive("mike", 5, True, 4);
    w = root spawn RequeenAudit();
    assert len(w.reports) == 1;
    assert w.reports[0] == ["alpha", "mike", "zulu"];
    assert w.checked == 3;
}

test "nucleus hives off another hive are not audited" {
    main = add_hive("main", 6, True, 1);
    main ++> Hive(tag="nuc", brood_frames=0, queen_seen=False, temper=5);
    w = root spawn RequeenAudit();
    assert len(w.reports[0]) == 0;
    assert w.checked == 1;
}

test "audit does not modify hives" {
    h = add_hive("h1", 1, False, 5);
    root spawn RequeenAudit();
    assert h.brood_frames == 1;
    assert h.queen_seen == False;
    assert h.temper == 5;
    assert len([root -->[?:Hive]]) == 1;
}
