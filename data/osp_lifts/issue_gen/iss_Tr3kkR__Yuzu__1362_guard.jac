import from iss_Tr3kkR__Yuzu__1362 { build_store }

test "reparent cycle blocked" {
    s = build_store();
    s.add_group("root");
    s.add_group("a", "root");
    s.add_group("b", "a");
    s.add_group("c", "b");
    assert s.descendants("root") == ["a", "b", "c"];
    assert s.would_cycle("c", "a") is True;
    try {
        s.reparent("a", "c");
        assert False;
    } except ValueError {
        # expected
    }
}

test "diamond descendants adversarial" {
    s = build_store();
    s.add_group("r");
    s.add_group("l", "r");
    s.add_group("m", "r");
    s.add_group("leaf", "l");
    s.add_group("leaf2", "m");
    s.add_group("deep", "leaf");
    s.add_group("deep2", "leaf2");
    assert sorted(s.descendants("r")) == ["deep", "deep2", "leaf", "leaf2", "l", "m"];
}
