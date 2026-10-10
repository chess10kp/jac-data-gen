import from apiary { add_hive, RequeenAudit }

test "strong queenright calm hive is not flagged" {
    add_hive("hill-3", 9, True, 2);
    add_hive("hill-7", 1, False, 1);
    w = root spawn RequeenAudit();
    assert w.reports[0] == ["hill-7"];
}
