# (paste full .jac content above, then append)

test "processing order tree" {
    p = build_processor();
    p.register_row("a", "A");
    p.register_row("b", "B", parent_id="a");
    p.register_row("c", "C", parent_id="a");
    assert p.processing_order() == ["a", "b", "c"];
    assert p.unreachable() == [];
}

test "cycle leaves unreachable" {
    p = build_processor();
    p.register_row("1", "one");
    p.register_row("2", "two", parent_id="3");
    p.register_row("3", "three", parent_id="2");
    assert p.processing_order() == ["1"];
    assert p.unreachable() == ["2", "3"];
}

test "diamond parent fanout order" {
    p = build_processor();
    p.register_row("r", "R");
    p.register_row("l", "L", parent_id="r");
    p.register_row("m", "M", parent_id="r");
    p.register_row("d", "D", parent_id="l");
    p.register_row("d2", "D2", parent_id="m");
    assert p.processing_order()[0] == "r";
    assert sorted(p.processing_order()[1:]) == ["d", "d2", "l", "m"];
}
